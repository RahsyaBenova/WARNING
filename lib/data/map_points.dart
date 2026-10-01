/// 지도 화면에서 루트를 그릴 때 쓰는 위치 (위도, 경도).
/// 코스 출발 도시는 코스 ID로, 지역은 지역 ID로 찾습니다.
/// 새 나라나 지역을 추가하면 여기에도 위치를 추가하세요. 없으면 지도에 "Map coming soon"이 표시됩니다.
const Map<String, (double, double)> kMapPoints = {
  // 한국 (출발: 서울)
  'korea': (37.57, 126.98),
  'suwon': (37.26, 127.03),
  'cheonan': (36.81, 127.11),
  'gongju': (36.45, 127.12),
  'yeongdong': (36.17, 127.78),
  'gimcheon': (36.14, 128.11),
  'daegu': (35.87, 128.60),
  'cheongdo': (35.65, 128.73),
  'busan': (35.18, 129.08),

  // 인도네시아 (출발: 자카르타)
  'indonesia': (-6.21, 106.85),
  'id_bogor': (-6.60, 106.80),
  'id_bandung': (-6.91, 107.61),
  'id_cirebon': (-6.73, 108.55),
  'id_purwokerto': (-7.42, 109.23),
  'id_yogyakarta': (-7.80, 110.36),

  // 태국 (출발: 방콕)
  'thailand': (13.76, 100.50),
  'th_ayutthaya': (14.35, 100.57),
  'th_nakhon_sawan': (15.70, 100.14),
  'th_phitsanulok': (16.82, 100.26),
  'th_sukhothai': (17.01, 99.82),
  'th_lampang': (18.29, 99.49),
  'th_chiang_mai': (18.79, 98.98),

  // 일본 (출발: 도쿄)
  'japan': (35.68, 139.69),
  'jp_yokohama': (35.44, 139.64),
  'jp_odawara': (35.26, 139.15),
  'jp_shizuoka': (34.98, 138.38),
  'jp_hamamatsu': (34.71, 137.73),
  'jp_nagoya': (35.18, 136.91),
  'jp_kyoto': (35.01, 135.77),
  'jp_osaka': (34.69, 135.50),
};