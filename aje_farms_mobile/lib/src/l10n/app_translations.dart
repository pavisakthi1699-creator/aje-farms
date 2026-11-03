import 'package:flutter/material.dart';
import '../state/app_session.dart';

/// Comprehensive local translation engine for Chuo Kikuu Cha Mtaani.
/// Works 100% offline without external network or API dependencies.
class AppTranslations {
  AppTranslations._();

  /// Swahili to English dictionary mapping exact UI strings and content labels.
  static const Map<String, String> _swToEn = {
    // App Branding & Navigation
    'Chuo Kikuu Cha Mtaani': 'Mtaani Open University',
    'Nyumbani': 'Home',
    'Kozi': 'Courses',
    'Mafunzo': 'Courses',
    'Jamii': 'Community',
    'Msaidizi': 'Assistant',
    'Msaidizi AI': 'AI Assistant',
    'Profaili': 'Profile',
    'Akaunti': 'Account',
    'Akaunti Yangu': 'My Account',
    'Mipangilio': 'Settings',
    'Taarifa': 'Notifications',
    'Arifa': 'Notifications',
    'Tafuta': 'Search',
    'Utafutaji': 'Search',
    'Dashibodi': 'Dashboard',
    'Dashibodi ya Admin': 'Admin Dashboard',
    'Dashibodi ya Utawala': 'Admin Dashboard',

    // Dashboard & Greetings
    'Jambo': 'Hello',
    'Karibu tena': 'Welcome back',
    'Habari za leo': 'Good day',
    'Mada za Leo': "Today's Topics",
    'Mada za Kujifunza': 'Learning Topics',
    'Mada Maarufu': 'Popular Topics',
    'Kozi Zilizohifadhiwa': 'Saved Courses',
    'Hivi karibuni': 'Recently Viewed',
    'Maendeleo Yako': 'Your Progress',
    'Endeleza shamba lako leo': 'Develop your farm today',
    'Uliza chochote kuhusu kilimo au ufugaji...':
        'Ask anything about farming or livestock...',
    'Tafuta kozi, makala au mada...': 'Search courses, articles, or topics...',
    'Hali ya Hewa & Msimu': 'Weather & Season',
    'Wataalamu Wapo Tayari': 'Experts Ready to Help',
    'Uliza Mtaalamu': 'Ask an Expert',
    'Elimu ya Kilimo Kiganjani': 'Farming Education in Your Hands',
    'Endelea Kujifunza': 'Continue Learning',
    'Mafunzo yanaandaliwa': 'Courses are being prepared',
    'Hakuna kozi iliyokamilisha ukaguzi wa vyanzo kwa sasa.':
        'No verified courses available at the moment.',

    // Courses & Curriculum
    'Kozi Zote': 'All Courses',
    'Mtaala': 'Curriculum',
    'Masomo': 'Lessons',
    'Sura': 'Modules',
    'Sura ya': 'Module',
    'Soma Sasa': 'Read Now',
    'Anza Jifunze': 'Start Learning',
    'Imekamilika': 'Completed',
    'Maelezo ya Kozi': 'Course Description',
    'Vitabu na Nyaraka': 'Books & Documents',
    'Video za Mafunzo': 'Training Videos',
    'Tathmini ya Ujuzi': 'Skill Assessment',
    'Hati ya Bitana': 'Certificate',
    'Mada': 'Topics',
    'Sura Zote': 'All Modules',
    'Maendeleo': 'Progress',
    'Fungua Masomo': 'Unlock Lessons',
    'Hakuna kozi bado': 'No courses yet',
    'Hakuna maudhui ya mafunzo yaliyopatikana kwa sasa. Vuta chini kusasisha.':
        'No learning content available right now. Pull down to refresh.',
    'Sasisha': 'Refresh',
    'Maudhui yamesasishwa.': 'Content updated.',
    'Tafuta kozi au somo': 'Search course or lesson',
    'Chagua Mada.\nJifunze Kilimo.': 'Choose Topic.\nLearn Farming.',
    'Chagua kozi hapa chini ili kuongeza tija kwenye shamba lako leo.':
        'Select a course below to boost your farm productivity today.',
    'Maktaba yako': 'Your library',
    'Mwendelezo wa kozi': 'Course progress',
    'Malengo ya Somo:': 'Lesson Objectives:',

    // Common Course & Category Titles
    'Ufugaji wa Kuku wa Kienyeji': 'Indigenous Poultry Farming',
    'Kilimo cha Mahindi': 'Maize Farming',
    'Magonjwa ya Kuku na Tiba': 'Poultry Diseases and Treatment',
    'Kilimo cha Mboga na Matunda': 'Vegetable and Fruit Farming',
    'Ufugaji wa Ng\'ombe wa Maziwa': 'Dairy Cattle Farming',
    'Afya na Uhifadhi wa Udongo': 'Soil Health and Conservation',
    'Ufugaji wa Mbuzi na Kondoo': 'Goat and Sheep Farming',
    'Usimamizi wa Shamba na Biashara': 'Farm Management and Business',
    'Kilimo cha Mpunga': 'Rice Farming',
    'Afya ya Wanyama': 'Animal Health',
    'Mboga na Matunda': 'Vegetables and Fruits',
    'Ufugaji Samaki': 'Fish Farming',
    'Ufugaji Nyuki': 'Bee Keeping',
    'Kilimo Hifadhi': 'Conservation Agriculture',
    'Ushuhuda wa Wakulima': 'Farmer Testimonials',

    // Community
    'Jamii ya Wakulima': 'Farmers Community',
    'Mawazo na Maswali': 'Discussions & Questions',
    'Uliza swali...': 'Ask a question...',
    'Swali': 'Ask',
    'Tuma': 'Post',
    'Jibu': 'Reply',
    'Majibu': 'Replies',
    'Wataalamu': 'Experts',
    'Hifadhi': 'Save',
    'Shiriki': 'Share',
    'Ripoti': 'Report',
    'Zuia Mtumiaji': 'Block User',
    'Machapisho Yangu': 'My Posts',
    'Chapisho Jipya': 'New Post',
    'Andika hapa...': 'Write here...',
    'Leta Picha': 'Add Photo',
    'Mtumiaji Alieidhinishwa': 'Verified Farmer',
    'Mtaalamu wa Kilimo': 'Agricultural Expert',

    // AI Chat
    'Msaidizi wa Mwalimu AI': 'Mwalimu AI Assistant',
    'Mwalimu AI': 'Mwalimu AI',
    'Mtandaoni': 'Online',
    'Hali: Mtandaoni': 'Status: Online',
    'Mifano ya maswali': 'Example questions',
    'Kilimo cha Kisasa': 'Modern Farming',
    'Ushauri wa Kilimo': 'Agricultural Advice',
    'Uliza AI': 'Ask AI',
    'Uliza AI Sasa': 'Ask AI Now',
    'Una swali gani?': 'What is your question?',

    // Notifications
    'Weka zote zimesomwa': 'Mark all as read',
    'Zote Zimesomwa': 'All Read',
    'Hakuna arifa mpya': 'No new notifications',
    'Zilizopita': 'Earlier',
    'Soma': 'Read',
    'Arifa hazijapatikana': 'Notifications unavailable',
    'Tumia mtandao kisha jaribu tena.': 'Connect to network and try again.',
    'Arifa zimewashwa': 'Notifications enabled',
    'Arifa zimezimwa': 'Notifications disabled',
    'Tutakutumia majibu mapya na taarifa muhimu.':
        'We will send you new replies and important updates.',
    'Washa arifa kwenye mipangilio ili kupata vikumbusho.':
        'Turn on notifications in settings to receive reminders.',
    'Tutakuonyesha majibu ya jamii, taarifa za usimamizi, na vikumbusho hapa.':
        'We will show community replies, management updates, and reminders here.',
    'Jibu jipya': 'New reply',
    'Jibu jipya kwenye jamii': 'New community reply',
    'Mkulima amejibu post yako.': 'A farmer replied to your post.',
    'Mkulima amejibu post yako': 'A farmer replied to your post',
    'Post imefichwa': 'Post hidden',
    'Post imerejeshwa': 'Post restored',
    'Ripoti imepitiwa': 'Report reviewed',
    'Post yako imefichwa baada ya ukaguzi wa timu ya Chuo Kikuu Cha Mtaani.':
        'Your post was hidden after review by the Mtaani Open University team.',
    'Post yako imerejeshwa baada ya ukaguzi wa timu ya Chuo Kikuu Cha Mtaani.':
        'Your post was restored after review by the Mtaani Open University team.',
    'Ripoti kuhusu post yako imepitiwa na timu ya Chuo Kikuu Cha Mtaani.':
        'A report regarding your post was reviewed by the Mtaani Open University team.',
    'Arifa za mafunzo na jamii': 'Learning and community notifications',
    'Washa au zima vikumbusho kwenye app.':
        'Turn reminders on or off in the app.',
    'Somo jipya limeongezwa': 'New lesson added',
    'Angalia mwongozo mpya wa nyanya na udhibiti wa wadudu.':
        'Check out the new tomato guide and pest management.',
    'Msimamizi akiwasha akaunti yako, mafunzo na Mwalimu AI vitafunguka.':
        'When staff activates your account, courses and Mwalimu AI will unlock.',
    'Machapisho': 'Posts',

    // Search
    'Matokeo ya Utafutaji': 'Search Results',
    'Matokeo bora': 'Top Results',
    'Hakuna matokeo yaliyopatikana': 'No results found',
    'Tafuta kwa mada au neno kuu': 'Search by topic or keyword',
    'Makala': 'Articles',

    // Profile & Settings
    'Profaili ya Mkulima': 'Farmer Profile',
    'Hariri Profaili': 'Edit Profile',
    'Jina Kamili': 'Full Name',
    'Namba ya Simu': 'Phone Number',
    'Eneo / Mkoa': 'Region / Location',
    'Aina ya Kilimo': 'Farming Type',
    'Lugha': 'Language',
    'Lugha / Language': 'Language / Lugha',
    'Badili lugha ya programu': 'Change app language',
    'Kiswahili': 'Swahili',
    'English': 'English',
    'Tafsiri kwa Kiingereza': 'Translate to English',
    'Mandhari': 'Theme',
    'Mwanga': 'Light',
    'Giza': 'Dark',
    'Mfumo': 'System',
    'Ondoka': 'Sign Out',
    'Ingia': 'Sign In',
    'Jiandikishe': 'Sign Up',

    // Auth & Identity
    'Barua Pepe': 'Email Address',
    'Nenosiri': 'Password',
    'Sahau Nenosiri?': 'Forgot Password?',
    'Weka Nenosiri Jipya': 'Reset Password',
    'Umekuwa na akaunti?': 'Already have an account?',
    'Huna akaunti?': 'Don\'t have an account?',
    'Tuma Kiungo cha Kuweka Upya': 'Send Reset Link',
    'Ingia kama Mgeni': 'Continue as Guest',

    // Paywall & Access
    'Kifurushi cha Mafunzo': 'Learning Package',
    'Hali ya Akaunti': 'Account Status',
    'Ufikiaji unasubiri idhini': 'Access pending approval',
    'Inasubiri Uidhinishaji': 'Pending Approval',
    'Akaunti Inayotumika': 'Active Account',
    'Malipo Yaliyoidhinishwa': 'Payment Approved',
    'Angalia hali yako': 'Check your status',
    'Wasiliana na Huduma kwa Wateja': 'Contact Support',

    // Assessments & Quizzes
    'Tathmini': 'Assessment',
    'Jaribio la Ujuzi': 'Skill Quiz',
    'Matokeo': 'Results',
    'Jaribu Tena': 'Try Again',
    'Umefanikiwa!': 'You Passed!',
    'Alama Zako': 'Your Score',

    // Problem Diagnosis
    'Utambuzi wa Tatizo': 'Problem Diagnosis',
    'Chagua Aina ya Zao au Mnyama': 'Select Crop or Animal',
    'Dalili za Tatizo': 'Symptoms',
    'Suluhisho Lililopendekezwa': 'Recommended Solution',
    'Tathmini Zao Lako': 'Diagnose Your Crop',

    // Admin Dashboard
    'Maandishi': 'Content',
    'Usimamizi': 'Moderation',
    'Watumiaji': 'Users',
    'Malipo': 'Payments',
    'Kozi & Yaliyomo': 'Courses & Content',
    'Uidhinishaji': 'Approvals',
    'Idhinisha': 'Approve',
    'Kataa': 'Reject',
    'Hali': 'Status',
    'Tarehe': 'Date',
    'Wajibu': 'Role',
    'Hifadhi Mabadiliko': 'Save Changes',
    'Hariri': 'Edit',
    'Ongea na Mtaalamu': 'Talk to an Expert',
    'Pata ushauri binafsi kupitia WhatsApp yetu.':
        'Get personalized advice via our WhatsApp.',
    'Tuma Ujumbe WhatsApp': 'Send WhatsApp Message',

    // Onboarding & General Actions
    'Karibu Chuo Kikuu Cha Mtaani': 'Welcome to Mtaani Open University',
    'Anza Sasa': 'Get Started',
    'Inayofuata': 'Next',
    'Ruka': 'Skip',
    'Ghairi': 'Cancel',
    'Funga': 'Close',
    'Ndio': 'Yes',
    'Hapana': 'No',
    'Imefanikiwa': 'Success',
    'Kosa Limetokea': 'An error occurred',
    'Jaribu tena': 'Try again',

    // Account Access Statuses
    'Akaunti yako imewashwa': 'Your account is active',
    'Akaunti yako inasubiri uthibitisho': 'Your account is pending verification',
    'Akaunti yako imesitishwa': 'Your account is suspended',
    'Fungua akaunti yako': 'Open your account',
    'Hujaingia': 'Not signed in',
    'Inasubiri uthibitisho': 'Pending verification',
    'Imesitishwa': 'Suspended',
    'Imewashwa': 'Active',
    'Jisajili ili kuona mafunzo yanayopatikana.':
        'Register to view available courses.',
    'Umesajiliwa. Timu ya Chuo Kikuu Cha Mtaani itathibitisha akaunti yako ili kufungua mafunzo.':
        'You are registered. The Mtaani Open University team will verify your account to unlock training.',
    'Wasiliana na timu ya Chuo Kikuu Cha Mtaani kwa msaada.':
        'Contact the Mtaani Open University team for assistance.',
    'Premium iko hai. Endelea na masomo, AI na jamii.':
        'Premium is active. Continue with lessons, AI, and community.',
    'Angalia Hali ya Uanachama': 'Check Membership Status',
    'Sitisha Kifurushi': 'Cancel Subscription',
    'Sitisha kifurushi?': 'Cancel subscription?',
    'Utapoteza ufikiaji wa masomo ya premium na Mwalimu AI mara moja.':
        'You will lose access to premium lessons and Mwalimu AI immediately.',
    'Sitisha': 'Cancel',
    'Kifurushi kimezimwa.': 'Subscription has been cancelled.',

    // Hero & Dashboard Cards
    'Kipaumbele cha leo': "Today's priority",
    'Eleza tatizo la shamba': 'Describe farm problem',
    'Chagua aina ya changamoto, ongeza zao au mnyama, kisha Mwalimu AI aanze na muktadha sahihi.':
        'Choose the challenge type, add crop or animal, then let Mwalimu AI start with the right context.',
    'Eleza tatizo': 'Describe problem',
    'Endelea na kozi': 'Continue course',
    'Jiunge na Jamii': 'Join Community',
    'Soma mwongozo wa jamii na shiriki uzoefu wako wa shamba.':
        'Read community guidelines and share your farm experience.',

    // Curriculum & Demo Courses
    'Kilimo cha Pasheni': 'Passion Fruit Farming',
    'Jifunze maandalizi ya shamba, upandaji, matunzo, magonjwa na masoko.':
        'Learn land preparation, planting, crop care, disease control, and markets.',
    'Maarufu': 'Popular',
    'Kuchagua eneo sahihi': 'Choosing the right location',
    'Kuandaa shamba kabla ya kupanda': 'Preparing the field before planting',
    'Kutambua changamoto za mwanzo': 'Identifying early challenges',
    'Kujua hatua za matunzo': 'Knowing the steps for crop care',
    'Kuchagua eneo la shamba': 'Choosing farm site',
    'Chunguza mwanga, njia ya maji na nafasi ya kupanga mistari. Rekodi hali ya eneo kabla ya kuandaa shamba.':
        'Examine sunlight, drainage, and row spacing. Record site conditions before preparing the land.',
    'Kuandaa shamba na nguzo': 'Preparing field and trellises',
    'Panga eneo la kupanda na mfumo wa kuusaidia mmea kukua. Rekebisha mpango kulingana na hali ya shamba lako.':
        'Plan planting area and vine support systems. Adjust according to your land conditions.',
    'Kufuatilia afya ya mmea': 'Monitoring plant health',
    'Kagua majani, shina na unyevu mara kwa mara. Piga picha na wasiliana na mtaalamu kabla ya kutumia tiba usiyoifahamu.':
        'Regularly inspect leaves, stem, and moisture. Take photos and consult an expert before applying unknown treatments.',

    'Ufugaji wa Kuku': 'Poultry Farming',
    'Nyumba bora, chakula, chanjo, usafi na biashara ya kuku.':
        'Quality housing, feed, vaccines, hygiene, and poultry business.',
    'Inafaa kwa wanaoanza': 'Beginner friendly',
    'Kujenga banda lenye hewa na usalama':
        'Building a safe and well-ventilated coop',
    'Kupanga ratiba ya chanjo': 'Planning vaccination schedule',
    'Kuchagua chakula bora': 'Choosing quality feed',
    'Kupunguza hatari ya magonjwa': 'Reducing disease risk',
    'Kuandaa banda': 'Preparing the coop',
    'Kagua nafasi, hewa, usalama na urahisi wa kusafisha banda kabla ya kuleta kuku.':
        'Inspect space, airflow, security, and ease of cleaning before bringing birds.',
    'Maji, chakula na usafi': 'Water, feed, and cleanliness',
    'Weka utaratibu wa maji safi, chakula na usafi, kisha andika mabadiliko unayoona kila siku.':
        'Establish a clean water, feeding, and sanitation routine, and log daily observations.',
    'Kuweka kumbukumbu za afya': 'Keeping health records',
    'Rekodi dalili, umri na historia ya kundi. Kwa chanjo, dawa au dalili kali, tumia ratiba iliyoidhinishwa na daktari wa mifugo wa eneo lako.':
        'Record symptoms, flock age, and history. For vaccines or severe signs, follow local vet approved schedules.',

    'Kilimo cha Nyanya': 'Tomato Farming',
    'Kitalu, upandaji, mbolea, udhibiti wa wadudu na maandalizi ya soko.':
        'Nursery, transplanting, fertilizer, pest control, and market readiness.',
    'Kozi mpya': 'New course',
    'Kuandaa kitalu bora': 'Preparing a quality nursery',
    'Kuhamisha miche yenye afya': 'Transplanting healthy seedlings',
    'Kutumia mbolea kwa wakati': 'Applying fertilizer on schedule',
    'Kudhibiti wadudu na magonjwa': 'Managing pests and diseases',
    'Kuandaa kitalu': 'Preparing the nursery',
    'Panga sehemu ya kitalu, ulinzi wa miche na utaratibu wa kukagua unyevu bila kuzidisha maji.':
        'Plan nursery site, seedling protection, and regular moisture checks without overwatering.',
    'Kufuatilia miche na mimea': 'Monitoring seedlings and plants',
    'Kagua majani na ukuaji, rekodi dalili na piga picha. Tambua tatizo kwa msaada wa mtaalamu kabla ya kutumia dawa.':
        'Inspect foliage and growth, note symptoms, and take photos. Identify issues with expert help before applying chemicals.',
    'Kujiandaa kwa mavuno': 'Preparing for harvest',
    'Panga uvunaji, upangaji wa ubora, hifadhi ya muda mfupi na mawasiliano na wanunuzi bila kutegemea bei isiyothibitishwa.':
        'Plan harvesting, grading, short-term storage, and buyer contacts without relying on unverified pricing.',

    // Course Navigation & Lessons
    'Dakika 5': '5 mins',
    'Dakika 6': '6 mins',
    'Dakika 10': '10 mins',
    'Dakika 15': '15 mins',
    'Dakika 20': '20 mins',
    'Bado hujaanza': 'Not started',
    'Umekamilisha': 'Completed',
    'Masomo yote yamekamilika': 'All lessons completed',
    'Kamilisha Somo': 'Complete Lesson',
    'Tazama Video': 'Watch Video',
    'Video bado haijachapishwa': 'Video not yet published',
    'Tazama video fupi ya utangulizi': 'Watch short intro video',
    'Utangulizi wa kozi hii': 'Introduction to this course',
    'Imeshindikana kufungua video.': 'Could not open video.',
    'Anza na somo la kwanza kisha fuata mpangilio wa masomo.':
        'Start with the first lesson and follow the course curriculum.',
    'Umemaliza masomo yote. Unaweza kurudia masomo au kumuuliza Mwalimu AI swali la kozi.':
        'You have finished all lessons. You can review lessons or ask Mwalimu AI a question about the course.',

    // Home & Community Topics
    'Matunda na Mbogamboga': 'Fruits & Vegetables',
    'Nafaka': 'Grains',
    'Mifugo': 'Livestock',
    'Mengineyo': 'Other',
    'Magonjwa': 'Diseases',
    'Masoko': 'Markets',
    'Kuku': 'Poultry',
    'Nyanya': 'Tomatoes',
    'Zote': 'All',

    // Problem Intake
    'Tueleze Changamoto': 'Tell Us Your Challenge',
    'Una changamoto gani leo kwenye shamba lako?':
        'What challenge do you have on your farm today?',
    'Changamoto uliyochagua': 'Selected challenge',
    'Zao au mnyama (hiari)': 'Crop or animal (optional)',
    'Mfano: nyanya, pasheni, kuku wa nyama':
        'Example: tomatoes, passion fruit, poultry',
    'Magonjwa ya mimea': 'Plant Diseases',
    'Majani kubadilika rangi, kuoza, kunyauka au ukungu.':
        'Discolored leaves, rotting, wilting, or mold.',
    'Wadudu na Visumbufu': 'Pests & Insects',
    'Vidukari, viwavi, funza au mashambulizi yasiyoeleweka.':
        'Aphids, caterpillars, worms, or unknown infestations.',
    'Mbolea na Udongo': 'Fertilizer & Soil',
    'Rutuba, aina ya mbolea, muda wa kuweka na kipimo.':
        'Fertility, fertilizer type, timing, and dosage.',
    'Maji / Umwagiliaji': 'Water / Irrigation',
    'Maji na Umwagiliaji': 'Water & Irrigation',
    'Ratiba ya maji, mifereji, ukame au maji kusimama.':
        'Watering schedule, trenches, drought, or standing water.',
    'Soko na Bei': 'Market & Prices',
    'Soko': 'Market',
    'Bei, wanunuzi, muda wa kuuza na maandalizi ya mavuno.':
        'Prices, buyers, selling window, and harvest prep.',
    'Ufugaji': 'Livestock',
    'Kuku, mbuzi au ngombe: afya, chakula, banda na chanjo.':
        'Poultry, goats, or cattle: health, feed, shelter, and vaccines.',

    // Community
    'Kubali usalama wa jamii': 'Accept community safety',
    'Kabla ya kuchapisha au kujibu, soma Masharti ya Matumizi na Mwongozo wa Jamii. Usichapishe vitisho, chuki, spam, taarifa binafsi au ushauri hatari.':
        'Before posting or replying, read the Terms of Service and Community Guidelines. Do not post threats, hate speech, spam, personal information, or harmful advice.',
    'Nakubali na Kuendelea': 'Accept and Continue',
    'Inahifadhi…': 'Saving…',
    'Masharti ya Matumizi': 'Terms of Service',
    'Mwongozo wa Jamii': 'Community Guidelines',
    'Mwongozo wa jamii': 'Community guidelines',
    'Karibu kwenye jamii ya Chuo Kikuu Cha Mtaani. Eleza hali uliyoiona, eneo na zao au mnyama. Usishiriki taarifa binafsi, na thibitisha ushauri wa dawa au chanjo na mtaalamu wa eneo lako.':
        'Welcome to the Mtaani Open University community. Describe what you observed, your location, and crop or animal. Do not share personal information, and verify medication or vaccine advice with a local specialist.',
    'Jamii imesasishwa.': 'Community updated.',
    'Mjadala huu hauwezi kufunguka kwa sasa.':
        'This discussion cannot be opened right now.',

    // AI Chat
    'Habari! Mimi ni Mwalimu AI. Nawezaje kukusaidia kuhusu kilimo leo?':
        'Hello! I am Mwalimu AI. How can I assist you with farming today?',
    'Samahani, kuna tatizo la kimtandao. Tafadhali jaribu tena baadae au wasiliana na mtaalamu.':
        'Sorry, there is a network issue. Please try again later or contact a specialist.',
    'Mwalimu AI itapatikana baada ya timu ya Chuo Kikuu Cha Mtaani kuthibitisha akaunti yako. Tunakujulisha mara akaunti yako itakapowashwa.':
        'Mwalimu AI will be available once the Mtaani Open University team verifies your account. We will notify you once your account is activated.',
    'Nirekodi dalili gani?': 'What symptoms should I record?',
    'Hatua salama ya kwanza': 'Safe first step',
    'Nipige picha gani?': 'What photos should I take?',
    'Nahitaji taarifa gani?': 'What information do I need?',
    'Je, nipime udongo?': 'Should I test my soil?',
    'Historia ya shamba': 'Farm history',
    'Ratiba ya kumwagilia': 'Watering schedule',
    'Maji yanasimama': 'Water is standing',
    'Dalili za ukame': 'Signs of drought',
    'Usafi wa banda': 'Coop hygiene',
    'Nimpateje daktari?': 'How do I find a veterinarian?',
    'Matatizo ya nyanya': 'Tomato problems',
    'Kwa nini unaripoti jibu hili?': 'Why are you reporting this response?',
    'Jibu linaudhi au halifai': 'Response is offensive or inappropriate',
    'Jibu linaweza kusababisha madhara': 'Response could cause harm',
    'Jibu si sahihi au linapotosha': 'Response is incorrect or misleading',
    'Jibu lina taarifa binafsi': 'Response contains personal information',
    'Sababu nyingine': 'Other reason',
    'Ona Kwenye Mafunzo': 'View in Courses',
    'Msaidizi wa Binadamu': 'Human Assistant',
    'Jibu limeripotiwa': 'Response reported',
    'Ripoti jibu hili': 'Report this response',
    'Muktadha uliotumwa': 'Sent Context',
    'Mwalimu AI anaandika': 'Mwalimu AI is typing',
    'Mwalimu AI anaandika…': 'Mwalimu AI is typing…',
    'Kwa nyanya, piga picha ya dalili, rekodi sehemu ya mmea iliyoathirika na hali ya unyevu. Usichague dawa kwa jina la dalili pekee; pata utambuzi wa mtaalamu wa eneo lako.':
        'For tomatoes, photograph the symptoms, record the affected plant part and moisture levels. Do not choose chemicals by symptom name alone; obtain a diagnosis from a local specialist.',
    'Kagua majani na ukuaji, rekodi dalili na tambua tatizo kwa msaada wa mtaalamu kabla ya kutumia dawa.':
        'Inspect leaves and growth, record symptoms, and identify the issue with expert guidance before applying treatments.',
    'Kwa pasheni, rekodi hali ya majani, shina, unyevu na muda ambao dalili zimeonekana. Piga picha ya sehemu iliyoathirika na wasiliana na mtaalamu wa eneo lako kabla ya kutumia dawa.':
        'For passion fruit, record the condition of leaves, stems, moisture, and how long symptoms have appeared. Photograph the affected area and consult a local specialist before applying treatments.',
    'Kagua majani, shina na unyevu mara kwa mara, kisha pata uthibitisho wa mtaalamu kabla ya kutumia tiba.':
        'Inspect leaves, stems, and moisture regularly, then obtain specialist confirmation before applying remedies.',
    'Kwa kuku, rekodi umri, idadi, dalili na muda zilipoanza. Tenga kuku mwenye dalili kali inapowezekana na wasiliana na daktari wa mifugo kwa utambuzi, chanjo au dawa.':
        'For poultry, record age, quantity, symptoms, and onset time. Isolate severely symptomatic birds where possible and contact a veterinarian for diagnosis, vaccination, or medication.',
    'Rekodi dalili na historia ya kundi, kisha tumia mwongozo wa daktari wa mifugo kwa chanjo na dawa.':
        'Record symptoms and flock history, then follow veterinary guidance for vaccines and medications.',
    'Kwa wadudu, piga picha ya mdudu na sehemu iliyoathirika, rekodi zao na eneo, kisha pata utambuzi kabla ya kuchagua hatua. Usitumie dawa usiyoifahamu.':
        'For pests, photograph the insect and affected parts, record crop and location, and obtain a diagnosis before taking action. Do not apply unfamiliar pesticides.',
    'Kwa mbolea na udongo, rekodi zao, hatua ya ukuaji na historia ya shamba. Kipimo cha udongo na ushauri wa mtaalamu wa eneo lako vinahitajika kabla ya kuchagua aina au kipimo cha mbolea.':
        'For fertilizer and soil, record crop, growth stage, and field history. Soil testing and local expert advice are required before choosing fertilizer type or dosage.',
    'Kwa maji, rekodi zao, aina ya udongo, mvua na hali ya unyevu. Kagua kama maji yanasimama au udongo umekauka, kisha linganisha na mwongozo wa zao na eneo lako.':
        'For irrigation and water, record crop, soil type, rainfall, and moisture conditions. Check for waterlogging or dry soil, then cross-reference with crop guidelines for your area.',
    'Kwa soko, thibitisha tarehe, eneo, daraja la bidhaa na chanzo cha bei. Linganisha taarifa kutoka zaidi ya mnunuzi mmoja kabla ya kufanya uamuzi.':
        'For markets, verify date, location, product grade, and price source. Compare information from multiple buyers before making decisions.',
    'Sina taarifa ya kutosha kwenye maelezo yako. Eleza zao au mnyama, eneo, dalili kuu, na muda ambao tatizo limeanza ili nipendekeze hatua salama inayofuata.':
        'I do not have enough information from your description. Specify the crop or animal, location, primary symptoms, and when the issue began so I can recommend safe next steps.',
    'Habari! Mimi ni Mwalimu AI, msaidizi wako wa kilimo na ufugaji. Unaweza kuniuliza kuhusu magonjwa ya mazao, ratiba ya maji, mbolea, au afya ya mifugo.':
        'Hello! I am Mwalimu AI, your farming and livestock assistant. You can ask me about crop diseases, watering schedules, fertilizer, or animal health.',
    'Ili kurekodi dalili kwa usahihi: 1) Angalia rangi na mabadiliko ya majani, shina, au matunda. 2) Rekodi lini dalili zilianza na jinsi zinavyoenea. 3) Pima unyevu wa udongo na hali ya hewa. 4) Piga picha wazi kabla ya kutumia tiba yoyote.':
        'To record symptoms accurately: 1) Check color and changes on leaves, stems, or fruits. 2) Note when symptoms began and how fast they are spreading. 3) Check soil moisture and weather conditions. 4) Take clear photos before applying any treatment.',
    'Hatua salama ya kwanza: 1) Tenga mmea au mnyama mwenye dalili kali ili kuzuia maambukizi. 2) Usitumie kemikali bila utambuzi rasmi. 3) Piga picha na chukua maelezo kamili. 4) Wasiliana na mtaalamu wa kilimo au mifugo wa eneo lako.':
        'Safe first step: 1) Isolate any severely affected plant or animal to prevent spreading. 2) Do not apply chemicals without a confirmed diagnosis. 3) Take clear photos and record details. 4) Consult your local agricultural officer or veterinarian.',
    'Piga picha hizi tatu muhimu: 1) Picha ya karibu ya sehemu iliyoathirika (jani, shina, tunda). 2) Picha ya mmea mzima kutoka juu hadi chini. 3) Picha ya shamba zima ili kuona ukubwa na mwelekeo wa shambulio.':
        'Take these three key photos: 1) A close-up of the affected part (leaf, stem, fruit). 2) A photo of the entire plant from top to bottom. 3) A wide shot of the field to show how widely the issue has spread.',
    'Taarifa unazohitaji kuandaa ni: jina la zao au mnyama, hatua ya ukuaji au umri, lini tatizo lilianza, eneo la shamba lako, na aina ya mbolea au dawa uliyotumia hivi karibuni.':
        'The information you need to prepare includes: crop or animal type, growth stage or age, when the issue began, farm location, and types of fertilizers or chemicals recently applied.',
    'Ndio, kupima udongo ni muhimu kujua kiwango cha pH na virutubisho (N, P, K). Hii inakusaidia kuchagua mbolea sahihi bila kupoteza fedha au kuharibu udongo.':
        'Yes, soil testing is essential to check pH and nutrient levels (N, P, K). This helps you apply the correct fertilizer without wasting money or degrading your soil.',
    'Historia ya shamba inajumuisha mazao yaliyolimwa msimu uliopita (mzunguko wa mazao), magonjwa yaliyowahi kutokea, na aina ya mbolea au viuatilifu vilivyotumika miaka miwili iliyopita.':
        'Farm history includes previous crop rotations, past disease outbreaks, and fertilizers or pesticides applied over the last two seasons.',
    'Mwaga maji asubuhi na mapema au jioni jua likishatua ili kuzuia upotevu wa maji kwa mvuke. Kagua unyevu wa udongo kwa kidole kirefu cha sentimita tano kabla ya kumwagilia tena.':
        'Water early in the morning or late in the evening to minimize evaporation loss. Test soil moisture down to a depth of 5 cm before watering again.',
    'Maji yakisimama shambani yanaweza kuozesha mizizi na kuleta magonjwa ya ukungu. Chimba mifereji ya kupitishia maji mara moja na uache kumwagilia hadi ardhi ikauke.':
        'Standing water can suffocate roots and promote fungal rot. Dig shallow drainage trenches immediately and suspend watering until the surface dries out.',
    'Dalili za ukame ni majani kujikunja au kunyauka katikati ya mchana, udongo kupasuka, na ukuaji kusimama. Weka matandazo (mulching) kuhifadhi unyevu uliopo.':
        'Drought signs include midday leaf wilting or curling, cracked soil, and stunted growth. Apply organic mulching to conserve remaining moisture.',
    'Kuhusu usafi wa banda: Badilisha matandiko (maranda) mara yanapokuwa na unyevu, fanya usafi kwa dawa ya kuua wadudu na vimelea kila wiki, na hakikisha kuna hewa ya kutosha.':
        'For coop hygiene: replace wet bedding shavings promptly, disinfect drinkers and feeders weekly, and ensure continuous cross-ventilation to prevent respiratory disease.',
    'Unaweza kupata daktari wa mifugo kwa kuwasiliana na afisa ugani wa kata yako, au kutumia kitufe cha "Msaidizi wa Binadamu" hapa chini kwa msaada wa haraka kupitia WhatsApp.':
        'You can reach a qualified veterinarian through your local ward livestock extension officer, or tap the "Human Assistant" button below for direct WhatsApp assistance.',

    // Profile & Activities
    'Mkulima Mwanachama': 'Member Farmer',
    'Mgeni': 'Guest',
    'Shughuli Zangu': 'My Activity',
    'Mafunzo yangu': 'My learning',
    'Nyaraka zilizohifadhiwa': 'Saved documents',
    'Kazi za vitendo': 'Practical assignments',
    'Msaada / WhatsApp': 'Support / WhatsApp',
    'Sheria na Sera': 'Terms & Policies',
    'Toka kwenye Akaunti': 'Sign Out',
    'Futa Akaunti': 'Delete Account',
    'Simamia maandishi, usimamizi, na watumiaji':
        'Manage content, moderation, and users',

    // Paywall & Benefits
    'Ufikiaji wa Mwalimu AI': 'Access to Mwalimu AI',
    'Masomo yaliyo kwenye kifurushi': 'Lessons included in package',
    'Njia ya kuwasiliana na mtaalamu': 'Direct connection to specialists',
    'Programu hii haitoi ununuzi ndani ya programu.':
        'This app does not offer in-app purchases.',
    'Onyesha Hali Upya': 'Refresh Status',
    'Ondoka kwenye Akaunti': 'Log Out of Account',
    'Ukishasaidiwa na timu, ufikiaji wako utarudi hapa hapa.':
        'Once assisted by the team, your access will be restored right here.',
    'Mafunzo yatafunguka mara tu timu ya Chuo Kikuu Cha Mtaani itakapothibitisha akaunti yako.':
        'Courses will unlock as soon as the Mtaani Open University team verifies your account.',
    'Wiki 1': '1 Week',
    'Ufikiaji wa haraka': 'Quick access',
    'Mwezi 1': '1 Month',
    'Thamani bora zaidi': 'Best value',
    'Mwaka 1': '1 Year',
    'Okoa TZS 20,000': 'Save TZS 20,000',

    // Problem & Dashboard
    'Chagua aina ya changamoto ili kupata mwongozo sahihi wa hatua za kuchukua.':
        'Select problem category to get step-by-step guidance.',
    'Mada maarufu za matatizo': 'Trending Problem Topics',
    'Somo la sasa': 'Current lesson',
    'Limekamilika': 'Completed',
    'Wadudu na Magonjwa': 'Pests & Diseases',
    'Umwagiliaji na Maji': 'Irrigation & Water',
    'Afya ya Mifugo': 'Livestock Health',
    'Sijui tatizo': "I don't know the problem",

    // Community
    'Hakuna machapisho bado': 'No posts yet',
    'Kuwa wa kwanza kuuliza swali au shiriki uzoefu wako na wakulima wengine.':
        'Be the first to ask a question or share your experience with other farmers.',
    'Jaribu chaguo lingine la mada au angalia machapisho yote.':
        'Try another topic option or view all posts.',
    'Tuma Swali': 'Ask Question',
    'Ona Zote': 'View All',
    'Jibu limehifadhiwa.': 'Reply saved.',
    'Imeshindikana kutuma jibu. Angalia mtandao wako.':
        'Failed to send reply. Check your network.',
    'Ripoti ya mtumiaji imepokelewa.': 'User report received.',
    'Ripoti ya post imepokelewa.': 'Post report received.',
    'Imeshindikana kutuma ripoti. Angalia mtandao wako.':
        'Failed to submit report. Check your network.',
    'Mtumiaji amezuiwa.': 'User has been blocked.',
    'Imeshindikana kumzuia mtumiaji.': 'Failed to block user.',
    'Zuia': 'Block',
    'Hutaona tena machapisho ya mtumiaji huyu kwenye jamii. Unaweza kuwasiliana na msaada ukitaka kuondoa kizuizi.':
        'You will no longer see posts from this user in the community. You can contact support to unblock.',
    'Majadiliano': 'Discussions',
    'Usalama wa jamii': 'Community safety',
    'Post imeripotiwa': 'Post reported',
    'Ripoti post': 'Report post',
    'Ripoti mtumiaji': 'Report user',
    'Zuia mtumiaji': 'Block user',
    'Majibu ya wakulima': 'Farmer replies',
    'Hakuna majibu bado. Kuwa wa kwanza kusaidia mkulima mwenzako.':
        'No replies yet. Be the first to help a fellow farmer.',
    'Andika jibu la kusaidia…': 'Write a helpful reply…',
    'Kwa nini unaripoti?': 'Why are you reporting?',
    'Taka au matangazo yasiyofaa': 'Spam or inappropriate ads',
    'Unyanyasaji au vitisho': 'Harassment or threats',
    'Chuki dhidi ya kundi': 'Hate speech against a group',
    'Maudhui ya kingono': 'Sexual content',
    'Vurugu au maudhui hatari': 'Violence or dangerous content',
    'Taarifa hatari au ya kupotosha': 'Harmful or misleading information',
    'Taarifa binafsi imewekwa wazi': 'Personal privacy exposed',
    'Swali au changamoto': 'Question or challenge',
    'Mfano: Majani ya nyanya yana madoa ya njano…':
        'Example: Tomato leaves have yellow spots…',
    'Eneo': 'Location',
    'Mfano: Morogoro': 'Example: Morogoro',
    'Chagua mada': 'Choose topic',
    'Ongeza picha (hiari)': 'Add photo (optional)',
    'Ondoa picha': 'Remove photo',
    'Chagua picha': 'Choose photo',
    'Inatuma…': 'Sending…',
    'Tuma kwenye Jamii': 'Post to Community',
    'Andika maelezo ya kutosha (angalau herufi 12) kuhusu changamoto.':
        'Write sufficient description (at least 12 characters) about the challenge.',
    'Weka eneo lako ili wakulima wakuelewe vizuri.':
        'Enter your location so other farmers understand better.',
    'Aina ya picha haikubaliki. Tumia JPG, PNG au WEBP.':
        'Image format not supported. Use JPG, PNG or WEBP.',
    'Imeshindikana kupakia picha; post itatumwa bila picha.':
        'Failed to upload image; post will be sent without photo.',
    'Post imetumwa kwenye jamii.': 'Post published to community.',
    'Imeshindikana kutuma post. Angalia mtandao wako.':
        'Failed to send post. Check your network.',
    'Piga simu kwa msaada': 'Call for support',
    'Mtaalamu aliyethibitishwa': 'Verified expert',
    'Jamii ya Chuo Kikuu Cha Mtaani': 'Mtaani Open University Community',
    'Hatua inayofuata': 'Next step',
    'Tumia AI kupanga muhtasari wa mjadala au mpe mtaalamu muktadha wake.':
        'Use AI to organize a discussion summary or provide context to an expert.',
    'Andaa muhtasari': 'Prepare summary',
    'Inahitaji haraka': 'Urgent',
    'Tafuta kwenye jamii': 'Search in community',
    'Masharti yamekubaliwa.': 'Terms accepted.',
    'wamependa': 'liked',
    'majibu': 'replies',

    // Profile & Settings
    'Wasiliana nasi kupitia WhatsApp': 'Contact us via WhatsApp',
    'Sera ya Faragha': 'Privacy Policy',
    'Futa akaunti na data': 'Delete account and data',
    'Hatua hii haiwezi kutenduliwa': 'This action cannot be undone',
    'Omba kufuta akaunti ya admin': 'Request admin account deletion',
    'Inahitaji uhakiki wa usimamizi': 'Requires management review',
    'Ondoka kwenye akaunti?': 'Sign out of account?',
    'Utahitaji kuingia tena kwa barua pepe na nenosiri.':
        'You will need to sign in again with your email and password.',
    'Futa akaunti kabisa?': 'Delete account permanently?',
    'Futa akaunti': 'Delete account',
    'Akaunti na data zako zimefutwa.': 'Your account and data have been deleted.',
    'Imeshindikana kufuta akaunti. Angalia mtandao wako na ujaribu tena.':
        'Failed to delete account. Check your network and try again.',
    'Muonekano wa app': 'App Appearance',
    'Chagua mwanga, giza, au fuata mipangilio ya kifaa.':
        'Choose light, dark, or follow device settings.',
    'Jina lako': 'Your Name',
    'Mfano: Asha': 'Example: Asha',
    'Eneo la kawaida': 'Default Location',
    'Hifadhi Mipangilio': 'Save Settings',
    'Mipangilio imehifadhiwa.': 'Settings saved.',
    'Nyaraka Zilizohifadhiwa': 'Saved Documents',
    'Tafuta nyaraka': 'Search documents',
    'Hujaweka nyaraka bado': 'No documents saved yet',
    'Chagua nyaraka hapa chini ili uzihifadhi kwa kusoma baadaye.':
        'Choose documents below to save them for later reading.',
    'Nyaraka zote': 'All Documents',
    'Ondoa': 'Remove',

    // AI Chat & Reports
    'Ripoti ya jibu la AI imepokelewa.': 'AI answer report received.',
    'Imeshindikana kutuma ripoti.': 'Failed to submit report.',

    // Paywall & Access Status
    'Ingia / Jisajili': 'Sign In / Register',
    'Bado hujawashiwa akaunti. Jaribu tena baadaye.':
        'Your account is not activated yet. Please try again later.',

    // Search
    'Futa utafutaji': 'Clear search',
    'Inatafuta': 'Searching',
    'Utafutaji wa mtandaoni umesitishwa kwa muda mfupi. Subiri kisha ujaribu tena.':
        'Online search is temporarily paused. Please wait and try again.',
    'Utafutaji haukukamilika': 'Search incomplete',
    'Jaribu neno lingine au chagua kichujio tofauti.':
        'Try another word or choose a different filter.',
    'Matokeo zaidi yapo. Ongeza maelezo kwenye utafutaji wako.':
        'More results available. Add more detail to your search.',
    'Matokeo yanatoka kwenye maudhui yaliyohifadhiwa. Huenda si kamili.':
        'Results are from offline cached content. They may be incomplete.',
    'Mada maarufu': 'Popular Topics',
    'Kozi hii haiwezi kufunguka kwa sasa.':
        'This course cannot be opened right now.',
    'Maudhui hayawezi kufunguka kwa sasa.':
        'This content cannot be opened right now.',
  };

