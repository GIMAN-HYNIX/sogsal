// 데이터 모델 (기획서 8장 기준). 1단계는 기기 안에만 저장한다.

enum Gender { male, female }

enum Goal { lose, maintain, muscle }

enum BodySource { inbody, estimate }

extension GenderLabel on Gender {
  String get label => this == Gender.male ? '남성' : '여성';
}

extension GoalLabel on Goal {
  String get label => switch (this) {
        Goal.lose => '살 빼기',
        Goal.maintain => '유지',
        Goal.muscle => '근육 늘리기',
      };
}

class UserProfile {
  final Gender gender;
  final int age;
  final double heightCm;
  final double targetWeightKg;
  final Goal goal;
  final bool agreedDisclaimer;

  const UserProfile({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.targetWeightKg,
    required this.goal,
    required this.agreedDisclaimer,
  });

  UserProfile copyWith({
    Gender? gender,
    int? age,
    double? heightCm,
    double? targetWeightKg,
    Goal? goal,
  }) =>
      UserProfile(
        gender: gender ?? this.gender,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        goal: goal ?? this.goal,
        agreedDisclaimer: agreedDisclaimer,
      );

  Map<String, dynamic> toJson() => {
        'gender': gender.name,
        'age': age,
        'heightCm': heightCm,
        'targetWeightKg': targetWeightKg,
        'goal': goal.name,
        'agreedDisclaimer': agreedDisclaimer,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        gender: Gender.values.byName(j['gender'] as String),
        age: (j['age'] as num).toInt(),
        heightCm: (j['heightCm'] as num).toDouble(),
        targetWeightKg: (j['targetWeightKg'] as num).toDouble(),
        goal: Goal.values.byName(j['goal'] as String),
        agreedDisclaimer: j['agreedDisclaimer'] as bool? ?? false,
      );
}

/// 체성분 기록 한 건.
class BodyComposition {
  final DateTime date;
  final double weightKg;
  final double muscleKg; // 골격근량
  final double fatKg; // 체지방량
  final double visceralLevel; // 내장지방 레벨 (1~20)
  final double? waistCm;
  final BodySource source;

  const BodyComposition({
    required this.date,
    required this.weightKg,
    required this.muscleKg,
    required this.fatKg,
    required this.visceralLevel,
    required this.source,
    this.waistCm,
  });

  double get fatPercent => weightKg <= 0 ? 0 : fatKg / weightKg * 100;
  bool get isEstimate => source == BodySource.estimate;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'muscleKg': muscleKg,
        'fatKg': fatKg,
        'visceralLevel': visceralLevel,
        'waistCm': waistCm,
        'source': source.name,
      };

  factory BodyComposition.fromJson(Map<String, dynamic> j) => BodyComposition(
        date: DateTime.parse(j['date'] as String),
        weightKg: (j['weightKg'] as num).toDouble(),
        muscleKg: (j['muscleKg'] as num).toDouble(),
        fatKg: (j['fatKg'] as num).toDouble(),
        visceralLevel: (j['visceralLevel'] as num).toDouble(),
        waistCm: (j['waistCm'] as num?)?.toDouble(),
        source: BodySource.values.byName(j['source'] as String),
      );
}

/// 캐릭터 꾸미기 상태. 1단계는 색상만.
class CharacterStyle {
  final int hairColor;
  final int outfitColor;
  final int skinColor;
  final String? hairStyle; // null이면 성별 기본(여자 보브, 남자 짧은 머리)

  static const defaultSkin = 0xFFF5C3A8;

  const CharacterStyle({
    this.hairColor = 0xFF1E2346,
    this.outfitColor = 0xFF3A6FD8,
    this.skinColor = defaultSkin,
    this.hairStyle,
  });

  CharacterStyle copyWith({int? hairColor, int? outfitColor, int? skinColor, String? hairStyle}) => CharacterStyle(
        hairColor: hairColor ?? this.hairColor,
        outfitColor: outfitColor ?? this.outfitColor,
        skinColor: skinColor ?? this.skinColor,
        hairStyle: hairStyle ?? this.hairStyle,
      );

  Map<String, dynamic> toJson() => {
        'hairColor': hairColor,
        'outfitColor': outfitColor,
        'skinColor': skinColor,
        if (hairStyle != null) 'hairStyle': hairStyle,
      };

  factory CharacterStyle.fromJson(Map<String, dynamic> j) => CharacterStyle(
        hairColor: j['hairColor'] as int? ?? 0xFF1E2346,
        outfitColor: j['outfitColor'] as int? ?? 0xFF3A6FD8,
        skinColor: j['skinColor'] as int? ?? defaultSkin,
        hairStyle: j['hairStyle'] as String?,
      );
}

/// 눈바디로 맞춘 부위별 보정. 각 값은 -1(가늘게) ~ 1(굵게), 0이면 숫자로 계산한 그대로.
class BodyTweak {
  final double shoulder, waist, hip, arm, thigh;

  const BodyTweak({this.shoulder = 0, this.waist = 0, this.hip = 0, this.arm = 0, this.thigh = 0});

  static const none = BodyTweak();

  bool get isNone => shoulder == 0 && waist == 0 && hip == 0 && arm == 0 && thigh == 0;

  BodyTweak copyWith({double? shoulder, double? waist, double? hip, double? arm, double? thigh}) => BodyTweak(
        shoulder: shoulder ?? this.shoulder,
        waist: waist ?? this.waist,
        hip: hip ?? this.hip,
        arm: arm ?? this.arm,
        thigh: thigh ?? this.thigh,
      );

  static BodyTweak lerp(BodyTweak a, BodyTweak b, double t) => BodyTweak(
        shoulder: a.shoulder + (b.shoulder - a.shoulder) * t,
        waist: a.waist + (b.waist - a.waist) * t,
        hip: a.hip + (b.hip - a.hip) * t,
        arm: a.arm + (b.arm - a.arm) * t,
        thigh: a.thigh + (b.thigh - a.thigh) * t,
      );

  Map<String, dynamic> toJson() => {'shoulder': shoulder, 'waist': waist, 'hip': hip, 'arm': arm, 'thigh': thigh};

  factory BodyTweak.fromJson(Map<String, dynamic> j) {
    double v(String k) => ((j[k] as num?)?.toDouble() ?? 0).clamp(-1.0, 1.0);
    return BodyTweak(shoulder: v('shoulder'), waist: v('waist'), hip: v('hip'), arm: v('arm'), thigh: v('thigh'));
  }

  @override
  bool operator ==(Object other) =>
      other is BodyTweak &&
      other.shoulder == shoulder &&
      other.waist == waist &&
      other.hip == hip &&
      other.arm == arm &&
      other.thigh == thigh;

  @override
  int get hashCode => Object.hash(shoulder, waist, hip, arm, thigh);
}

/// 눈바디 사진. 폰 안에만 저장한다(줄인 JPEG를 base64로).
class BodyPhoto {
  final String id;
  final DateTime date;
  final String jpegBase64;

  const BodyPhoto({required this.id, required this.date, required this.jpegBase64});

  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'jpeg': jpegBase64};

  factory BodyPhoto.fromJson(Map<String, dynamic> j) => BodyPhoto(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        jpegBase64: j['jpeg'] as String,
      );
}
