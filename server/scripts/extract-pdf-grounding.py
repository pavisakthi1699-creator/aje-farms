#!/usr/bin/env python3
"""Generate idempotent SQL for PDF source segments and grounding-fact drafts."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import unicodedata
from pathlib import Path

import pdfplumber


PAGE_PATTERN = re.compile(r"Uk\.\s*(\d+)(?:\s*-\s*(\d+))?", re.IGNORECASE)
LINKABLE_TYPES = {"course", "module", "lesson"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", required=True)
    parser.add_argument("--curriculum", required=True)
    parser.add_argument("--source-document-id", required=True)
    parser.add_argument("--course-code", required=True)
    parser.add_argument(
        "--printed-page-offset",
        type=int,
        default=1,
        help="PDF page number minus printed page number.",
    )
    return parser.parse_args()


def sql_text(value: str | None) -> str:
    if value is None:
        return "null"
    return "'" + value.replace("'", "''") + "'"


def page_range(row: dict) -> tuple[int, int] | None:
    match = PAGE_PATTERN.search(str(row.get("source_reference", "")))
    if not match:
        return None
    start = int(match.group(1))
    end = int(match.group(2) or start)
    return (start, end)


def normalized_tokens(value: str) -> set[str]:
    normalized = unicodedata.normalize("NFKD", value.lower())
    return {
        token
        for token in re.findall(r"[a-z0-9]+", normalized)
        if len(token) >= 4
    }


def overlap_score(fact: str, evidence: str) -> float:
    fact_tokens = normalized_tokens(fact)
    if not fact_tokens:
        return 0.0
    return len(fact_tokens & normalized_tokens(evidence)) / len(fact_tokens)


def target_select(row: dict, source_segment_hash: str) -> str:
    item_type = row["item_type"]
    source_id = sql_text(source_segment_hash)
    if item_type == "course":
        return f"""
select
  'course',
  c.id,
  ss.id,
  ss.source_document_id,
  'pending_review'::public.source_link_status,
  {sql_text(row.get("source_reference"))}
from public.courses c
join public.source_segments ss
  on ss.source_document_id = {sql_text(ARGS.source_document_id)}::uuid
 and ss.content_hash = {source_id}
where c.code = {sql_text(ARGS.course_code)}
"""
    if item_type == "module":
        return f"""
select
  'module',
  m.id,
  ss.id,
  ss.source_document_id,
  'pending_review'::public.source_link_status,
  {sql_text(row.get("source_reference"))}
from public.course_modules m
join public.courses c on c.id = m.course_id
join public.source_segments ss
  on ss.source_document_id = {sql_text(ARGS.source_document_id)}::uuid
 and ss.content_hash = {source_id}
where c.code = {sql_text(ARGS.course_code)}
  and m.code = {sql_text(row.get("module_code") or row.get("code"))}
"""
    return f"""
select
  'lesson',
  l.id,
  ss.id,
  ss.source_document_id,
  'pending_review'::public.source_link_status,
  {sql_text(row.get("source_reference"))}
from public.lessons l
join public.course_modules m on m.id = l.module_id
join public.courses c on c.id = m.course_id
join public.source_segments ss
  on ss.source_document_id = {sql_text(ARGS.source_document_id)}::uuid
 and ss.content_hash = {source_id}
where c.code = {sql_text(ARGS.course_code)}
  and m.code = {sql_text(row.get("module_code"))}
  and l.code = {sql_text(row.get("lesson_code") or row.get("code"))}