  /// English to Swahili reverse mapping.
  static final Map<String, String> _enToSw = {
    for (final entry in _swToEn.entries) entry.value: entry.key,
  };

  /// Translates text based on current locale (or target language flag).
  /// If `isEnglish` is true, translates Swahili -> English.
  /// If `isEnglish` is false, translates English -> Swahili (or keeps original Swahili).
  static String translate(String text, {required bool isEnglish}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    if (isEnglish) {
      if (_swToEn.containsKey(trimmed)) {
        return _swToEn[trimmed]!;
      }
      final lower = trimmed.toLowerCase();
      for (final entry in _swToEn.entries) {
        if (entry.key.toLowerCase() == lower) {
          return entry.value;
        }
      }
      if (_enToSw.containsKey(trimmed)) {
        return text;
      }

      // Pattern-based dynamic notification translations (Swahili -> English)
      final activeMatch =
          RegExp(r'^(.*)\s+imewashwa kwenye kifaa hiki\.?$').firstMatch(trimmed);
      if (activeMatch != null) {
        final plan = activeMatch.group(1)!.trim();
        return '$plan is active on this device.';
      }

      final assessMatch = RegExp(
              r'^Umewasilisha kazi\s+(\d+)\.\s+Endelea kutumia maarifa shambani\.?$')
          .firstMatch(trimmed);
      if (assessMatch != null) {
        final count = assessMatch.group(1)!;
        return 'You have submitted $count assignments. Keep using your skills on the farm.';
      }

      final docsMatch =
          RegExp(r'^Una nyaraka\s+(\d+)\s+za kusoma baadaye\.?$')
              .firstMatch(trimmed);
      if (docsMatch != null) {
        final count = docsMatch.group(1)!;
        return 'You have $count documents saved to read later.';
      }

      final postsMatch =
          RegExp(r'^Umetuma post\s+(\d+)\.\s+Angalia majibu mapya\.?$')
              .firstMatch(trimmed);
      if (postsMatch != null) {
        final count = postsMatch.group(1)!;
        return 'You have shared $count posts. Check for new replies.';
      }

      final replyMatch =
          RegExp(r'^(.*)\s+amejibu post yako\.?$').firstMatch(trimmed);
      if (replyMatch != null) {
        final author = replyMatch.group(1)!.trim();
        final translatedAuthor = _swToEn[author] ?? author;
        return '$translatedAuthor replied to your post.';
      }

      // Dynamic account access patterns
      final activePlanWithDetailsMatch = RegExp(
              r'^(.*)\s+imewashwa\.\s*Unaweza kuendelea na masomo na Mwalimu AI\.?$')
          .firstMatch(trimmed);
      if (activePlanWithDetailsMatch != null) {
        final plan = activePlanWithDetailsMatch.group(1)!.trim();
        return '$plan is active. You can continue with lessons and Mwalimu AI.';
      }

      final activePlanMatch =
          RegExp(r'^(.*)\s+imewashwa\.?$').firstMatch(trimmed);
      if (activePlanMatch != null) {
        final plan = activePlanMatch.group(1)!.trim();
        return '$plan is active';
      }

      // Dynamic lesson and progress patterns
      final nextLessonMatch =
          RegExp(r'^Somo linalofuata:\s*(.*)$').firstMatch(trimmed);
      if (nextLessonMatch != null) {
        final lesson = nextLessonMatch.group(1)!.trim();
        final translatedLesson = translate(lesson, isEnglish: true);
        return 'Next lesson: $translatedLesson';
      }

      final completedSomeMatch = RegExp(
              r'^Umekamilisha somo\s*(\d+)\s*kati ya\s*(\d+)\.\s*Endelea na somo linalofuata\.?$')
          .firstMatch(trimmed);
      if (completedSomeMatch != null) {
        return 'You completed lesson ${completedSomeMatch.group(1)} of ${completedSomeMatch.group(2)}. Continue with the next lesson.';
      }

      final lessonCountMatch =
          RegExp(r'^(\d+)/(\d+)\s+masomo$').firstMatch(trimmed);
      if (lessonCountMatch != null) {
        return '${lessonCountMatch.group(1)}/${lessonCountMatch.group(2)} lessons';
      }

      final percentProgressMatch =
          RegExp(r'^(\d+)%\s+ya\s+(.*)\s+imekamilika$').firstMatch(trimmed);
      if (percentProgressMatch != null) {
        final pct = percentProgressMatch.group(1)!;
        final title = percentProgressMatch.group(2)!.trim();
        return '$pct% of ${translate(title, isEnglish: true)} completed';
      }

      final savedCountMatch =
          RegExp(r'^(\d+)\s+zimehifadhiwa$').firstMatch(trimmed);
      if (savedCountMatch != null) {
        return '${savedCountMatch.group(1)} saved';
      }

      final accountEmailMatch =
          RegExp(r'^Akaunti:\s*(.*)$').firstMatch(trimmed);
      if (accountEmailMatch != null) {
        return 'Account: ${accountEmailMatch.group(1)}';
      }

      final resultsCountMatch =
          RegExp(r'^(\d+)\s+matokeo yamepatikana\.?$').firstMatch(trimmed);
      if (resultsCountMatch != null) {
        return '${resultsCountMatch.group(1)} results found.';
      }

      final continueCourseMatch =
          RegExp(r'^Endelea na kozi\s+(.*)$').firstMatch(trimmed);
      if (continueCourseMatch != null) {
        final title = continueCourseMatch.group(1)!.trim();
        return 'Continue course ${translate(title, isEnglish: true)}';
      }

      final askAiReadyMatch =
          RegExp(r'^Mwalimu AI yuko tayari kujibu maswali kuhusu\s*(.*)$')
              .firstMatch(trimmed);
      if (askAiReadyMatch != null) {
        final topic = askAiReadyMatch.group(1)!.trim();
        return 'Mwalimu AI is ready to answer questions about ${translate(topic, isEnglish: true)}';
      }

      final likesMatch = RegExp(r'^(\d+)\s+wamependa$').firstMatch(trimmed);
      if (likesMatch != null) {
        return '${likesMatch.group(1)} liked';
      }

      final repliesMatch = RegExp(r'^(\d+)\s+majibu$').firstMatch(trimmed);
      if (repliesMatch != null) {
        return '${repliesMatch.group(1)} replies';
      }

      final summaryMatch =
          RegExp(r'^(\d+)\s+mijadala,\s+(\d+)\s+majibu ya wataalamu\.?$')
              .firstMatch(trimmed);
      if (summaryMatch != null) {
        return '${summaryMatch.group(1)} discussions, ${summaryMatch.group(2)} expert replies.';
      }

      final noPostsForTopicMatch =
          RegExp(r'^Hakuna machapisho kwa "(.*)"$').firstMatch(trimmed);
      if (noPostsForTopicMatch != null) {
        final topic = noPostsForTopicMatch.group(1)!;
        return 'No posts for "${translate(topic, isEnglish: true)}"';
      }

      final blockAuthorMatch = RegExp(r'^Zuia (.*)\?$').firstMatch(trimmed);
      if (blockAuthorMatch != null) {
        return 'Block ${blockAuthorMatch.group(1)}?';
      }

      String result = text;
      _swToEn.forEach((swKey, enVal) {
        if (swKey.length >= 4 && result.contains(swKey)) {
          result = result.replaceAll(swKey, enVal);
        }
      });
      return result;
    } else {
      if (_enToSw.containsKey(trimmed)) {
        return _enToSw[trimmed]!;
      }
      final lower = trimmed.toLowerCase();
      for (final entry in _enToSw.entries) {
        if (entry.key.toLowerCase() == lower) {
          return entry.value;
        }
      }
      if (_swToEn.containsKey(trimmed)) {
        return text;
      }

      // Pattern-based dynamic notification translations (English -> Swahili)
      final activeMatchEn =
          RegExp(r'^(.*)\s+is (?:active|enabled) on this device\.?$')
              .firstMatch(trimmed);
      if (activeMatchEn != null) {
        final plan = activeMatchEn.group(1)!.trim();
        return '$plan imewashwa kwenye kifaa hiki.';
      }

      final assessMatchEn = RegExp(
              r'^You have submitted\s+(\d+)\s+assignments\.\s+Keep using your skills on the farm\.?$')
          .firstMatch(trimmed);
      if (assessMatchEn != null) {
        final count = assessMatchEn.group(1)!;
        return 'Umewasilisha kazi $count. Endelea kutumia maarifa shambani.';
      }

      final docsMatchEn =
          RegExp(r'^You have\s+(\d+)\s+documents saved to read later\.?$')
              .firstMatch(trimmed);
      if (docsMatchEn != null) {
        final count = docsMatchEn.group(1)!;
        return 'Una nyaraka $count za kusoma baadaye.';
      }

      final postsMatchEn =
          RegExp(r'^You have shared\s+(\d+)\s+posts\.\s+Check for new replies\.?$')
              .firstMatch(trimmed);
      if (postsMatchEn != null) {
        final count = postsMatchEn.group(1)!;
        return 'Umetuma post $count. Angalia majibu mapya.';
      }

      final replyMatchEn =
          RegExp(r'^(.*)\s+replied to your post\.?$').firstMatch(trimmed);
      if (replyMatchEn != null) {
        final author = replyMatchEn.group(1)!.trim();
        final translatedAuthor = _enToSw[author] ?? author;
        return '$translatedAuthor amejibu post yako.';
      }

      final nextLessonMatchEn =
          RegExp(r'^Next lesson:\s*(.*)$').firstMatch(trimmed);
      if (nextLessonMatchEn != null) {
        final lesson = nextLessonMatchEn.group(1)!.trim();
        return 'Somo linalofuata: ${translate(lesson, isEnglish: false)}';
      }

      final lessonCountMatchEn =
          RegExp(r'^(\d+)/(\d+)\s+lessons$').firstMatch(trimmed);
      if (lessonCountMatchEn != null) {
        return '${lessonCountMatchEn.group(1)}/${lessonCountMatchEn.group(2)} masomo';
      }

      final percentProgressMatchEn =
          RegExp(r'^(\d+)%\s+of\s+(.*)\s+completed$').firstMatch(trimmed);
      if (percentProgressMatchEn != null) {
        final pct = percentProgressMatchEn.group(1)!;
        final title = percentProgressMatchEn.group(2)!.trim();
        return '$pct% ya ${translate(title, isEnglish: false)} imekamilika';
      }

      final savedCountMatchEn =
          RegExp(r'^(\d+)\s+saved$').firstMatch(trimmed);
      if (savedCountMatchEn != null) {
        return '${savedCountMatchEn.group(1)} zimehifadhiwa';
      }

      final accountEmailMatchEn =
          RegExp(r'^Account:\s*(.*)$').firstMatch(trimmed);
      if (accountEmailMatchEn != null) {
        return 'Akaunti: ${accountEmailMatchEn.group(1)}';
      }

      final resultsCountMatchEn =
          RegExp(r'^(\d+)\s+results found\.?$').firstMatch(trimmed);
      if (resultsCountMatchEn != null) {
        return '${resultsCountMatchEn.group(1)} matokeo yamepatikana.';
      }

      String result = text;
      _enToSw.forEach((enKey, swVal) {
        if (enKey.length >= 4 && result.contains(enKey)) {
          result = result.replaceAll(enKey, swVal);
        }
      });
      return result;
    }
  }

  /// Helper to translate a string using context's current session language.
  static String tr(String text, BuildContext context) {
    final isEnglish =
        context.session.state.languagePreference.languageCode == 'en';
    return translate(text, isEnglish: isEnglish);
  }
}

/// Flutter extensions for convenient text translation syntax:
/// Usage: `'Nyumbani'.tr(context)`
extension StringTranslateX on String {
  String tr(BuildContext context) => AppTranslations.tr(this, context);
}

/// Context extension for quick language check and translation.
/// Usage: `context.tr('Nyumbani')` or `context.isEnglish`
extension BuildContextTranslateX on BuildContext {
  bool get isEnglish =>
      session.state.languagePreference.languageCode == 'en';

  String tr(String text) => AppTranslations.translate(text, isEnglish: isEnglish);
}
