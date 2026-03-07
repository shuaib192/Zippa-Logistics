// ============================================
// 🇳🇬 NIGERIA LOCATIONS DATA
// Includes all 36 States + FCT and their major LGAs
// with approximate GPS coordinates for fare calculation.
// ============================================

class NigeriaLocation {
  final String state;
  final List<LgaData> lgas;

  const NigeriaLocation({required this.state, required this.lgas});
}

class LgaData {
  final String name;
  final double lat;
  final double lng;

  const LgaData({required this.name, required this.lat, required this.lng});
}

const List<NigeriaLocation> nigeriaStates = [
  NigeriaLocation(
    state: 'Lagos',
    lgas: [
      LgaData(name: 'Ikeja', lat: 6.6010, lng: 3.3515),
      LgaData(name: 'Lagos Island', lat: 6.4485, lng: 3.4013),
      LgaData(name: 'Ikorodu', lat: 6.6194, lng: 3.5105),
      LgaData(name: 'Epe', lat: 6.5841, lng: 3.9841),
      LgaData(name: 'Badagry', lat: 6.4158, lng: 2.8831),
      LgaData(name: 'Alimosho', lat: 6.6014, lng: 3.2435),
      LgaData(name: 'Agege', lat: 6.6180, lng: 3.3209),
      LgaData(name: 'Apapa', lat: 6.4447, lng: 3.3575),
      LgaData(name: 'Surulere', lat: 6.5059, lng: 3.3619),
      LgaData(name: 'Oshodi-Isolo', lat: 6.5392, lng: 3.3228),
      LgaData(name: 'Mushin', lat: 6.5361, lng: 3.3512),
      LgaData(name: 'Lagos Mainland', lat: 6.5053, lng: 3.3769),
      LgaData(name: 'Eti-Osa', lat: 6.4522, lng: 3.4868),
      LgaData(name: 'Amuwo-Odofin', lat: 6.4561, lng: 3.2755),
    ],
  ),
  NigeriaLocation(
    state: 'Abuja (FCT)',
    lgas: [
      LgaData(name: 'Garki', lat: 9.0347, lng: 7.4851),
      LgaData(name: 'Wuse', lat: 9.0667, lng: 7.4667),
      LgaData(name: 'Maitama', lat: 9.0833, lng: 7.5000),
      LgaData(name: 'Asokoro', lat: 9.0436, lng: 7.5192),
      LgaData(name: 'Gwagwalada', lat: 8.9482, lng: 7.0761),
      LgaData(name: 'Kuje', lat: 8.8797, lng: 7.2276),
      LgaData(name: 'Abaji', lat: 8.4727, lng: 6.9452),
      LgaData(name: 'Bwari', lat: 9.2882, lng: 7.3712),
      LgaData(name: 'Kwali', lat: 8.8722, lng: 7.0092),
      LgaData(name: 'AMAC', lat: 9.0561, lng: 7.4985),
    ],
  ),
  NigeriaLocation(
    state: 'Abia',
    lgas: [
      LgaData(name: 'Aba South', lat: 5.1053, lng: 7.3508),
      LgaData(name: 'Aba North', lat: 5.1220, lng: 7.3620),
      LgaData(name: 'Umuahia North', lat: 5.5262, lng: 7.4898),
      LgaData(name: 'Umuahia South', lat: 5.4667, lng: 7.4667),
      LgaData(name: 'Ohafia', lat: 5.6178, lng: 7.8286),
      LgaData(name: 'Arochukwu', lat: 5.3853, lng: 7.9103),
      LgaData(name: 'Bende', lat: 5.5562, lng: 7.6366),
    ],
  ),
  NigeriaLocation(
    state: 'Adamawa',
    lgas: [
      LgaData(name: 'Yola North', lat: 9.2035, lng: 12.4850),
      LgaData(name: 'Yola South', lat: 9.1834, lng: 12.4646),
      LgaData(name: 'Mubi North', lat: 10.2676, lng: 13.2657),
      LgaData(name: 'Mubi South', lat: 10.1803, lng: 13.2306),
      LgaData(name: 'Gombi', lat: 10.1667, lng: 12.7333),
      LgaData(name: 'Numon', lat: 9.4503, lng: 12.0303),
    ],
  ),
  NigeriaLocation(
    state: 'Akwa Ibom',
    lgas: [
      LgaData(name: 'Uyo', lat: 5.0333, lng: 7.9266),
      LgaData(name: 'Eket', lat: 4.6393, lng: 7.9304),
      LgaData(name: 'Ikot Ekpene', lat: 5.1818, lng: 7.7148),
      LgaData(name: 'Oron', lat: 4.8333, lng: 8.2333),
      LgaData(name: 'Ikot Abasi', lat: 4.5667, lng: 7.5500),
      LgaData(name: 'Itu', lat: 5.1667, lng: 7.9833),
    ],
  ),
  NigeriaLocation(
    state: 'Anambra',
    lgas: [
      LgaData(name: 'Awka South', lat: 6.2105, lng: 7.0665),
      LgaData(name: 'Awka North', lat: 6.2800, lng: 7.0300),
      LgaData(name: 'Onitsha North', lat: 6.1437, lng: 6.7833),
      LgaData(name: 'Onitsha South', lat: 6.1333, lng: 6.7767),
      LgaData(name: 'Nnewi North', lat: 6.0152, lng: 6.9167),
      LgaData(name: 'Nnewi South', lat: 5.8833, lng: 6.9500),
      LgaData(name: 'Idemili North', lat: 6.1167, lng: 6.8500),
      LgaData(name: 'Idemili South', lat: 6.0500, lng: 6.8333),
    ],
  ),
  NigeriaLocation(
    state: 'Bauchi',
    lgas: [
      LgaData(name: 'Bauchi', lat: 10.3103, lng: 9.8439),
      LgaData(name: 'Azare', lat: 11.6744, lng: 10.1914),
      LgaData(name: 'Misau', lat: 11.3167, lng: 10.4667),
      LgaData(name: 'Katagum', lat: 11.6833, lng: 10.2333),
      LgaData(name: 'Jama\'are', lat: 11.6667, lng: 9.9333),
    ],
  ),
  NigeriaLocation(
    state: 'Bayelsa',
    lgas: [
      LgaData(name: 'Yenagoa', lat: 4.9267, lng: 6.2631),
      LgaData(name: 'Brass', lat: 4.3167, lng: 6.2333),
      LgaData(name: 'Ogbia', lat: 4.6500, lng: 6.3333),
      LgaData(name: 'Sagbama', lat: 5.1500, lng: 6.2167),
      LgaData(name: 'Southern Ijaw', lat: 4.8167, lng: 6.0833),
      LgaData(name: 'Ekeremor', lat: 5.0500, lng: 5.8333),
    ],
  ),
  NigeriaLocation(
    state: 'Benue',
    lgas: [
      LgaData(name: 'Makurdi', lat: 7.7327, lng: 8.5214),
      LgaData(name: 'Otukpo', lat: 7.1925, lng: 8.1328),
      LgaData(name: 'Gboko', lat: 7.3167, lng: 9.0000),
      LgaData(name: 'Katsina-Ala', lat: 7.1667, lng: 9.2833),
      LgaData(name: 'Adoka', lat: 7.1264, lng: 7.9142),
    ],
  ),
  NigeriaLocation(
    state: 'Borno',
    lgas: [
      LgaData(name: 'Maiduguri', lat: 11.8333, lng: 13.1500),
      LgaData(name: 'Biu', lat: 10.6122, lng: 12.1947),
      LgaData(name: 'Bama', lat: 11.5167, lng: 13.6833),
      LgaData(name: 'Monguno', lat: 12.6667, lng: 13.6167),
      LgaData(name: 'Konduga', lat: 11.6500, lng: 13.4167),
    ],
  ),
  NigeriaLocation(
    state: 'Cross River',
    lgas: [
      LgaData(name: 'Calabar Municipal', lat: 4.9757, lng: 8.3417),
      LgaData(name: 'Calabar South', lat: 4.9500, lng: 8.3300),
      LgaData(name: 'Akamkpa', lat: 5.3167, lng: 8.3333),
      LgaData(name: 'Ogoja', lat: 6.6558, lng: 8.7981),
      LgaData(name: 'Ikom', lat: 5.9667, lng: 8.7167),
      LgaData(name: 'Obudu', lat: 6.6667, lng: 9.1667),
      LgaData(name: 'Ugep', lat: 5.8167, lng: 8.0833),
    ],
  ),
  NigeriaLocation(
    state: 'Delta',
    lgas: [
      LgaData(name: 'Asaba', lat: 6.2000, lng: 6.7333),
      LgaData(name: 'Warri South', lat: 5.5167, lng: 5.7500),
      LgaData(name: 'Warri North', lat: 5.9833, lng: 5.4333),
      LgaData(name: 'Ughelli North', lat: 5.4833, lng: 5.9833),
      LgaData(name: 'Ughelli South', lat: 5.4000, lng: 5.9000),
      LgaData(name: 'Sapele', lat: 5.8833, lng: 5.6833),
      LgaData(name: 'Agbor', lat: 6.2500, lng: 6.2000),
      LgaData(name: 'Aniocha North', lat: 6.3667, lng: 6.5167),
    ],
  ),
  NigeriaLocation(
    state: 'Ebonyi',
    lgas: [
      LgaData(name: 'Abakaliki', lat: 6.3236, lng: 8.1133),
      LgaData(name: 'Afikpo North', lat: 5.8911, lng: 7.9374),
      LgaData(name: 'Afikpo South', lat: 5.8000, lng: 7.8500),
      LgaData(name: 'Onueke', lat: 6.1333, lng: 8.0833),
      LgaData(name: 'Ishielu', lat: 6.4167, lng: 7.8333),
    ],
  ),
  NigeriaLocation(
    state: 'Edo',
    lgas: [
      LgaData(name: 'Benin City (Oredo)', lat: 6.3350, lng: 5.6269),
      LgaData(name: 'Ikpoba-Okha', lat: 6.3167, lng: 5.7167),
      LgaData(name: 'Egor', lat: 6.3667, lng: 5.5833),
      LgaData(name: 'Auchi (Etsako West)', lat: 7.0667, lng: 6.2667),
      LgaData(name: 'Ekpoma (Esan West)', lat: 6.7414, lng: 6.1367),
      LgaData(name: 'Uromi (Esan North-East)', lat: 6.7000, lng: 6.3333),
      LgaData(name: 'Okada (Ovia North-East)', lat: 6.5167, lng: 5.3833),
    ],
  ),
  NigeriaLocation(
    state: 'Ekiti',
    lgas: [
      LgaData(name: 'Ado Ekiti', lat: 7.6233, lng: 5.2205),
      LgaData(name: 'Ikere', lat: 7.4981, lng: 5.2311),
      LgaData(name: 'Oye', lat: 7.7981, lng: 5.3333),
      LgaData(name: 'Ikole', lat: 7.8000, lng: 5.5167),
      LgaData(name: 'Ido-Osi', lat: 7.8222, lng: 5.1834),
    ],
  ),
  NigeriaLocation(
    state: 'Enugu',
    lgas: [
      LgaData(name: 'Enugu North', lat: 6.4413, lng: 7.4988),
      LgaData(name: 'Enugu South', lat: 6.3833, lng: 7.5000),
      LgaData(name: 'Enugu East', lat: 6.4833, lng: 7.5500),
      LgaData(name: 'Nsukka', lat: 6.8578, lng: 7.3958),
      LgaData(name: 'Udi', lat: 6.3167, lng: 7.4333),
      LgaData(name: 'Awgu', lat: 6.0667, lng: 7.4833),
      LgaData(name: 'Oji River', lat: 6.2667, lng: 7.2667),
    ],
  ),
  NigeriaLocation(
    state: 'Gombe',
    lgas: [
      LgaData(name: 'Gombe', lat: 10.2833, lng: 11.1667),
      LgaData(name: 'Kaltungo', lat: 9.8167, lng: 11.3000),
      LgaData(name: 'Billiri', lat: 9.8667, lng: 11.2167),
      LgaData(name: 'Dukku', lat: 10.8167, lng: 10.7667),
      LgaData(name: 'Yamaltu Deba', lat: 10.2167, lng: 11.3833),
    ],
  ),
  NigeriaLocation(
    state: 'Imo',
    lgas: [
      LgaData(name: 'Owerri Municipal', lat: 5.4850, lng: 7.0350),
      LgaData(name: 'Owerri North', lat: 5.5333, lng: 7.0833),
      LgaData(name: 'Owerri West', lat: 5.4333, lng: 6.9667),
      LgaData(name: 'Orlu', lat: 5.7958, lng: 7.0400),
      LgaData(name: 'Okigwe', lat: 5.8333, lng: 7.3333),
      LgaData(name: 'Mbaise', lat: 5.4833, lng: 7.2167),
      LgaData(name: 'Oguta', lat: 5.7167, lng: 6.8167),
    ],
  ),
  NigeriaLocation(
    state: 'Jigawa',
    lgas: [
      LgaData(name: 'Dutse', lat: 11.7000, lng: 9.3333),
      LgaData(name: 'Hadejia', lat: 12.4500, lng: 10.0333),
      LgaData(name: 'Gumel', lat: 12.6333, lng: 9.3833),
      LgaData(name: 'Ringim', lat: 12.1500, lng: 9.1667),
      LgaData(name: 'Birnin Kudu', lat: 11.4500, lng: 9.4833),
    ],
  ),
  NigeriaLocation(
    state: 'Kaduna',
    lgas: [
      LgaData(name: 'Kaduna South', lat: 10.5105, lng: 7.4204),
      LgaData(name: 'Kaduna North', lat: 10.5333, lng: 7.4500),
      LgaData(name: 'Zaria', lat: 11.0667, lng: 7.7000),
      LgaData(name: 'Sabon Gari', lat: 11.0833, lng: 7.7333),
      LgaData(name: 'Kafanchan (Jema\'a)', lat: 9.5833, lng: 8.2833),
      LgaData(name: 'Chikun', lat: 10.4500, lng: 7.3167),
      LgaData(name: 'Birnin Gwari', lat: 10.6667, lng: 6.7500),
    ],
  ),
  NigeriaLocation(
    state: 'Kano',
    lgas: [
      LgaData(name: 'Kano Municipal', lat: 11.9964, lng: 8.5167),
      LgaData(name: 'Dala', lat: 12.0167, lng: 8.5000),
      LgaData(name: 'Fagge', lat: 12.0333, lng: 8.5333),
      LgaData(name: 'Gwale', lat: 11.9833, lng: 8.4833),
      LgaData(name: 'Tarauni', lat: 11.9667, lng: 8.5533),
      LgaData(name: 'Nassarawa', lat: 12.0000, lng: 8.5500),
      LgaData(name: 'Wudil', lat: 11.8081, lng: 8.8419),
    ],
  ),
  NigeriaLocation(
    state: 'Katsina',
    lgas: [
      LgaData(name: 'Katsina', lat: 12.9894, lng: 7.6172),
      LgaData(name: 'Daura', lat: 13.0333, lng: 8.3167),
      LgaData(name: 'Funtua', lat: 11.5167, lng: 7.3167),
      LgaData(name: 'Malumfashi', lat: 11.7833, lng: 7.6167),
      LgaData(name: 'Zango', lat: 13.0500, lng: 8.5667),
    ],
  ),
  NigeriaLocation(
    state: 'Kebbi',
    lgas: [
      LgaData(name: 'Birnin Kebbi', lat: 12.4500, lng: 4.2000),
      LgaData(name: 'Argungu', lat: 12.7500, lng: 4.5333),
      LgaData(name: 'Yauri', lat: 10.7833, lng: 4.8167),
      LgaData(name: 'Zuru', lat: 11.4167, lng: 5.2333),
      LgaData(name: 'Jega', lat: 12.2167, lng: 4.3833),
    ],
  ),
  NigeriaLocation(
    state: 'Kogi',
    lgas: [
      LgaData(name: 'Lokoja', lat: 7.8000, lng: 6.7333),
      LgaData(name: 'Okene', lat: 7.5500, lng: 6.2333),
      LgaData(name: 'Idah', lat: 7.1167, lng: 6.7333),
      LgaData(name: 'Anyigba (Dekina)', lat: 7.4833, lng: 7.1667),
      LgaData(name: 'Kabba', lat: 7.8333, lng: 6.0667),
      LgaData(name: 'Ankpa', lat: 7.3833, lng: 7.6333),
    ],
  ),
  NigeriaLocation(
    state: 'Kwara',
    lgas: [
      LgaData(name: 'Ilorin South', lat: 8.4799, lng: 4.5418),
      LgaData(name: 'Ilorin West', lat: 8.4833, lng: 4.5167),
      LgaData(name: 'Ilorin East', lat: 8.5000, lng: 4.6000),
      LgaData(name: 'Offa', lat: 8.1491, lng: 4.7186),
      LgaData(name: 'Oro (Irepodun)', lat: 8.2167, lng: 4.8500),
      LgaData(name: 'Omu-Aran', lat: 8.1333, lng: 5.1000),
    ],
  ),
  NigeriaLocation(
    state: 'Nasarawa',
    lgas: [
      LgaData(name: 'Lafia', lat: 8.4833, lng: 8.5167),
      LgaData(name: 'Keffi', lat: 8.8476, lng: 7.8731),
      LgaData(name: 'Akwanga', lat: 8.9167, lng: 8.4000),
      LgaData(name: 'Nasarawa', lat: 8.5333, lng: 7.7000),
      LgaData(name: 'Karu', lat: 8.9833, lng: 7.6000),
    ],
  ),
  NigeriaLocation(
    state: 'Niger',
    lgas: [
      LgaData(name: 'Minna (Chanchaga)', lat: 9.6139, lng: 6.5569),
      LgaData(name: 'Bida', lat: 9.0833, lng: 6.0167),
      LgaData(name: 'Suleja', lat: 9.1806, lng: 7.1800),
      LgaData(name: 'Kontagora', lat: 10.4000, lng: 5.4667),
      LgaData(name: 'Lapai', lat: 9.0500, lng: 6.5667),
    ],
  ),
  NigeriaLocation(
    state: 'Ogun',
    lgas: [
      LgaData(name: 'Abeokuta South', lat: 7.1500, lng: 3.3500),
      LgaData(name: 'Abeokuta North', lat: 7.2000, lng: 3.3000),
      LgaData(name: 'Sagamu', lat: 6.8400, lng: 3.6500),
      LgaData(name: 'Ota (Ado-Odo)', lat: 6.6919, lng: 3.2285),
      LgaData(name: 'Ijebu Ode', lat: 6.8194, lng: 3.9175),
      LgaData(name: 'Ilaro (Yewa South)', lat: 6.8833, lng: 3.0000),
      LgaData(name: 'Ifo', lat: 6.8167, lng: 3.2000),
    ],
  ),
  NigeriaLocation(
    state: 'Ondo',
    lgas: [
      LgaData(name: 'Akure South', lat: 7.2500, lng: 5.2000),
      LgaData(name: 'Akure North', lat: 7.3000, lng: 5.2167),
      LgaData(name: 'Ondo West', lat: 7.1000, lng: 4.8333),
      LgaData(name: 'Owo', lat: 7.2000, lng: 5.5833),
      LgaData(name: 'Okitipupa', lat: 6.5000, lng: 4.7833),
      LgaData(name: 'Ore (Odigbo)', lat: 6.7500, lng: 4.8833),
    ],
  ),
  NigeriaLocation(
    state: 'Osun',
    lgas: [
      LgaData(name: 'Osogbo', lat: 7.7710, lng: 4.5654),
      LgaData(name: 'Ife Central', lat: 7.4667, lng: 4.5667),
      LgaData(name: 'Ife East', lat: 7.4833, lng: 4.6000),
      LgaData(name: 'Ilesa East', lat: 7.6333, lng: 4.7500),
      LgaData(name: 'Ilesa West', lat: 7.6167, lng: 4.7333),
      LgaData(name: 'Ede North', lat: 7.7333, lng: 4.4333),
      LgaData(name: 'Iwo', lat: 7.6333, lng: 4.1833),
    ],
  ),
  NigeriaLocation(
    state: 'Oyo',
    lgas: [
      LgaData(name: 'Ibadan North', lat: 7.4124, lng: 3.9056),
      LgaData(name: 'Ibadan North East', lat: 7.3833, lng: 3.9333),
      LgaData(name: 'Ibadan South East', lat: 7.3600, lng: 3.9200),
      LgaData(name: 'Ogbomosho North', lat: 8.1333, lng: 4.2500),
      LgaData(name: 'Ogbomosho South', lat: 8.1167, lng: 4.2667),
      LgaData(name: 'Oyo East', lat: 7.8500, lng: 3.9500),
      LgaData(name: 'Iseyin', lat: 7.9667, lng: 3.6000),
      LgaData(name: 'Saki West', lat: 8.6667, lng: 3.3833),
    ],
  ),
  NigeriaLocation(
    state: 'Plateau',
    lgas: [
      LgaData(name: 'Jos North', lat: 9.9167, lng: 8.9000),
      LgaData(name: 'Jos South', lat: 9.7500, lng: 8.8500),
      LgaData(name: 'Jos East', lat: 9.9333, lng: 9.1000),
      LgaData(name: 'Pankshin', lat: 9.3333, lng: 9.4500),
      LgaData(name: 'Bukuru', lat: 9.7833, lng: 8.8667),
    ],
  ),
  NigeriaLocation(
    state: 'Rivers',
    lgas: [
      LgaData(name: 'Port Harcourt', lat: 4.7500, lng: 7.0000),
      LgaData(name: 'Obio-Akpor', lat: 4.8417, lng: 6.9667),
      LgaData(name: 'Bonny', lat: 4.4500, lng: 7.1667),
      LgaData(name: 'Eleme', lat: 4.7833, lng: 7.1167),
      LgaData(name: 'Oyigbo', lat: 4.8833, lng: 7.2167),
      LgaData(name: 'Ahoada East', lat: 5.0833, lng: 6.6500),
      LgaData(name: 'Omoku (ONELGA)', lat: 5.3333, lng: 6.6500),
    ],
  ),
  NigeriaLocation(
    state: 'Sokoto',
    lgas: [
      LgaData(name: 'Sokoto South', lat: 13.0622, lng: 5.2339),
      LgaData(name: 'Sokoto North', lat: 13.0800, lng: 5.2500),
      LgaData(name: 'Gwadabawa', lat: 13.3500, lng: 5.2500),
      LgaData(name: 'Bodinga', lat: 12.8667, lng: 5.1167),
    ],
  ),
  NigeriaLocation(
    state: 'Taraba',
    lgas: [
      LgaData(name: 'Jalingo', lat: 8.8917, lng: 11.3667),
      LgaData(name: 'Wukari', lat: 7.8500, lng: 9.7833),
      LgaData(name: 'Bali', lat: 7.8167, lng: 10.9667),
      LgaData(name: 'Gembu (Sardauna)', lat: 6.7167, lng: 11.2500),
    ],
  ),
  NigeriaLocation(
    state: 'Yobe',
    lgas: [
      LgaData(name: 'Damaturu', lat: 11.7470, lng: 11.9610),
      LgaData(name: 'Potiskum', lat: 11.7100, lng: 11.0800),
      LgaData(name: 'Gashua', lat: 12.8667, lng: 11.0333),
      LgaData(name: 'Geidam', lat: 12.9000, lng: 11.9333),
    ],
  ),
  NigeriaLocation(
    state: 'Zamfara',
    lgas: [
      LgaData(name: 'Gusau', lat: 12.1628, lng: 6.6614),
      LgaData(name: 'Kaura Namoda', lat: 12.5898, lng: 6.5869),
      LgaData(name: 'Tsafe', lat: 11.9500, lng: 6.9167),
      LgaData(name: 'Talata Mafara', lat: 12.1167, lng: 6.0667),
      LgaData(name: 'Maru', lat: 12.3333, lng: 6.4000),
    ],
  ),
];
