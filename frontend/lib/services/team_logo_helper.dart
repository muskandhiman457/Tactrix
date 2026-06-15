String? getIplLogoAsset(String teamName) {
  final name = teamName.toLowerCase().trim();
  if (name.contains("chennai") || name.contains("super kings") || name.contains("csk")) {
    return "assets/logos/csk logo.png";
  } else if (name.contains("mumbai") || name == "mi" || name.contains("mumbai indians")) {
    return "assets/logos/MI logo.jpg";
  } else if (name.contains("royal challengers") || name.contains("rcb") || name.contains("bengaluru") || name.contains("bangalore")) {
    return "assets/logos/RCB logo.jpg";
  } else if (name.contains("kolkata") || name.contains("knight riders") || name.contains("kkr")) {
    return "assets/logos/kkr logo.jpg";
  } else if (name.contains("rajasthan") || name == "rr" || name.contains("rajasthan royals")) {
    return "assets/logos/Rajasthan royal.jpg";
  } else if (name.contains("delhi") || name == "dc" || name.contains("delhi capitals")) {
    return "assets/logos/delhi capitals logo.png";
  } else if (name.contains("punjab") || name.contains("kings xi") || name == "pbks" || name.contains("punjab kings")) {
    return "assets/logos/Punjab kings logo.jpg";
  } else if (name.contains("sunrisers") || name.contains("hyderabad") || name == "srh") {
    return "assets/logos/sunrisers hyderabad logo.png";
  } else if (name.contains("gujarat") || name == "gt" || name.contains("gujarat titans")) {
    return "assets/logos/GT logo.png";
  } else if (name.contains("lucknow") || name.contains("super giants") || name == "lsg") {
    return "assets/logos/LSG logo.jpg";
  }
  return null;
}

String? getKabaddiLogoAsset(String teamName) {
  final name = teamName.toLowerCase().trim();
  if (name.contains("patna") || name.contains("pirates") || name == "pat") {
    return "assets/logos/patna_pirates.png";
  } else if (name.contains("mumba") || name == "mum") {
    return "assets/logos/u_mumba.png";
  } else if (name.contains("jaipur") || name.contains("panthers") || name == "jai") {
    return "assets/logos/jaipur_pink_panthers.png";
  } else if (name.contains("bengaluru") || name.contains("bulls") || name == "blr") {
    return "assets/logos/bengaluru_bulls.png";
  } else if (name.contains("delhi") || name.contains("dabang") || name == "del") {
    return "assets/logos/dabang_delhi.png";
  } else if (name.contains("puneri") || name.contains("paltan") || name == "pun") {
    return "assets/logos/puneri_paltan.png";
  }
  return null;
}

