// 앱 상태 + 기기 내 저장. 1단계는 서버 없이 shared_preferences만 쓴다.
// 나중에 Supabase/Firebase로 바꿀 때는 _load/_save만 교체하면 된다.
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/body_calc.dart';
import '../models/models.dart';

class AppStore extends ChangeNotifier {
  static const _key = 'sogsal_state_v1';

  UserProfile? profile;
  List<BodyComposition> records = [];
  CharacterStyle style = const CharacterStyle();
  bool loaded = false;

  bool get onboarded => profile != null && records.isNotEmpty;
  BodyComposition? get latest => records.isEmpty ? null : records.last;
  BodyComposition? get previous =>
      records.length < 2 ? null : records[records.length - 2];

  BodyType? get bodyType => onboarded
      ? BodyCalc.classify(profile!.gender, profile!.heightCm, latest!)
      : null;

  BodyShape get shape => onboarded
      ? BodyCalc.shapeOf(profile!.gender, profile!.heightCm, latest!)
      : const BodyShape(0.4, 0.4);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        if (j['profile'] != null) {
          profile = UserProfile.fromJson(j['profile'] as Map<String, dynamic>);
        }
        records = [
          for (final r in (j['records'] as List? ?? []))
            BodyComposition.fromJson(r as Map<String, dynamic>),
        ]..sort((a, b) => a.date.compareTo(b.date));
        if (j['style'] != null) {
          style = CharacterStyle.fromJson(j['style'] as Map<String, dynamic>);
        }
      }
    } catch (_) {
      // 저장소가 깨졌으면 처음부터 시작한다.
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'profile': profile?.toJson(),
        'records': [for (final r in records) r.toJson()],
        'style': style.toJson(),
      }),
    );
  }

  void completeOnboarding(UserProfile p, BodyComposition first) {
    profile = p;
    records = [first];
    notifyListeners();
    _save();
  }

  void updateProfile(UserProfile p) {
    profile = p;
    notifyListeners();
    _save();
  }

  /// 같은 날 기록은 덮어쓴다.
  void addRecord(BodyComposition r) {
    records.removeWhere((e) => _sameDay(e.date, r.date));
    records.add(r);
    records.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
    _save();
  }

  /// 체중만 빠르게 기록. 체지방률·근육 비율은 직전 기록을 유지한 추정치로 넣는다.
  void addWeightOnly(double weightKg) {
    final last = latest!;
    final ratio = weightKg / last.weightKg;
    addRecord(BodyComposition(
      date: DateTime.now(),
      weightKg: weightKg,
      muscleKg: last.muscleKg * ratio,
      fatKg: last.fatKg * ratio,
      visceralLevel: last.visceralLevel,
      waistCm: last.waistCm,
      source: BodySource.estimate,
    ));
  }

  void updateStyle(CharacterStyle s) {
    style = s;
    notifyListeners();
    _save();
  }

  Future<void> reset() async {
    profile = null;
    records = [];
    style = const CharacterStyle();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
