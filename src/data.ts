export const KNOWLEDGE_BASE = `
TAARIFA ZILIZOIDHINISHWA (KNOWLEDGE BASE):

Topic: Kilimo cha Pasheni
- Pasheni inahitaji udongo unaopitisha maji vizuri.
- Eneo lisituamishe maji kwa sababu mizizi inaweza kuoza.
- Shamba linahitaji maandalizi mazuri kabla ya kupanda.
- Tumia nguzo na waya kusaidia mmea kupanda vizuri.
- Matunzo muhimu ni pamoja na kumwagilia kwa mpangilio, kupalilia, na kufuatilia wadudu.
- Chanzo: Video - Maandalizi ya shamba la pasheni
- Chanzo: PDF - Mwongozo mfupi wa pasheni

Topic: Ufugaji wa Kuku
- Kuku wanahitaji banda lenye hewa ya kutosha, usafi na ulinzi dhidi ya baridi na wanyama hatari.
- Chanjo ni muhimu katika kupunguza magonjwa.
- Chakula bora na maji safi vinasaidia ukuaji mzuri.
- Usafi wa banda hupunguza hatari ya magonjwa.
- Chanzo: Video - Misingi ya ufugaji wa kuku
- Chanzo: PDF - Mwongozo wa kuku kwa wanaoanza

Topic: Kilimo cha Nyanya
- Nyanya zinahitaji kitalu bora kabla ya kuhamishia miche shambani.
- Udongo uwe na rutuba na usiotuamisha maji.
- Miche ihamishwe ikiwa na afya nzuri.
- Matunzo ni pamoja na kumwagilia, kuweka mbolea, na kudhibiti wadudu.
- Chanzo: Video - Hatua za mwanzo za kilimo cha nyanya
- Chanzo: PDF - Mwongozo mfupi wa nyanya
`;

export const TOPICS = [
  {
    id: 'pasheni',
    title: 'Kilimo cha Pasheni',
    description: 'Jifunze maandalizi ya shamba, upandaji, matunzo, magonjwa na masoko.',
    badge: 'Maarufu',
    progress: 65,
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBVXFJ72a-UXHIvbtzcMLKYtC5p_JDa7xEcRu3GyljOawmvIG3KcvL8V6bxXDnSBIIuTw_bj9-4h08PdUYFydTpPbBknF9ikna4dKdtj6iZ_w2LBrfLVzrfIZNvBSYk9fX4-c84q2bFxjnqpF5LUi8IOkLfZEYodxNAgvja_JZyJiPLXNyL-vofHyrrFO7tJuYPSDSpkMPbluXRRtPn8MBzQ5uofzFr39n-1CuBrWCOGmiHDskRwDIeU_aQmgOFZUlU-4NEBLYQsJUK',
    outcomes: [
      'Kuchagua eneo sahihi',
      'Kuandaa shamba',
      'Kutambua changamoto za mwanzo',
      'Kujua hatua za matunzo'
    ]
  },
  {
    id: 'kuku',
    title: 'Ufugaji wa Kuku',
    description: 'Nyumba bora, chakula, chanjo, usafi na biashara ya kuku.',
    badge: 'Inafaa kwa wanaoanza',
    progress: 0,
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA0U85z3NmGL6m_pGx_eMPdAIg_nDloZ-wW5kCXp-iQhc4hpU__VW6Vqgz7KgfyNVnvrh4qPMT0BA8ShtI1DKALwEk9P1ElRGU9nc7FRKzd__XwKYK1HqyuaJjsYi0nrTcyy0Lxqpxm7s5E_6qnSfePk5FuPbmJkCcKpurAUzK7LTxlvZK5gUfCrUy7DNn8Zx6PFglqISS--5ng_kd50VkL0Zt6eXyrGSu41K9l8VIlGGtFN5ZHqxTugfPFNnYA3nqY7WRfN4myPgpY'
  },
  {
    id: 'nyanya',
    title: 'Kilimo cha Nyanya',
    description: 'Kitalu, upandaji, mbolea, udhibiti wa wadudu na maandalizi ya soko.',
    badge: 'Kozi mpya',
    progress: 0,
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAhVqpvWA3bAJ-59E7R6DgkWNb2FVegSXSINwCaXKS6o-vDWEkKdhHWBO7djqTD77bQ_fwgekV5Y2K9g141rxP9ROGWxthMPFf_ucopORm3YI1fqGo3cS45t6_iTvJXTjp15L8RoyHf27y1Uvoa-yIzvNxpmPYKd8oHZYbhM0gJf_kJWaIt79In6bPeW8L6LG4FgSUR3YbK6ooyT6sS1ZnuJOjv01WA6mJITlhhs_yEUkwB4bOv4JoHNXI9pIVKJ_gntRIXFtGckQUY'
  }
];

export const COMMUNITY_POSTS = [
  {
    id: 1,
    author: 'Joseph M.',
    authorImage: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCSDFzW4SioCgf6bXdRkjhWsGVc33VQ7tB932XcWkk0F95fe9UXlcDaH5wh8eOBV_i4Mrzsoc5LuXhmcQRjeL83J_emAa-uxxSBQN6louhV2kSDqiVDgMdyhVyuDMyOZ2vF7fN_KEnvzYGP_M-s7cTC5bvDOdvRiT01q8rvxFCAJCOOo-TAGGJtVYR2BKq-VZ--68g2Ayh3mBAGkHZHvtMeIOX7wY3WzdWkOOPRqJRX-6v6ukHZcmdvwJiUhELG_ndHFZEGh4VTKPPx',
    location: 'Morogoro',
    time: 'Saa 2 zilizopita',
    content: 'Naomba ushauri, majani ya pasheni yangu yanabadilika rangi.',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDJnKqtYFYfIVfjEsTv51XEt2jAGgCPFlgMJaOhfy8-BD4XeRlrI53KSNSW3m3Htk9hnjh8gT4dSfq2KIfpSwf51JF8D_zo_4MLuq8R2nCwk_iTvJWIo9tSRpcqJ4p62iT2opEcsntb5Qex8sOtxi5BVYGjV5b3AmfwLuny-yyIu8c_KicfMHK3PUTB-_FOU7k7HE7DP7OBI62d1t09rdf0pAhgkLwM0ptEC4vYNrErmyBEC2Vh3GsSH3ncCgLAqvBpGK6Ueu38_SND',
    likes: 12,
    comments: 4
  },
  {
    id: 2,
    author: 'Mama Asha',
    authorImage: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAnoBR3Eqzw5_au8y8Q7PIrCwsngwpzA3ML_082kzxzKjSnTs-CumVVIf9w1nxyxDKwf2KjB_pjsgrJcsOkUCNK4Qm5xYLxs2do_UXa9bwM5vdW6bWE8h3inUq4sCdTIy8wqVpquL518iZASvkhEwEWiGjNO97Z9IQRNcsvBYbkGl2tGu9QRHqaM2ovL8JCk_iiugEQrj_NlqzIGUBImFJVJPmFie112lXgZJWzUR5ljnSjCyCzXHTMyxm6yy_m3WlII9z85RKuNekb',
    location: 'Mbeya',
    time: 'Saa 5 zilizopita',
    content: 'Natafuta mwongozo wa kuanza ufugaji wa kuku wa nyama.',
    relatedTopic: 'Ufugaji wa Kuku',
    likes: 34,
    comments: 8
  }
];
