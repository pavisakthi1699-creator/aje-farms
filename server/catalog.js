export const catalog = {
  courses: [
    {
      id: 'pasheni',
      contentVersion: 2,
      title: 'Kilimo cha Pasheni',
      description:
        'Jifunze maandalizi ya shamba, upandaji, matunzo, magonjwa na masoko.',
      badge: 'Maarufu',
      icon: 'local_florist',
      progress: 0,
      imageUrl: 'assets/images/courses/pasheni.jpg',
      outcomes: [
        'Kuchagua eneo sahihi',
        'Kuandaa shamba kabla ya kupanda',
        'Kutambua changamoto za mwanzo',
        'Kujua hatua za matunzo',
      ],
      lessons: [
        {
          title: 'Kuchagua eneo la shamba',
          type: 'reading',
          meta: 'Dakika 5',
          description:
            'Chunguza mwanga, njia ya maji na nafasi ya kupanga mistari. Rekodi hali ya eneo kabla ya kuandaa shamba.',
        },
        {
          title: 'Kuandaa shamba na nguzo',
          type: 'reading',
          meta: 'Dakika 6',
          description:
            'Panga eneo la kupanda na mfumo wa kuusaidia mmea kukua. Rekebisha mpango kulingana na hali ya shamba lako.',
        },
        {
          title: 'Kufuatilia afya ya mmea',
          type: 'reading',
          meta: 'Dakika 5',
          description:
            'Kagua majani, shina na unyevu mara kwa mara. Piga picha na wasiliana na mtaalamu kabla ya kutumia tiba usiyoifahamu.',
        },
      ],
    },
    {
      id: 'kuku',
      contentVersion: 2,
      title: 'Ufugaji wa Kuku',
      description: 'Nyumba bora, chakula, chanjo, usafi na biashara ya kuku.',
      badge: 'Inafaa kwa wanaoanza',
      icon: 'egg_alt',
      progress: 0,
      imageUrl: 'assets/images/courses/kuku.jpg',
      outcomes: [
        'Kujenga banda lenye hewa na usalama',
        'Kupanga ratiba ya chanjo',
        'Kuchagua chakula bora',
        'Kupunguza hatari ya magonjwa',
      ],
      lessons: [
        {
          title: 'Kuandaa banda',
          type: 'reading',
          meta: 'Dakika 6',
          description:
            'Kagua nafasi, hewa, usalama na urahisi wa kusafisha banda kabla ya kuleta kuku.',
        },
        {
          title: 'Maji, chakula na usafi',
          type: 'reading',
          meta: 'Dakika 5',
          description:
            'Weka utaratibu wa maji safi, chakula na usafi, kisha andika mabadiliko unayoona kila siku.',
        },
        {
          title: 'Kuweka kumbukumbu za afya',
          type: 'reading',
          meta: 'Dakika 5',
          description:
            'Rekodi dalili, umri na historia ya kundi. Kwa chanjo, dawa au dalili kali, tumia ratiba iliyoidhinishwa na daktari wa mifugo wa eneo lako.',
        },
      ],
    },
    {
      id: 'nyanya',
      contentVersion: 2,
      title: 'Kilimo cha Nyanya',
      description:
        'Kitalu, upandaji, mbolea, udhibiti wa wadudu na maandalizi ya soko.',
      badge: 'Kozi mpya',
      icon: 'grass',
      progress: 0,
      imageUrl: 'assets/images/courses/nyanya.jpg',
      outcomes: [
        'Kuandaa kitalu bora',
        'Kuhamisha miche yenye afya',
        'Kutumia mbolea kwa wakati',
        'Kudhibiti wadudu na magonjwa',
      ],
      lessons: [
        {
          title: 'Kuandaa kitalu',
          type: 'reading',
          meta: 'Dakika 5',
          description:
            'Panga sehemu ya kitalu, ulinzi wa miche na utaratibu wa kukagua unyevu bila kuzidisha maji.',
        },
        {
          title: 'Kufuatilia miche na mimea',
          type: 'reading',
          meta: 'Dakika 5',
          description:
            'Kagua majani na ukuaji, rekodi dalili na piga picha. Tambua tatizo kwa msaada wa mtaalamu kabla ya kutumia dawa.',
        },
        {
          title: 'Kujiandaa kwa mavuno',
          type: 'reading',
          meta: 'Dakika 5',
          description:
            'Panga uvunaji, upangaji wa ubora, hifadhi ya muda mfupi na mawasiliano na wanunuzi bila kutegemea bei isiyothibitishwa.',
        },
      ],
    },
  ],
  problemCategories: [
    {
      title: 'Magonjwa ya mimea',
      topic: 'Magonjwa ya mimea',
      icon: 'spa',
      color: '#E15241',
      summary: 'Majani kubadilika rangi, kuoza, kunyauka au ukungu.',
      examples: ['Ukungu', 'Majani njano'],
    },
    {
      title: 'Wadudu na Visumbufu',
      topic: 'Wadudu',
      icon: 'bug_report',
      color: '#E07A2F',
      summary: 'Vidukari, viwavi, funza au mashambulizi yasiyoeleweka.',
      examples: ['Viwavi', 'Vidukari'],
    },
    {
      title: 'Mbolea na Udongo',
      topic: 'Mbolea',
      icon: 'eco',
      color: '#188C5B',
      summary: 'Rutuba, aina ya mbolea, muda wa kuweka na kipimo.',
      examples: ['DAP', 'Udongo mchovu'],
    },
    {
      title: 'Maji / Umwagiliaji',
      topic: 'Maji na Umwagiliaji',
      icon: 'water_drop',
      color: '#2F7DE1',
      summary: 'Ratiba ya maji, mifereji, ukame au maji kusimama.',
      examples: ['Kukauka', 'Maji mengi'],
    },
    {
      title: 'Soko na Bei',
      topic: 'Soko',
      icon: 'trending_up',
      color: '#D5961B',
      summary: 'Bei, wanunuzi, muda wa kuuza na maandalizi ya mavuno.',
      examples: ['Kulinganisha bei', 'Wanunuzi'],
    },
    {
      title: 'Ufugaji',
      topic: 'Ufugaji',
      icon: 'handshake',
      color: '#C85A3C',
      summary: 'Kuku, mbuzi au ngombe: afya, chakula, banda na chanjo.',
      examples: ['Chanjo', 'Chakula'],
    },
  ],
  plans: [
    {
      title: 'Wiki 1',
      subtitle: 'Ufikiaji wa haraka',
      price: 'TZS 3,000',
      icon: 'calendar_month',
    },
    {
      title: 'Mwezi 1',
      subtitle: 'Thamani bora zaidi',
      price: 'TZS 10,000',
      icon: 'star',
      recommended: true,
    },
    {
      title: 'Kozi Maalum',
      subtitle: 'Utaalamu wa kina',
      price: 'TZS 50,000',
      icon: 'menu_book',
    },
  ],
  communityPosts: [
    {
      id: 'seed-community-guidelines',
      author: 'Timu ya AJE Farms',
      location: 'Tanzania',
      time: 'Mwongozo wa jamii',
      content:
        'Karibu kwenye jamii ya AJE Farms. Eleza hali uliyoiona, eneo na zao au mnyama. Usishiriki taarifa binafsi, na thibitisha ushauri wa dawa au chanjo na mtaalamu wa eneo lako.',
      likes: 0,
      comments: 0,
      tags: ['Jamii', 'Mwongozo'],
      replies: [],
      isExpert: true,
    },
  ],
};
