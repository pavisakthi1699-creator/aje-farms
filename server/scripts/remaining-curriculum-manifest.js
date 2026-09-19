export const REMAINING_CURRICULUM = [
  { code: "CRS-ALZ-01", markdownFile: "KILIMO CHA ALIZETI TANZANIA.md", sourceFile: "KILIMO CHA ALIZETI TANZANIA (1).pdf", contentCourseId: "kilimo-cha-alizeti" },
  { code: "CRS-CHK-01", markdownFile: "KILIMO CHA CHIKICHI .md", sourceFile: "KILIMO CHA CHIKICHI TOLEO LA KWANZA.pdf", contentCourseId: "kilimo-cha-chikichi" },
  { code: "CRS-NAN-01", markdownFile: "KILIMO CHA NANASI.md", sourceFile: "KILIMO CHA NANASI Toleo La Kwanza.pdf", contentCourseId: "kilimo-cha-nanasi" },
  { code: "CRS-001", markdownFile: "Bustani ya Eden.md", sourceFile: "BUSTANI YA EDEN MWOKOZI WA FAMILIA KITABU.pdf", contentCourseId: "bustani-ya-eden" },
  { code: "CRS-PSH-01", markdownFile: "KILIMO CHA PASHENI .md", sourceFile: "KILIMO CHA PASHENI TOLEO LA KWANZA.PDF", contentCourseId: "kilimo-cha-pasheni" },
  { code: "CRS-MPU-01", markdownFile: "KILIMO CHA MPUNGA.md", sourceFile: "KITABU CHA KILIMO CHA MPUNGA.pdf", contentCourseId: "kilimo-cha-mpunga" },
  { code: "CRS-MHG-01", markdownFile: "KILIMO CHA MUHOGO.md", sourceFile: "KITABU CHA KILIMO CHA MUHOGO.pdf", contentCourseId: "kilimo-cha-muhogo" },
  { code: "CRS-MGB-01", markdownFile: "KILIMO CHA Migomba.md", sourceFile: "Kitabu cha KILIMO CHA  Migomba.pdf", contentCourseId: "kilimo-cha-migomba" },
  { code: "CRS-KUK-01", markdownFile: "LISHE BORA YA KUKU.md", sourceFile: "LISHE BORA YA KUKU.pdf", contentCourseId: "lishe-bora-ya-kuku" },
  { code: "CRS-NYN-01", markdownFile: "KILIMO CHA NYANYA KWA MTAJI KIDOGO.md", sourceFile: "KILIMO CHA NYANYA KWA MTAJI KIDOGO.pdf", contentCourseId: "kilimo-cha-nyanya" },
];

export function curriculumSourceDirectory(args = process.argv.slice(2)) {
  const value = args.find((arg) => arg.startsWith("--source-dir="));
  return value ? value.slice("--source-dir=".length) : process.env.CURRICULUM_SOURCE_DIR ?? "..";
}

export function selectedCurricula(args = process.argv.slice(2)) {
  const selected = args.find((arg) => arg.startsWith("--course="))?.slice("--course=".length);
  if (!selected) return REMAINING_CURRICULUM;
  const curriculum = REMAINING_CURRICULUM.filter((item) => item.code === selected);
  if (curriculum.length === 0) throw new Error(`Unknown course ${selected}`);
  return curriculum;
}
