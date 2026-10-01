import 'package:flutter/foundation.dart';
import 'data/courses.dart';
import 'data/regions.dart';
import 'data/landmarks.dart';
import 'data/outfits.dart';
import 'data/missions.dart';
import 'services/notification_service.dart';

/// 한 걸음 길이(km)와 거리 배율. 배율을 바꾸면 여행 속도가 바뀝니다.
const double kStepLengthKm = 0.0007; // 약 70cm
const double kVirtualScale = 10.0; // 현실 1km = 가상 10km

/// 하루에 볼 수 있는 보상형 광고 횟수 (2배 전진 + 랜드마크 되찾기 합산)
const int kMaxAdsPerDay = 5;

/// 광고로 국가를 해금할 때 필요한 시청 횟수 (하루 광고 제한과 별도로 셈)
const int kUnlockAdsRequired = 20;

/// 산책 결과 화면용 환산값 (대략적인 평균값, 기획에 맞게 조정 가능)
const double kCo2KgPerKm = 0.17; // 같은 거리를 승용차로 갔다면 나왔을 탄소
const double kKcalPerStep = 0.04; // 1,000보에 약 40kcal

/// 해커톤 시연용: 달력에 지난 날짜의 걷기 기록 예시를 채워 넣음 (실제 출시 땐 false)
const bool kSeedDemoHistory = true;

/// 날짜를 기록용 문자열로 (예: 2026-10-01)
String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 게임 진행 상태: 걸음 수, 세션, 국가별 진행 거리, 컬렉션, 광고, 해금, 날짜별 기록.
class GameState extends ChangeNotifier {
  GameState() {
    if (kSeedDemoHistory) _seedDemoHistory();
  }

  // ---------- 플레이어 이름 ----------

  String playerName = 'Traveler';

