export const catalog = {
  courses: [
    {
      id: 'pasheni',
      title: 'Kilimo cha Pasheni',
      description:
        'Jifunze maandalizi ya shamba, upandaji, matunzo, magonjwa na masoko.',
      badge: 'Maarufu',
      icon: 'local_florist',
      progress: 0.65,
      imageUrl:
        'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?auto=format&fit=crop&w=900&q=80',
      outcomes: [
        'Kuchagua eneo sahihi',
        'Kuandaa shamba kabla ya kupanda',
        'Kutambua changamoto za mwanzo',
        'Kujua hatua za matunzo',
      ],
      lessons: [
        {
          title: 'Maandalizi ya shamba',
          type: 'video',
          meta: 'DKK 5',
          description:
            'Tambua eneo lenye mwanga, maji yanayopita vizuri na nafasi ya mistari kabla ya kupanda pasheni.',
          isCompleted: true,
        },
        {
          title: 'Mwongozo mfupi wa pasheni',
          type: 'pdf',
          meta: '2 MB',
          description:
            'Pakua muhtasari wa hatua za kupanda, kuweka nguzo, kumwagilia na kutambua dalili za mwanzo.',
          isCompleted: true,
        },
        {
          title: 'Jaribio la maarifa',
          type: 'quiz',
          meta: 'Maswali 10',
          description:
            'Pima kama uko tayari kuendelea kwenye hatua za magonjwa, mavuno na masoko.',
          isPremium: true,
        },
      ],
    },
    {
      id: 'kuku',
      title: 'Ufugaji wa Kuku',
      description: 'Nyumba bora, chakula, chanjo, usafi na biashara ya kuku.',
      badge: 'Inafaa kwa wanaoanza',
      icon: 'egg_alt',
      progress: 0,
      imageUrl:
        'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?auto=format&fit=crop&w=900&q=80',
      outcomes: [
        'Kujenga banda lenye hewa na usalama',
        'Kupanga ratiba ya chanjo',
        'Kuchagua chakula bora',
        'Kupunguza hatari ya magonjwa',
      ],
      lessons: [
        {
          title: 'Misingi ya ufugaji wa kuku',
          type: 'video',
          meta: 'DKK 6',
          description:
            'Jifunze mahitaji ya banda, maji, chakula na usafi kabla ya kuleta vifaranga.',
        },
        {
          title: 'Ratiba ya chanjo',
          type: 'pdf',
          meta: '1 MB',
          description:
            'Orodha ya chanjo muhimu na muda wa kuzitoa kwa kuku wa nyama au mayai.',
        },
        {
          title: 'Biashara ya kuku',
          type: 'quiz',
          meta: 'Premium',
          description:
            'Kadiria gharama, mapato na masoko kabla ya kuongeza idadi ya kuku.',
          isPremium: true,
        },
      ],
    },
    {
      id: 'nyanya',
      title: 'Kilimo cha Nyanya',
      description:
        'Kitalu, upandaji, mbolea, udhibiti wa wadudu na maandalizi ya soko.',
      badge: 'Kozi mpya',
      icon: 'grass',
      progress: 0,
      imageUrl:
        'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=900&q=80',
      outcomes: [
        'Kuandaa kitalu bora',
        'Kuhamisha miche yenye afya',
        'Kutumia mbolea kwa wakati',
        'Kudhibiti wadudu na magonjwa',
      ],
      lessons: [
        {
          title: 'Kuandaa kitalu',
          type: 'video',
          meta: 'DKK 4',
          description:
            'Chagua mbegu, andaa kivuli na linda miche dhidi ya maji mengi na wadudu.',
        },
        {
          title: 'Udhibiti wa wadudu',
          type: 'pdf',
          meta: '2 MB',
          description:
            'Tambua viwavi, vidukari na ukungu mapema kabla ya kuchagua dawa au hatua ya shamba.',
        },
        {
          title: 'Maandalizi ya soko',
          type: 'quiz',
          meta: 'Premium',
          description:
            'Panga kuvuna, kupanga madaraja na kuzungumza na wanunuzi kabla ya msimu.',
          isPremium: true,
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
      examples: ['Bei ya leo', 'Wanunuzi'],
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
      id: 'seed-pasheni-disease',
      author: 'Joseph M.',
      location: 'Morogoro',
      time: 'Saa 2 zilizopita',
      content: 'Naomba ushauri, majani ya pasheni yangu yanabadilika rangi.',
      likes: 12,
      comments: 4,
      tags: ['Pasheni', 'Magonjwa'],
      replies: [
        {
          author: 'Mtaalamu AJE',
          body:
            'Angalia kama kuna madoa chini ya jani na kama maji yanasimama karibu na shina. Ukiona ukungu, tenga sehemu iliyoathirika kwanza.',
          time: 'Dakika 45 zilizopita',
          isExpert: true,
        },
        {
          author: 'Mama Asha',
          body:
            'Nilipunguza kumwagilia na kuondoa majani yaliyoathirika, hali ikaanza kuwa nzuri.',
          time: 'Dakika 20 zilizopita',
        },
      ],
      hasImage: true,
      isUrgent: true,
    },
    {
      id: 'seed-kuku-start',
      author: 'Mama Asha',
      location: 'Mbeya',
      time: 'Saa 5 zilizopita',
      content: 'Natafuta mwongozo wa kuanza ufugaji wa kuku wa nyama.',
      relatedTopic: 'Ufugaji wa Kuku',
      likes: 34,
      comments: 8,
      tags: ['Mifugo', 'Kuku'],
      replies: [
        {
          author: 'Daudi K.',
          body:
            'Anza na idadi ndogo, andaa banda lenye hewa na hakikisha ratiba ya chanjo iko tayari kabla ya vifaranga.',
          time: 'Saa 3 zilizopita',
        },
        {
          author: 'Mtaalamu AJE',
          body:
            'Kozi ya ufugaji wa kuku ina checklist ya banda na ratiba ya chanjo. Itakusaidia kupanga gharama za mwanzo.',
          time: 'Saa 1 iliyopita',
          isExpert: true,
        },
      ],
    },
    {
      id: 'seed-nyanya-market',
      author: 'Mtaalamu AJE',
      location: 'Arusha',
      time: 'Leo',
      content:
        'Bei ya nyanya imepanda kwenye baadhi ya masoko. Wakulima waangalie ubora na kupanga kuvuna asubuhi ili kupunguza kuharibika.',
      relatedTopic: 'Kilimo cha Nyanya',
      likes: 57,
      comments: 11,
      tags: ['Masoko', 'Nyanya'],
      replies: [
        {
          author: 'Joseph M.',
          body: 'Je, kuna bei elekezi kwa Morogoro wiki hii?',
          time: 'Saa 1 iliyopita',
        },
      ],
      isExpert: true,
    },
  ],
};
