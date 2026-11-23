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

  const CharacterStyle({this.hairColor = 0xFF1E2346, this.outfitColor = 0xFF3A6FD8});

  CharacterStyle copyWith({int? hairColor, int? outfitColor}) => CharacterStyle(
        hairColor: hairColor ?? this.hairColor,
        outfitColor: outfitColor ?? this.outfitColor,
      );

  Map<String, dynamic> toJson() => {'hairColor': hairColor, 'outfitColor': outfitColor};

  factory CharacterStyle.fromJson(Map<String, dynamic> j) => CharacterStyle(
        hairColor: j['hairColor'] as int? ?? 0xFF1E2346,
        outfitColor: j['outfitColor'] as int? ?? 0xFF3A6FD8,
      );
}
