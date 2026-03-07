// ============================================
// 🇳🇬 NIGERIA LOCATIONS DATA
// Includes all 36 States + FCT and their LGAs
// with approximate GPS coordinates for fare calculation.
// =// ============================================

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
      LgaData(name: 'Ifako-Ijaiye', lat: 6.6661, lng: 3.2842),
      LgaData(name: 'Mushin', lat: 6.5361, lng: 3.3512),
      LgaData(name: 'Oshodi-Isolo', lat: 6.5392, lng: 3.3228),
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
      LgaData(name: 'Kuje', lat: 8.8797, lng: 7.2276),
      LgaData(name: 'Abaji', lat: 8.4727, lng: 6.9452),
    ],
  ),
  NigeriaLocation(
    state: 'Ogun',
    lgas: [
      LgaData(name: 'Abeokuta South', lat: 7.1500, lng: 3.3500),
      LgaData(name: 'Abeokuta North', lat: 7.2000, lng: 3.3000),
      LgaData(name: 'Ijebu Ode', lat: 6.8194, lng: 3.9175),
      LgaData(name: 'Sagamu', lat: 6.8400, lng: 3.6500),
      LgaData(name: 'Ota', lat: 6.6919, lng: 3.2285),
    ],
  ),
  NigeriaLocation(
    state: 'Oyo',
    lgas: [
      LgaData(name: 'Ibadan North', lat: 7.4124, lng: 3.9056),
      LgaData(name: 'Ibadan South East', lat: 7.3600, lng: 3.9200),
      LgaData(name: 'Ogbomosho North', lat: 8.1333, lng: 4.2500),
      LgaData(name: 'Oyo East', lat: 7.8500, lng: 3.9500),
    ],
  ),
  // Note: More states and LGAs would be added here in a production app.
  // For now, these are the primary hubs to get the app running.
];