  /// 이름 변경 (앞뒤 공백 제거, 빈 이름은 무시, 최대 20자)
  void setPlayerName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    playerName = trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed;
    notifyListeners();
  }

  // ---------- 날짜별 걷기 기록 (내 정보 탭의 달력용) ----------

  final Map<String, int> dailySteps = {}; // 날짜 → 그날 실제로 걸은 걸음 (광고 보너스 제외)

  int stepsOn(DateTime d) => dailySteps[dayKey(d)] ?? 0;

  void _seedDemoHistory() {
    final now = DateTime.now();
    for (var i = 1; i <= 40; i++) {
      if (i % 4 == 0) continue; // 가끔 쉬는 날
      final d = now.subtract(Duration(days: i));
      dailySteps[dayKey(d)] = 3000 + (i * 1237) % 7000;
    }
  }

  // ---------- 전체 콜렉션 진행률 ----------

  int get collectionTotal {
    var n = kOutfits.length + kMissions.length;
    for (final c in kCourses) {
      if (!c.comingSoon) n += c.regions.length + c.landmarks.length;
    }
    return n;
  }

  int get collectionOwned =>
      collectedIds.length + landmarkIds.length + outfitIds.length + missionPhotos.length;

  int totalSteps = 0; // 실제로 걸은 걸음 (나중에 랭킹은 이 값만 사용)
  int bonusSteps = 0; // 광고로 얻은 추가 전진 (실제 걸음과 분리해서 기록)
  int sessionSteps = 0;
  bool isWalking = false;
  bool bonusClaimed = false; // 이번 산책에서 2배 보너스를 이미 받았는지

  // ---------- 이번 산책 기록 (결과 화면용) ----------

  final List<Region> sessionRegions = []; // 이번 산책에서 도착한 지역
  final List<Landmark> sessionLandmarks = []; // 이번 산책에서 얻은 랜드마크
  final List<Outfit> sessionOutfits = []; // 이번 산책에서 받은 의상
  double _sessionStartKm = 0;

  double get sessionRealKm => sessionSteps * kStepLengthKm; // 실제로 걸은 거리
  double get sessionVirtualKm => traveledKm - _sessionStartKm; // 가상 여행 전진 거리
  double get sessionCo2Kg => sessionRealKm * kCo2KgPerKm;
  double get sessionKcal => sessionSteps * kKcalPerStep;
  double get totalCo2Kg => totalSteps * kStepLengthKm * kCo2KgPerKm;
  final Set<String> collectedIds = {}; // 획득한 지역 특산물 (모든 나라 공통)
  final Set<String> landmarkIds = {}; // 획득한 랜드마크 스페셜 (모든 나라 공통)

  // ---------- 사진 미션 ----------

  final Map<String, Uint8List> missionPhotos = {}; // 미션 ID → 찍은 사진

  bool isMissionDone(Mission m) => missionPhotos.containsKey(m.id);

  final List<String> _todayMissionIds = []; // 오늘 받은 미션 (무료 + 광고 추가분)
  String _missionDay = '';

  /// 날짜가 바뀌었으면 오늘의 무료 미션을 새로 뽑음
  void _refreshMissionDay() {
    if (_missionDay == _today) return;
    _missionDay = _today;
    _todayMissionIds.clear();
    for (var i = 0; i < kFreeMissionsPerDay; i++) {
      final m = _nextNewMission();
      if (m != null) _todayMissionIds.add(m.id);
    }
  }

  /// 아직 못 찾았고 오늘 목록에도 없는 다음 미션 (날짜마다 시작점이 달라짐)
  Mission? _nextNewMission() {
    final day = DateTime.now().difference(DateTime(2026)).inDays;
    final start = day % kMissions.length;
    for (var i = 0; i < kMissions.length; i++) {
      final m = kMissions[(start + i) % kMissions.length];
      if (!isMissionDone(m) && !_todayMissionIds.contains(m.id)) return m;
    }
    return null;
  }

  /// 오늘의 미션 목록 (무료 1개 + 광고로 추가한 미션)
  List<Mission> get todayMissions {
    _refreshMissionDay();
    return [
      for (final id in _todayMissionIds) kMissions.firstWhere((m) => m.id == id),
    ];
  }

  int get bonusMissionsLeft {
    _refreshMissionDay();
    final used = _todayMissionIds.length - kFreeMissionsPerDay;
    return kMaxBonusMissionsPerDay - (used < 0 ? 0 : used);
  }

  /// 아직 못 찾은 미션이 남아 있는지
  bool get hasNewMissions => _nextNewMission() != null;

  /// 오늘 미션을 모두 끝냈고, 추가 횟수와 새 미션이 남아 있을 때만 광고로 추가 가능
  bool get canAddBonusMission =>
      todayMissions.every(isMissionDone) && bonusMissionsLeft > 0 && hasNewMissions;

  /// 광고 시청 완료 후 호출: 새 미션 하나를 오늘 목록에 추가
  bool addBonusMission() {
    if (!canAddBonusMission) return false;
    final m = _nextNewMission();
    if (m == null) return false;
    _todayMissionIds.add(m.id);
    notifyListeners();
    return true;
  }

  void completeMission(Mission m, Uint8List photo) {
    missionPhotos[m.id] = photo;
    notifyListeners();
  }

  // ---------- 캐릭터 의상 ----------

  final Set<String> outfitIds = {
    for (final o in kOutfits)
      if (o.courseId == null) o.id,
  };
  String currentOutfitId = kOutfits.first.id;
  Outfit? _pendingOutfit; // 방금 받은 의상 (보상 팝업용)

  Outfit get outfit => kOutfits.firstWhere((o) => o.id == currentOutfitId);
  bool ownsOutfit(Outfit o) => outfitIds.contains(o.id);

  void equipOutfit(Outfit o) {
    if (!ownsOutfit(o)) return;
    currentOutfitId = o.id;
    notifyListeners();
  }

  /// 방금 받은 의상을 한 번만 꺼내옴 (없으면 null)
  Outfit? takeOutfitReward() {
    final o = _pendingOutfit;
    _pendingOutfit = null;
    return o;
  }

  /// 지금 코스를 완주했으면 그 나라의 전통 의상을 지급
  void _grantCourseOutfit() {
    if (!isCourseComplete) return;
    for (final o in kOutfits) {
      if (o.courseId == currentCourseId && outfitIds.add(o.id)) {
        _pendingOutfit = o;
        sessionOutfits.add(o);
      }
    }
  }

  // ---------- 국가(코스) ----------

  String currentCourseId = kCourses.first.id;
  final Set<String> unlockedCourses = {
    for (final c in kCourses)
      if (c.freeUnlocked) c.id,
  };
  final Map<String, double> _kmByCourse = {}; // 나라별 진행 거리
  final Map<String, int> _unlockAds = {}; // 나라별 해금 광고 시청 횟수
  final Map<String, int> _completedCount = {}; // 나라별 완주 횟수

  int timesCompleted(Course c) => _completedCount[c.id] ?? 0;

  Course get course => kCourses.firstWhere((c) => c.id == currentCourseId);
  double kmFor(Course c) => _kmByCourse[c.id] ?? 0;
  double get traveledKm => kmFor(course);
  bool get isCourseComplete => traveledKm >= course.totalKm;
  bool isUnlocked(Course c) => unlockedCourses.contains(c.id);
  int unlockAdsWatched(Course c) => _unlockAds[c.id] ?? 0;

  /// 지금 코스에서 걸음만큼 전진 (코스 끝을 넘어가지 않음). 끝에 닿으면 완주 횟수 +1
  void _advance(int steps) {
    final before = traveledKm;
    final km = before + steps * kStepLengthKm * kVirtualScale;
    final after = km > course.totalKm ? course.totalKm : km;
    _kmByCourse[currentCourseId] = after;
    if (before < course.totalKm && after >= course.totalKm) {
      _completedCount[currentCourseId] = timesCompleted(course) + 1;
    }
  }

  /// 완주한 나라를 처음부터 다시 여행. 특산물은 다시 주지 않고,
  /// 놓쳤던 랜드마크는 다시 지나갈 때 획득 기회가 생김
  bool restartCourse() {
    if (isWalking || !isCourseComplete) return false;
    _kmByCourse[currentCourseId] = 0;
    _alertedLandmarks.removeAll(course.landmarks.map((l) => l.id)); // 알림도 다시 받도록
    notifyListeners();
    return true;
  }

  /// 해금된 다른 나라로 이동. 산책 중에는 바꿀 수 없음
  bool selectCourse(Course c) {
    if (isWalking || !isUnlocked(c) || c.comingSoon) return false;
    currentCourseId = c.id;
    sessionSteps = 0;
    bonusClaimed = false;
    notifyListeners();
    return true;
  }

  /// 해금 광고 1회 시청 완료. 필요 횟수를 채우면 해금되고 true
  bool addUnlockAd(Course c) {
    final watched = unlockAdsWatched(c) + 1;
    _unlockAds[c.id] = watched;
    if (watched >= kUnlockAdsRequired) unlockedCourses.add(c.id);
    notifyListeners();
    return isUnlocked(c);
  }

  /// 결제로 해금
  void unlockByPurchase(Course c) {
    unlockedCourses.add(c.id);
    notifyListeners();
  }

  // ---------- 진행 상황 ----------

  /// 지금 코스에서 아직 도착하지 않은 가장 가까운 지역 (완주했으면 null)
  Region? get nextRegion {
    for (final r in course.regions) {
      if (r.km > traveledKm) return r;
    }
    return null;
  }

  /// 지금 근처에 있고 아직 획득하지 않은 랜드마크 (없으면 null)
  Landmark? get nearbyLandmark {
    for (final l in course.landmarks) {
      final inRange = (traveledKm - l.km).abs() <= kLandmarkRangeKm;
      if (inRange && !landmarkIds.contains(l.id)) return l;
    }
    return null;
  }

  final Set<String> _alertedLandmarks = {}; // 이미 알림을 보낸 랜드마크

  /// 랜드마크 근처에 새로 들어섰으면 알림을 한 번만 보냄
  void _checkLandmarkAlert() {
    final l = nearbyLandmark;
    if (l != null && _alertedLandmarks.add(l.id)) {
      NotificationService.landmarkNearby(l);
    }
  }

  /// 획득하지 못한 채 지나쳐버린 랜드마크인지
  bool isLandmarkMissed(Course c, Landmark l) =>
      !landmarkIds.contains(l.id) && kmFor(c) > l.km + kLandmarkRangeKm;

  // ---------- 산책 세션 ----------

  void startSession() {
    isWalking = true;
    sessionSteps = 0;
    bonusClaimed = false;
    sessionRegions.clear();
    sessionLandmarks.clear();
    sessionOutfits.clear();
    _sessionStartKm = traveledKm;
    notifyListeners();
  }

  void endSession() {
    isWalking = false;
    notifyListeners();
  }

  /// 걸음을 더하고, 이번에 새로 도착한 지역 목록을 돌려줍니다.
  /// 지금은 테스트 버튼이 호출하고, 나중에 실제 걸음 수 API로 교체합니다.
  List<Region> addSteps(int steps) {
    if (!isWalking) return [];
    final before = traveledKm;
    totalSteps += steps;
    sessionSteps += steps;
    final key = dayKey(DateTime.now());
    dailySteps[key] = (dailySteps[key] ?? 0) + steps;
    _advance(steps);
    _checkLandmarkAlert();
    return _collectArrivals(before);
  }

  /// before 지점부터 현재 위치 사이에 도착한 지역 중, 아직 없는 특산물만 지급
  /// (다시 여행할 때는 이미 가진 특산물이라 아무것도 지급되지 않음)
  List<Region> _collectArrivals(double before) {
    final after = traveledKm;
    final reached = course.regions
        .where((r) => r.km > before && r.km <= after && !collectedIds.contains(r.id))
        .toList();
    for (final r in reached) {
      collectedIds.add(r.id);
    }
    sessionRegions.addAll(reached);
    _grantCourseOutfit();
    notifyListeners();
    return reached;
  }

  /// 랜드마크를 눌렀을 때 호출. 근처에 있을 때만 획득되며,
  /// 새로 획득했으면 true를 돌려줍니다.
  bool collectLandmark(Landmark l) {
    if ((traveledKm - l.km).abs() > kLandmarkRangeKm) return false;
    final added = landmarkIds.add(l.id);
    if (added) sessionLandmarks.add(l);
    notifyListeners();
    return added;
  }

  // ---------- 보상형 광고 ----------

  int _adsToday = 0;
  String _adDay = '';

  String get _today => dayKey(DateTime.now());

  int get adsLeftToday =>
      _adDay == _today ? kMaxAdsPerDay - _adsToday : kMaxAdsPerDay;

  void _useAd() {
    if (_adDay != _today) {
      _adDay = _today;
      _adsToday = 0;
    }
    _adsToday++;
  }

  /// 산책을 끝낸 뒤, 아직 2배 보너스를 안 받았고 광고 횟수가 남았는지
  bool get canDoubleSession =>
      !isWalking && sessionSteps > 0 && !bonusClaimed && adsLeftToday > 0;

  /// 광고 시청 완료 후 호출: 이번 산책 걸음만큼 한 번 더 전진 (= 2배)
  List<Region> applyDoubleBonus() {
    if (!canDoubleSession) return [];
    _useAd();
    bonusClaimed = true;
    final before = traveledKm;
    bonusSteps += sessionSteps;
    _advance(sessionSteps);
    _checkLandmarkAlert();
    return _collectArrivals(before);
  }

  /// 광고 시청 완료 후 호출: 놓친 랜드마크를 되찾음
  bool recoverLandmark(Course c, Landmark l) {
    if (!isLandmarkMissed(c, l) || adsLeftToday <= 0) return false;
    _useAd();
    landmarkIds.add(l.id);
    notifyListeners();
    return true;
  }
}