// core/data/ghana_locations.dart
// Region → City/Town → Areas/Suburbs

class GhanaLocations {
  GhanaLocations._();

  static const regions = [
    'Ashanti Region',
    'Greater Accra Region',
    'Western Region',
    'Central Region',
    'Eastern Region',
    'Volta Region',
    'Northern Region',
    'Upper East Region',
    'Upper West Region',
    'Bono Region',
    'Bono East Region',
    'Ahafo Region',
    'Savannah Region',
    'North East Region',
    'Oti Region',
    'Western North Region',
  ];

  static const Map<String, List<String>> cities = {
    'Ashanti Region': [
      'Kumasi', 'Obuasi', 'Ejisu', 'Mampong', 'Konongo',
      'Bekwai', 'Offinso', 'Nkawie', 'Agogo', 'Mankranso',
    ],
    'Greater Accra Region': [
      'Accra', 'Tema', 'Madina', 'Ashaiman', 'Kasoa',
      'Teshie', 'Nungua', 'Dansoman', 'Spintex', 'East Legon',
    ],
    'Western Region': [
      'Takoradi', 'Sekondi', 'Tarkwa', 'Axim', 'Elubo',
      'Agona Nkwanta', 'Shama', 'Bogoso',
    ],
    'Central Region': [
      'Cape Coast', 'Winneba', 'Kasoa', 'Mankessim', 'Saltpond',
      'Dunkwa-on-Offin', 'Elmina', 'Swedru',
    ],
    'Eastern Region': [
      'Koforidua', 'Nkawkaw', 'Suhum', 'Akim Oda', 'Nsawam',
      'Akropong', 'Aburi', 'Somanya',
    ],
    'Volta Region': [
      'Ho', 'Hohoe', 'Keta', 'Kpando', 'Anloga',
      'Akatsi', 'Aflao', 'Sogakope',
    ],
    'Northern Region': [
      'Tamale', 'Yendi', 'Damongo', 'Savelugu', 'Bimbilla',
      'Tolon', 'Kumbungu',
    ],
    'Upper East Region': [
      'Bolgatanga', 'Navrongo', 'Bawku', 'Zebilla', 'Paga',
    ],
    'Upper West Region': [
      'Wa', 'Tumu', 'Lawra', 'Nandom', 'Jirapa',
    ],
    'Bono Region': [
      'Sunyani', 'Berekum', 'Dormaa Ahenkro', 'Wenchi', 'Odumase',
    ],
    'Bono East Region': [
      'Techiman', 'Nkoranza', 'Kintampo', 'Atebubu', 'Yeji',
    ],
    'Ahafo Region': [
      'Goaso', 'Bechem', 'Duayaw Nkwanta', 'Kukuom',
    ],
    'Savannah Region': [
      'Damongo', 'Bole', 'Salaga', 'Sawla',
    ],
    'North East Region': [
      'Nalerigu', 'Gambaga', 'Walewale', 'Chereponi',
    ],
    'Oti Region': [
      'Dambai', 'Nkwanta', 'Kadjebi', 'Jasikan',
    ],
    'Western North Region': [
      'Sefwi Wiawso', 'Bibiani', 'Juaboso', 'Enchi',
    ],
  };