String? getCountryFlagUrl(String teamName) {
  final name = teamName.toLowerCase().trim();

  // Exclude IPL/Kabaddi/Club teams to avoid false positives (e.g., Mumbai Indians matching "India")
  if (getIplLogoAsset(teamName) != null || getKabaddiLogoAsset(teamName) != null) {
    return null;
  }

  // Special cricket/football team flag overrides
  if (name.contains('west indies') || name.contains('windies') || name == 'wi') {
    return 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Flag_of_the_West_Indies_Cricket_Board.svg/320px-Flag_of_the_West_Indies_Cricket_Board.svg.png';
  }

  // Comprehensive map of country names & common short codes (ISO 3166-1 alpha-2 where applicable)
  final Map<String, String> countryCodeMap = {
    'india': 'in',
    'ind': 'in',
    'australia': 'au',
    'aus': 'au',
    'england': 'gb-eng',
    'eng': 'gb-eng',
    'south africa': 'za',
    'rsa': 'za',
    'sa': 'za',
    'pakistan': 'pk',
    'pak': 'pk',
    'new zealand': 'nz',
    'nz': 'nz',
    'sri lanka': 'lk',
    'sl': 'lk',
    'bangladesh': 'bd',
    'ban': 'bd',
    'afghanistan': 'af',
    'afg': 'af',
    'netherlands': 'nl',
    'ned': 'nl',
    'scotland': 'gb-sct',
    'sco': 'gb-sct',
    'ireland': 'ie',
    'ire': 'ie',
    'zimbabwe': 'zw',
    'zim': 'zw',
    'united states': 'us',
    'usa': 'us',
    'nepal': 'np',
    'nep': 'np',
    'oman': 'om',
    'omn': 'om',
    'united arab emirates': 'ae',
    'uae': 'ae',
    'canada': 'ca',
    'can': 'ca',
    'namibia': 'na',
    'nam': 'na',
    'papua new guinea': 'pg',
    'png': 'pg',
    'uganda': 'ug',
    'uga': 'ug',
    'hong kong': 'hk',
    'hkg': 'hk',
    'kenya': 'ke',
    'ken': 'ke',
    'singapore': 'sg',
    'sgp': 'sg',
    'malaysia': 'my',
    'mas': 'my',
    'kuwait': 'kw',
    'kwt': 'kw',
    'qatar': 'qa',
    'qat': 'qa',
    'italy': 'it',
    'ita': 'it',
    'germany': 'de',
    'ger': 'de',
    'spain': 'es',
    'esp': 'es',
    'argentina': 'ar',
    'arg': 'ar',
    'france': 'fr',
    'fra': 'fr',
    'portugal': 'pt',
    'por': 'pt',
    'brazil': 'br',
    'bra': 'br',
    'japan': 'jp',
    'jpn': 'jp',
    'belgium': 'be',
    'bel': 'be',
    'croatia': 'hr',
    'cro': 'hr',
    'uruguay': 'uy',
    'uru': 'uy',
    'senegal': 'sn',
    'sen': 'sn',
    'morocco': 'ma',
    'mar': 'ma',
    'colombia': 'co',
    'col': 'co',
    'chile': 'cl',
    'chi': 'cl',
    'peru': 'pe',
    'ecuador': 'ec',
    'ecu': 'ec',
    'venezuela': 've',
    'ven': 've',
    'south korea': 'kr',
    'kor': 'kr',
    'saudi arabia': 'sa',
    'ksa': 'sa',
    'iran': 'ir',
    'irn': 'ir',
    'egypt': 'eg',
    'egy': 'eg',
    'nigeria': 'ng',
    'nga': 'ng',
    'cameroon': 'cm',
    'cmr': 'cm',
    'ghana': 'gh',
    'gha': 'gh',
    'ivory coast': 'ci',
    'cote d\'ivoire': 'ci',
    'civ': 'ci',
    'algeria': 'dz',
    'alg': 'dz',
    'tunisia': 'tn',
    'tun': 'tn',
    'mexico': 'mx',
    'mex': 'mx',
    'switzerland': 'ch',
    'sui': 'ch',
    'denmark': 'dk',
    'den': 'dk',
    'sweden': 'se',
    'swe': 'se',
    'norway': 'no',
    'nor': 'no',
    'poland': 'pl',
    'pol': 'pl',
    'ukraine': 'ua',
    'ukr': 'ua',
    'turkey': 'tr',
    'tur': 'tr',
    'austria': 'at',
    'aut': 'at',
    'hungary': 'hu',
    'hun': 'hu',
    'romania': 'ro',
    'rou': 'ro',
    'slovakia': 'sk',
    'svk': 'sk',
    'czechia': 'cz',
    'czech republic': 'cz',
    'cze': 'cz',
    'georgia': 'ge',
    'geo': 'ge',
    'albania': 'al',
    'alb': 'al',
    'slovenia': 'si',
    'svn': 'si',
    'serbia': 'rs',
    'srb': 'rs',
    'greece': 'gr',
    'gre': 'gr',
    'finland': 'fi',
    'fin': 'fi',
    'iceland': 'is',
    'isl': 'is',
    'wales': 'gb-wls',
    'wal': 'gb-wls',
    'jamaica': 'jm',
    'jam': 'jm',
    'costa rica': 'cr',
    'crc': 'cr',
    'panama': 'pa',
    'pan': 'pa',
    'honduras': 'hn',
    'hon': 'hn',
    'el salvador': 'sv',
    'slv': 'sv',
    'iraq': 'iq',
    'irq': 'iq',
    'jordan': 'jo',
    'jor': 'jo',
    'uzbekistan': 'uz',
    'uzb': 'uz',
    'tajikistan': 'tj',
    'tjk': 'tj',
    'china': 'cn',
    'chn': 'cn',
    'vietnam': 'vn',
    'vie': 'vn',
    'thailand': 'th',
    'tha': 'th',
    'indonesia': 'id',
    'ina': 'id',
    'lebanon': 'lb',
    'lbn': 'lb',
    'palestine': 'ps',
    'ple': 'ps',
    'syria': 'sy',
    'syr': 'sy',
    'kyrgyzstan': 'kg',
    'kyrgyz republic': 'kg',
    'kgz': 'kg',
    'bahrain': 'bh',
    'bhr': 'bh',
    'mali': 'ml',
    'mli': 'ml',
    'burkina faso': 'bf',
    'bfa': 'bf',
    'guinea': 'gn',
    'gui': 'gn',
    'dr congo': 'cd',
    'cod': 'cd',
    'angola': 'ao',
    'ang': 'ao',
    'cape verde': 'cv',
    'cpv': 'cv',
    'mauritania': 'mr',
    'mtn': 'mr',
    'equatorial guinea': 'gq',
    'eqg': 'gq',
    'zambia': 'zm',
    'zam': 'zm',
  };

  // 1. Direct match
  if (countryCodeMap.containsKey(name)) {
    return 'https://flagcdn.com/w80/${countryCodeMap[name]}.png';
  }

  // 2. Word boundary match
  for (final entry in countryCodeMap.entries) {
    final regex = RegExp('\\b${RegExp.escape(entry.key)}\\b');
    if (regex.hasMatch(name)) {
      return 'https://flagcdn.com/w80/${entry.value}.png';
    }
  }

  return null;
}