"""


def main() -> None:
    curriculum = json.loads(Path(ARGS.curriculum).read_text(encoding="utf-8"))
    rows = curriculum["rows"] if isinstance(curriculum, dict) else curriculum
    candidates = [
        row
        for row in rows
        if row.get("item_type") in LINKABLE_TYPES | {"faq"}
        and page_range(row) is not None
    ]

    segments: dict[tuple[int, int], dict] = {}
    with pdfplumber.open(ARGS.pdf) as pdf:
        for row in candidates:
            printed_start, printed_end = page_range(row)  # type: ignore[misc]
            pdf_start = printed_start + ARGS.printed_page_offset
            pdf_end = printed_end + ARGS.printed_page_offset
            if pdf_start < 1 or pdf_end > len(pdf.pages):
                raise ValueError(
                    f"{row.get('external_id')} cites pages outside the PDF: "
                    f"{printed_start}-{printed_end}"
                )
            key = (printed_start, printed_end)
            if key not in segments:
                content = "\n\n".join(
                    (pdf.pages[index - 1].extract_text() or "").strip()
                    for index in range(pdf_start, pdf_end + 1)
                ).strip()
                if not content:
                    raise ValueError(
                        f"No extractable text for printed pages "
                        f"{printed_start}-{printed_end}"
                    )
                segments[key] = {
                    "content": content,
                    "hash": hashlib.sha256(content.encode("utf-8")).hexdigest(),
                    "title": row.get("title_sw")
                    or row.get("question_sw")
                    or f"Kurasa {printed_start}-{printed_end}",
                }

    print("begin;")
    for order, ((start, end), segment) in enumerate(
        sorted(segments.items()), start=1
    ):
        print(
            f"""
insert into public.source_segments (
  source_document_id,
  page_start,
  page_end,
  section_title,
  segment_order,
  content_sw,
  content_hash,
  extraction_method,
  review_status,
  risk_level
)
values (
  {sql_text(ARGS.source_document_id)}::uuid,
  {start},
  {end},
  {sql_text(segment["title"])},
  {order},
  {sql_text(segment["content"])},
  {sql_text(segment["hash"])},
  'pdfplumber',
  'needs_review',
  'medium'
)
on conflict (source_document_id, content_hash) do update
set page_start = excluded.page_start,
    page_end = excluded.page_end,
    section_title = excluded.section_title,
    segment_order = excluded.segment_order,
    content_sw = excluded.content_sw,
    extraction_method = excluded.extraction_method,
    updated_at = now();
"""
        )

    for row in candidates:
        start, end = page_range(row)  # type: ignore[misc]
        segment = segments[(start, end)]
        if row["item_type"] in LINKABLE_TYPES:
            print(
                """
insert into public.content_source_links (
  content_type,
  content_id,
  source_segment_id,
  source_document_id,
  link_status,
  evidence_note
)
"""
                + target_select(row, segment["hash"])
                + """
on conflict (content_type, content_id, source_segment_id) do update
set link_status = excluded.link_status,
    evidence_note = excluded.evidence_note,
    updated_at = now();
"""
            )
            continue

        answer = str(row.get("answer_sw", "")).strip()
        if not answer or "whatsapp" in answer.lower():
            continue
        score = overlap_score(answer, segment["content"])
        print(
            f"""
insert into public.grounding_facts (
  course_id,
  source_segment_id,
  code,
  fact_sw,
  question_sw,
  status,
  risk_level,
  import_source,
  external_id
)
select
  c.id,
  ss.id,
  {sql_text(row.get("code") or row.get("external_id"))},
  {sql_text(answer)},
  {sql_text(row.get("question_sw"))},
  'needs_review',
  'medium',
  'notebooklm',
  {sql_text(row.get("external_id"))}
from public.courses c
join public.source_segments ss
  on ss.source_document_id = {sql_text(ARGS.source_document_id)}::uuid
 and ss.content_hash = {sql_text(segment["hash"])}
where c.code = {sql_text(ARGS.course_code)}
on conflict (import_source, external_id)
where external_id is not null
do update
set source_segment_id = excluded.source_segment_id,
    fact_sw = excluded.fact_sw,
    question_sw = excluded.question_sw,
    status = 'needs_review',
    risk_level = excluded.risk_level,
    updated_at = now();
"""
        )
        print(
            json.dumps(
                {
                    "external_id": row.get("external_id"),
                    "pages": f"{start}-{end}",
                    "overlap": round(score, 2),
                    "review": "manual_required",
                },
                ensure_ascii=False,
            ),
            file=sys.stderr,
        )

    print(
        f"""
update public.source_documents
set processing_status = 'needs_review',
    updated_at = now()
where id = {sql_text(ARGS.source_document_id)}::uuid;

update public.courses
set delivery_type = 'text',
    status = 'draft',
    source_link_status = 'pending_review',
    published_at = null,
    updated_at = now()
where code = {sql_text(ARGS.course_code)};

commit;
"""
    )


if __name__ == "__main__":
    ARGS = parse_args()
    main()