  static const Map<String, List<String>> areas = {
    // ── Kumasi ──
    'Kumasi': [
      'Abrepo', 'Abuakwa', 'Adum', 'Ahinsan', 'Ahodwo',
      'Airport', 'Amakom', 'Amesii', 'Anloga Junction', 'Appiadu',
      'Asafo', 'Ashtown', 'Asuoyeboa', 'Ayeduase',
      'Ayigya', 'Bantama', 'Bohyen', 'Bomso', 'Breman',
      'Buokrom', 'Chirapatre', 'Daban', 'Dakwadwom', 'Dichemso',
      'Edwenase', 'Ejisu Road', 'Emena', 'Fante Newtown',
      'Gaza/Kentinkrono', 'Gyinyase', 'Kaase', 'KNUST Campus',
      'Kotei', 'Kronum', 'Kwadaso', 'Lake Road',
      'Maakro', 'Manhyia', 'New Tafo', 'Nhyiaeso', 'North Suntreso',
      'Oforikrom', 'Old Tafo', 'Pampaso', 'Patasi',
      'Santasi', 'Sofoline', 'South Suntreso', 'Suame',
      'Tafo', 'Tech Junction', 'West End',
    ],
    // ── Accra ──
    'Accra': [
      'Abelenkpe', 'Abeka', 'Ablekuma', 'Achimota', 'Adabraka',
      'Adenta', 'Adjiringanor', 'Agbogba', 'Airport City',
      'Airport Hills', 'Airport Residential Area', 'Alajo',
      'Amasaman', 'Ashaley Botwe', 'Baatsona',
      'Burma Camp', 'Cantonments', 'Chorkor', 'Dansoman',
      'Darkuman', 'Dome', 'Dome-Kwabenya', 'Dzorwulu',
      'East Airport', 'East Cantonments', 'East Legon', 'East Legon Hills',
      'Gbawe', 'Haatso', 'Jamestown', 'Kanda',
      'Kaneshie', 'Kisseman', 'Kokomlemle', 'Kokrobite',
      'Korle Bu', 'Kotobabi', 'Kwashieman', 'La',
      'Labadi', 'Labone', 'Lakeside Estate', 'Lapaz',
      'Lashibi', 'Legon', 'MacCarthy Hill', 'Madina',
      'Mallam', 'Mamprobi', 'Mataheko', 'Ministries',
      'New Achimota', 'New Legon', 'Nima', 'North Kaneshie',
      'North Legon', 'North Ridge', 'Nungua', 'Odorkor',
      'Ofankor', 'Ogbojo', 'Osu', 'Oyarifa',
      'Pokuase', 'Ridge', 'Roman Ridge', 'Sakumono',
      'Santa Maria', 'Shiashie', 'South La', 'South Legon',
      'Sowutuom', 'Spintex', 'Taifa', 'Tesano',
      'Teshie', 'Tetegu', 'Trassaco Valley',
      'Weija', 'West Airport', 'West Legon', 'West Ridge',
    ],
    // ── Tema ──
    'Tema': [
      'Community 1', 'Community 2', 'Community 3', 'Community 4',
      'Community 5', 'Community 6', 'Community 7', 'Community 8',
      'Community 9', 'Community 10', 'Community 11', 'Community 12',
      'Community 13', 'Community 14', 'Community 15', 'Community 16',
      'Community 17', 'Community 18', 'Community 19', 'Community 20',
      'Community 21', 'Community 22', 'Community 23', 'Community 24',
      'Community 25', 'Harbour', 'Industrial Area', 'New Town',
      'Manhean', 'Tema West', 'Kpone', 'Dawhenya',
    ],
    // ── Cape Coast ──
    'Cape Coast': [
      'Abura', 'Adisadel', 'Bakaano', 'Cape Coast University', 'Duakor',
      'Esikafo', 'Kakumdo', 'Kotokuraba', 'Mfantsipim', 'OLA',
      'Pedu', 'Science', 'UCC Campus',
    ],
    // ── Takoradi ──
    'Takoradi': [
      'Airport Ridge', 'Anaji', 'Beach Road', 'Chapel Hill',
      'Effia', 'Essikado', 'Fijai', 'Kojokrom',
      'Market Circle', 'New Site', 'Tanokrom', 'West Fijai',
    ],
    // ── Ho ──
    'Ho': [
      'Bankoe', 'Ho Dome', 'Ho Heve', 'Ho Kpodzi',
      'Ho Polytechnic Area', 'Mawuli', 'Stadium Area',
    ],
    // ── Tamale ──
    'Tamale': [
      'Aboabo', 'Choggu', 'Jisonayili', 'Kaladan',
      'Lamashegu', 'Sakasaka', 'UDS Campus', 'Vittin',
    ],
    // ── Koforidua ──
    'Koforidua': [
      'Adweso', 'Effiduase', 'Nsukwao', 'Old Estate',
      'Oyoko', 'Srodae', 'Tech Area',
    ],
    // ── Sunyani ──
    'Sunyani': [
      'Abesim', 'Baakoniaba', 'Estate', 'Fiapre',
      'New Town', 'Nkrankwanta', 'Penkwase', 'South Ridge',
    ],
  };

  static List<String> getCities(String region) => cities[region] ?? [];

  static List<String> getAreas(String city) => areas[city] ?? [];
}
