import 'regions.dart';
import 'landmarks.dart';

/// 국가별 여행 코스. 한국 코스는 regions.dart와 landmarks.dart의 목록을 그대로 씁니다.
class Course {
  final String id;
  final String country;
  final String routeName;
  final double totalKm;
  final List<Region> regions;
  final List<Landmark> landmarks;
  final bool freeUnlocked; // 처음부터 열려 있는 코스
  final String price; // 유료 해금 가격 (표시용)

  const Course({
    required this.id,
    required this.country,
    required this.routeName,
    required this.totalKm,
    required this.regions,
    required this.landmarks,
    this.freeUnlocked = false,
    this.price = '',
  });

  /// 아직 콘텐츠가 없는 코스 (목록에 "Coming soon"으로만 표시)
  bool get comingSoon => regions.isEmpty;
}

const List<Course> kCourses = [
  Course(
    id: 'korea',
    country: 'Korea',
    routeName: kRouteName,
    totalKm: kRouteTotalKm,
    regions: kRoute,
    landmarks: kLandmarks,
    freeUnlocked: true,
  ),
  Course(
    id: 'indonesia',
    country: 'Indonesia',
    routeName: 'Jakarta → Yogyakarta',
    totalKm: 560,
    regions: kIndonesiaRegions,
    landmarks: kIndonesiaLandmarks,
    price: '\$2.99',
  ),
  Course(
    id: 'thailand',
    country: 'Thailand',
    routeName: 'Bangkok → Chiang Mai',
    totalKm: 750,
    regions: kThailandRegions,
    landmarks: kThailandLandmarks,
    price: '\$2.99',
  ),
  Course(
    id: 'japan',
    country: 'Japan',
    routeName: 'Tokyo → Osaka',
    totalKm: 520,
    regions: kJapanRegions,
    landmarks: kJapanLandmarks,
    price: '\$2.99',
  ),
  Course(
    id: 'france',
    country: 'France',
    routeName: 'Paris → Nice',
    totalKm: 0,
    regions: [],
    landmarks: [],
  ),
];

// ---------- 일본 코스 (ID는 다른 나라와 겹치지 않게 jp_로 시작) ----------

const List<Region> kJapanRegions = [
  Region(id: 'jp_yokohama', name: 'Yokohama', item: 'Shumai Dumplings', km: 30),
  Region(id: 'jp_odawara', name: 'Odawara', item: 'Kamaboko Fish Cake', km: 80),
  Region(id: 'jp_shizuoka', name: 'Shizuoka', item: 'Shizuoka Green Tea', km: 180),
  Region(id: 'jp_hamamatsu', name: 'Hamamatsu', item: 'Grilled Eel', km: 250),
  Region(id: 'jp_nagoya', name: 'Nagoya', item: 'Miso Katsu', km: 350),
  Region(id: 'jp_kyoto', name: 'Kyoto', item: 'Yatsuhashi Sweets', km: 480),
  Region(id: 'jp_osaka', name: 'Osaka', item: 'Takoyaki', km: 520),
];

const List<Landmark> kJapanLandmarks = [
  Landmark(id: 'jp_fuji', name: 'Mount Fuji', km: 120),
  Landmark(id: 'jp_nagoya_castle', name: 'Nagoya Castle', km: 355),
  Landmark(id: 'jp_fushimi_inari', name: 'Fushimi Inari Shrine', km: 475),
  Landmark(id: 'jp_osaka_castle', name: 'Osaka Castle', km: 515),
];

// ---------- 인도네시아 코스 (자바섬 서쪽에서 동쪽으로, ID는 id_로 시작) ----------

const List<Region> kIndonesiaRegions = [
  Region(id: 'id_bogor', name: 'Bogor', item: 'Bogor Taro Cake', km: 60),
  Region(id: 'id_bandung', name: 'Bandung', item: 'Batagor', km: 150),
  Region(id: 'id_cirebon', name: 'Cirebon', item: 'Empal Gentong', km: 280),
  Region(id: 'id_purwokerto', name: 'Purwokerto', item: 'Tempeh Mendoan', km: 420),
  Region(id: 'id_yogyakarta', name: 'Yogyakarta', item: 'Gudeg', km: 560),
];

const List<Landmark> kIndonesiaLandmarks = [
  Landmark(id: 'id_bogor_garden', name: 'Bogor Botanical Gardens', km: 65),
  Landmark(id: 'id_tangkuban', name: 'Tangkuban Perahu Volcano', km: 160),
  Landmark(id: 'id_borobudur', name: 'Borobudur Temple', km: 530),
  Landmark(id: 'id_kraton', name: 'Kraton Yogyakarta', km: 555),
];

// ---------- 태국 코스 (방콕에서 북쪽으로, ID는 th_로 시작) ----------

const List<Region> kThailandRegions = [
  Region(id: 'th_ayutthaya', name: 'Ayutthaya', item: 'Roti Sai Mai', km: 80),
  Region(id: 'th_nakhon_sawan', name: 'Nakhon Sawan', item: 'Mooncakes', km: 240),
  Region(id: 'th_phitsanulok', name: 'Phitsanulok', item: 'Sun-dried Bananas', km: 380),
  Region(id: 'th_sukhothai', name: 'Sukhothai', item: 'Sukhothai Noodles', km: 440),
  Region(id: 'th_lampang', name: 'Lampang', item: 'Rooster Bowl', km: 650),
  Region(id: 'th_chiang_mai', name: 'Chiang Mai', item: 'Khao Soi', km: 750),
];

const List<Landmark> kThailandLandmarks = [
  Landmark(id: 'th_ayutthaya_park', name: 'Ayutthaya Historical Park', km: 85),
  Landmark(id: 'th_sukhothai_park', name: 'Sukhothai Historical Park', km: 445),
  Landmark(id: 'th_doi_suthep', name: 'Wat Phra That Doi Suthep', km: 745),
];