// ============================================
// 🇳🇬 NIGERIA LOCATIONS DATA
// Includes all 36 States + FCT and their LGAs
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
    ],
  ),
  NigeriaLocation(
    state: 'Abia',
    lgas: [
      LgaData(name: 'Aba South', lat: 5.1053, lng: 7.3508),
      LgaData(name: 'Umuahia North', lat: 5.5262, lng: 7.4898),
    ],
  ),
  NigeriaLocation(
    state: 'Adamawa',
    lgas: [
      LgaData(name: 'Yola North', lat: 9.2035, lng: 12.4850),
      LgaData(name: 'Mubi North', lat: 10.2676, lng: 13.2657),
    ],
  ),
  NigeriaLocation(
    state: 'Akwa Ibom',
    lgas: [
      LgaData(name: 'Uyo', lat: 5.0333, lng: 7.9266),
      LgaData(name: 'Eket', lat: 4.6393, lng: 7.9304),
    ],
  ),
  NigeriaLocation(
    state: 'Anambra',
    lgas: [
      LgaData(name: 'Awka South', lat: 6.2105, lng: 7.0665),
      LgaData(name: 'Onitsha North', lat: 6.1437, lng: 6.7833),
    ],
  ),
  NigeriaLocation(
    state: 'Bauchi',
    lgas: [
      LgaData(name: 'Bauchi', lat: 10.3103, lng: 9.8439),
      LgaData(name: 'Azare', lat: 11.6744, lng: 10.1914),
    ],
  ),
  NigeriaLocation(
    state: 'Bayelsa',
    lgas: [
      LgaData(name: 'Yenagoa', lat: 4.9267, lng: 6.2631),
    ],
  ),
  NigeriaLocation(
    state: 'Benue',
    lgas: [
      LgaData(name: 'Makurdi', lat: 7.7327, lng: 8.5214),
      LgaData(name: 'Otukpo', lat: 7.1925, lng: 8.1328),
    ],
  ),
  NigeriaLocation(
    state: 'Borno',
    lgas: [
      LgaData(name: 'Maiduguri', lat: 11.8333, lng: 13.1500),
    ],
  ),
  NigeriaLocation(
    state: 'Cross River',
    lgas: [
      LgaData(name: 'Calabar Municipal', lat: 4.9757, lng: 8.3417),
      LgaData(name: 'Akamkpa', lat: 5.3167, lng: 8.3333),
    ],
  ),
  NigeriaLocation(
    state: 'Delta',
    lgas: [
      LgaData(name: 'Asaba', lat: 6.2000, lng: 6.7333),
      LgaData(name: 'Warri South', lat: 5.5167, lng: 5.7500),
    ],
  ),
  NigeriaLocation(
    state: 'Ebonyi',
    lgas: [
      LgaData(name: 'Abakaliki', lat: 6.3236, lng: 8.1133),
    ],
  ),
  NigeriaLocation(
    state: 'Edo',
    lgas: [
      LgaData(name: 'Benin City (Oredo)', lat: 6.3350, lng: 5.6269),
      LgaData(name: 'Auchi', lat: 7.0667, lng: 6.2667),
    ],
  ),
  NigeriaLocation(
    state: 'Ekiti',
    lgas: [
      LgaData(name: 'Ado Ekiti', lat: 7.6233, lng: 5.2205),
    ],
  ),
  NigeriaLocation(
    state: 'Enugu',
    lgas: [
      LgaData(name: 'Enugu North', lat: 6.4413, lng: 7.4988),
      LgaData(name: 'Nsukka', lat: 6.8578, lng: 7.3958),
    ],
  ),
  NigeriaLocation(
    state: 'Gombe',
    lgas: [
      LgaData(name: 'Gombe', lat: 10.2833, lng: 11.1667),
    ],
  ),
  NigeriaLocation(
    state: 'Imo',
    lgas: [
      LgaData(name: 'Owerri Municipal', lat: 5.4850, lng: 7.0350),
    ],
  ),
  NigeriaLocation(
    state: 'Jigawa',
    lgas: [
      LgaData(name: 'Dutse', lat: 11.7000, lng: 9.3333),
    ],
  ),
  NigeriaLocation(
    state: 'Kaduna',
    lgas: [
      LgaData(name: 'Kaduna South', lat: 10.5105, lng: 7.4204),
      LgaData(name: 'Zaria', lat: 11.0667, lng: 7.7000),
    ],
  ),
  NigeriaLocation(
    state: 'Kano',
    lgas: [
      LgaData(name: 'Kano Municipal', lat: 11.9964, lng: 8.5167),
    ],
  ),
  NigeriaLocation(
    state: 'Katsina',
    lgas: [
      LgaData(name: 'Katsina', lat: 12.9894, lng: 7.6172),
    ],
  ),
  NigeriaLocation(
    state: 'Kebbi',
    lgas: [
      LgaData(name: 'Birnin Kebbi', lat: 12.4500, lng: 4.2000),
    ],
  ),
  NigeriaLocation(
    state: 'Kogi',
    lgas: [
      LgaData(name: 'Lokoja', lat: 7.8000, lng: 6.7333),
    ],
  ),
  NigeriaLocation(
    state: 'Kwara',
    lgas: [
      LgaData(name: 'Ilorin South', lat: 8.4799, lng: 4.5418),
    ],
  ),
  NigeriaLocation(
    state: 'Nasarawa',
    lgas: [
      LgaData(name: 'Lafia', lat: 8.4833, lng: 8.5167),
    ],
  ),
  NigeriaLocation(
    state: 'Niger',
    lgas: [
      LgaData(name: 'Minna', lat: 9.6139, lng: 6.5569),
      LgaData(name: 'Suleja', lat: 9.1806, lng: 7.1800),
    ],
  ),
  NigeriaLocation(
    state: 'Ogun',
    lgas: [
      LgaData(name: 'Abeokuta South', lat: 7.1500, lng: 3.3500),
      LgaData(name: 'Sagamu', lat: 6.8400, lng: 3.6500),
      LgaData(name: 'Ota', lat: 6.6919, lng: 3.2285),
    ],
  ),
  NigeriaLocation(
    state: 'Ondo',
    lgas: [
      LgaData(name: 'Akure South', lat: 7.2500, lng: 5.2000),
    ],
  ),
  NigeriaLocation(
    state: 'Osun',
    lgas: [
      LgaData(name: 'Osogbo', lat: 7.7710, lng: 4.5654),
      LgaData(name: 'Ife Central', lat: 7.4667, lng: 4.5667),
    ],
  ),
  NigeriaLocation(
    state: 'Oyo',
    lgas: [
      LgaData(name: 'Ibadan North', lat: 7.4124, lng: 3.9056),
      LgaData(name: 'Ogbomosho North', lat: 8.1333, lng: 4.2500),
    ],
  ),
  NigeriaLocation(
    state: 'Plateau',
    lgas: [
      LgaData(name: 'Jos North', lat: 9.9167, lng: 8.9000),
    ],
  ),
  NigeriaLocation(
    state: 'Rivers',
    lgas: [
      LgaData(name: 'Port Harcourt', lat: 4.7500, lng: 7.0000),
      LgaData(name: 'Obio-Akpor', lat: 4.8417, lng: 6.9667),
    ],
  ),
  NigeriaLocation(
    state: 'Sokoto',
    lgas: [
      LgaData(name: 'Sokoto South', lat: 13.0622, lng: 5.2339),
    ],
  ),
  NigeriaLocation(
    state: 'Taraba',
    lgas: [
      LgaData(name: 'Jalingo', lat: 8.8917, lng: 11.3667),
    ],
  ),
  NigeriaLocation(
    state: 'Yobe',
    lgas: [
      LgaData(name: 'Damaturu', lat: 11.7470, lng: 11.9610),
    ],
  ),
  NigeriaLocation(
    state: 'Zamfara',
    lgas: [
      LgaData(name: 'Gusau', lat: 12.1628, lng: 6.6614),
    ],
  ),
];
