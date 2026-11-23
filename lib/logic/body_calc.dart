// 체성분 추정 · 체형 분류 · 안전 가드 (기획서 6장).
// 주의: 아래 기준은 모두 임시 규칙이다. 출시 전 영양사·전문가 검수가 필요하다.
import 'dart:math' as math;

import '../models/models.dart';

enum BodyType { standard, skinnyFat, muscular, chubby, muscleFat, underweight }

extension BodyTypeInfo on BodyType {
  String get label => switch (this) {
        BodyType.standard => '표준',
        BodyType.skinnyFat => '마른비만',
        BodyType.muscular => '근육형',
        BodyType.chubby => '통통',
        BodyType.muscleFat => '근육돼지',
        BodyType.underweight => '저체중',
      };

  String get comment => switch (this) {
        BodyType.standard => '균형 잡힌 몸이에요. 지금처럼만 가요.',
        BodyType.skinnyFat => '겉은 날씬해도 근육이가 부족해요. 단백질과 근력운동이 필요해요.',
        BodyType.muscular => '근육이가 튼튼해요. 잘 유지해봐요.',
        BodyType.chubby => '지방이가 조금 많아요. 천천히 건강하게 줄여봐요.',
        BodyType.muscleFat => '근육도 지방도 많아요. 근육은 지키고 지방만 덜어내요.',
        BodyType.underweight => '몸이 너무 가벼워요. 감량보다 영양을 먼저 챙겨요.',
      };

  bool get isWarning => this == BodyType.underweight;
}

/// 0~1 범위의 캐릭터 체형 파라미터.
class BodyShape {
  final double fatness;
  final double muscle;
  const BodyShape(this.fatness, this.muscle);
}

double _clamp01(double v) => v.clamp(0.0, 1.0).toDouble();

double log10(num x) => math.log(x) / math.ln10;

class BodyCalc {
  static double bmi(double weightKg, double heightCm) {
    final m = heightCm / 100;
    return weightKg / (m * m);
  }

  /// 미 해군법(US Navy) 체지방률 추정. 단위 cm.
  /// 여성은 엉덩이 둘레가 필요하다.
  static double? navyBodyFatPercent({
    required Gender gender,
    required double heightCm,
    required double neckCm,
    required double waistCm,
    double? hipCm,
  }) {
    double bf;
    if (gender == Gender.male) {
      final d = waistCm - neckCm;
      if (d <= 0) return null;
      bf = 495 / (1.0324 - 0.19077 * log10(d) + 0.15456 * log10(heightCm)) - 450;
    } else {
      if (hipCm == null) return null;
      final d = waistCm + hipCm - neckCm;
      if (d <= 0) return null;
      bf = 495 / (1.29579 - 0.35004 * log10(d) + 0.22100 * log10(heightCm)) - 450;
    }
    if (bf.isNaN || bf.isInfinite) return null;
    return bf.clamp(3.0, 60.0).toDouble();
  }

  /// 제지방량에서 골격근량을 대략 계산 (임시 계수).
  static double estimateMuscleKg(Gender gender, double weightKg, double fatPercent) {
    final lbm = weightKg * (1 - fatPercent / 100);
    return lbm * (gender == Gender.male ? 0.53 : 0.49);
  }

  /// 허리둘레(있으면)나 체지방률로 내장지방 레벨을 대략 추정 (1~20, 임시 규칙).
  static double estimateVisceralLevel({
    required Gender gender,
    required double fatPercent,
    double? waistCm,
  }) {
    double level;
    if (waistCm != null) {
      // 복부비만 기준(남 90 / 여 85cm)에서 레벨 10 정도가 되도록.
      final base = gender == Gender.male ? 70.0 : 65.0;
      level = 1 + (waistCm - base) / 2.2;
    } else {
      final base = gender == Gender.male ? 8.0 : 15.0;
      level = 1 + (fatPercent - base) * 0.6;
    }
    return level.clamp(1.0, 20.0).roundToDouble();
  }

  /// 키 대비 골격근 지수 (kg/m²).
  static double muscleIndex(double muscleKg, double heightCm) {
    final m = heightCm / 100;
    return muscleKg / (m * m);
  }

  /// 체지방률 × 근육량 2축으로 6가지 체형 분류. 성별 기준 적용, 나이 미반영.
  static BodyType classify(Gender gender, double heightCm, BodyComposition b) {
    final bmiV = bmi(b.weightKg, heightCm);
    final bf = b.fatPercent;
    final mi = muscleIndex(b.muscleKg, heightCm);
    final male = gender == Gender.male;

    final fatVeryLow = bf < (male ? 6 : 14);
    if (bmiV < 18.5 || fatVeryLow) return BodyType.underweight;

    final fatOver = bf >= (male ? 20 : 28);
    final fatHigh = bf >= (male ? 25 : 32);
    final muscleLow = mi < (male ? 9.5 : 7.0);
    final muscleHigh = mi >= (male ? 11.5 : 8.8);

    if (muscleHigh && fatOver) return BodyType.muscleFat;
    if (muscleHigh) return BodyType.muscular;
    if (muscleLow && fatOver && bmiV < 25) return BodyType.skinnyFat;
    if (fatHigh || bmiV >= 25) return BodyType.chubby;
    return BodyType.standard;
  }

  /// 캐릭터 외형 파라미터.
  static BodyShape shapeOf(Gender gender, double heightCm, BodyComposition b) {
    final male = gender == Gender.male;
    final fat = _clamp01((b.fatPercent - (male ? 8 : 16)) / (male ? 24 : 24));
    final mi = muscleIndex(b.muscleKg, heightCm);
    final mus = _clamp01((mi - (male ? 8.5 : 6.3)) / (male ? 4.0 : 3.2));
    return BodyShape(fat, mus);
  }

  // ---------------- 칼로리 · 단백질 목표 (나이는 여기에만 쓴다) ----------------

  /// Mifflin-St Jeor 기초대사량.
  static double bmr(UserProfile p, double weightKg) {
    final base = 10 * weightKg + 6.25 * p.heightCm - 5 * p.age;
    return p.gender == Gender.male ? base + 5 : base - 161;
  }

  /// 하루 권장 칼로리 (가벼운 활동 1.375 가정). 극단적 저칼로리를 막는 하한 적용.
  static int dailyCalories(UserProfile p, double weightKg) {
    final tdee = bmr(p, weightKg) * 1.375;
    final target = switch (p.goal) {
      Goal.lose => tdee - 500,
      Goal.maintain => tdee,
      Goal.muscle => tdee + 250,
    };
    final floor = math.max(bmr(p, weightKg), p.gender == Gender.male ? 1500.0 : 1200.0);
    return math.max(target, floor).round();
  }

  /// 하루 단백질 목표 (g). 감량·근육 목표는 kg당 1.6g, 유지는 1.2g.
  static int dailyProteinG(UserProfile p, double weightKg) {
    final perKg = p.goal == Goal.maintain ? 1.2 : 1.6;
    return (weightKg * perKg).round();
  }

  // ---------------- 안전 가드 ----------------

  /// 목표 체중이 저체중(BMI 18.5 미만)이면 막는다. 문제 없으면 null.
  static String? targetWeightWarning(double heightCm, double targetKg) {
    final minKg = 18.5 * math.pow(heightCm / 100, 2);
    if (targetKg < minKg) {
      return '건강을 위해 목표 체중은 ${minKg.toStringAsFixed(1)}kg 이상으로 정해주세요.';
    }
    return null;
  }

  /// 주당 체중의 1%를 넘게 빠지면 급감량 경고.
  static String? rapidLossWarning(List<BodyComposition> records) {
    if (records.length < 2) return null;
    final last = records.last;
    final weekAgo = last.date.subtract(const Duration(days: 7));
    final prev = records.lastWhere(
      (r) => !r.date.isAfter(weekAgo),
      orElse: () => records.first,
    );
    final days = last.date.difference(prev.date).inDays;
    if (days < 3) return null;
    final perWeek = (prev.weightKg - last.weightKg) / days * 7;
    if (perWeek > prev.weightKg * 0.01) {
      return '일주일에 ${perWeek.toStringAsFixed(1)}kg씩 빠지고 있어요. 너무 빠르면 근육이 같이 빠져요. 천천히 가요.';
    }
    return null;
  }

  /// 직전 기록과 비교해 무엇이 변했는지 한마디.
  static String? changeMessage(BodyComposition? prev, BodyComposition now) {
    if (prev == null) return null;
    final dFat = now.fatKg - prev.fatKg;
    final dMus = now.muscleKg - prev.muscleKg;
    final dVis = now.visceralLevel - prev.visceralLevel;
    if (dMus <= -0.3) return '근육이가 줄었어요. 단백질이 부족하진 않았나요?';
    if (dVis <= -1) return '내장지방이가 가벼워졌어요. 숨쉬기 편해 보여요.';
    if (dFat <= -0.3) return '지방이가 ${(-dFat).toStringAsFixed(1)}kg 빠졌어요. 이대로만 가요.';
    if (dMus >= 0.3) return '근육이가 ${dMus.toStringAsFixed(1)}kg 늘었어요.';
    if (dFat >= 0.5) return '지방이가 조금 늘었어요. 오늘은 가볍게 먹어볼까요?';
    return '큰 변화는 없어요. 꾸준함이 제일 중요해요.';
  }
}

/// 부위별 속 보기용 추정치.
enum BodyPart { belly, arm, thigh, chest }

extension BodyPartInfo on BodyPart {
  String get label => switch (this) {
        BodyPart.belly => '뱃살',
        BodyPart.arm => '팔뚝',
        BodyPart.thigh => '허벅지·엉덩이',
        BodyPart.chest => '가슴·등',
      };
}

class PartDetail {
  final double subFatKg;
  final double muscleKg;
  final double? visceralLevel; // 배에만
  const PartDetail(this.subFatKg, this.muscleKg, this.visceralLevel);
}

class PartCalc {
  // 부위별 분포 비율 (임시 값, 추정 시각화용).
  static const _fatShareMale = {
    BodyPart.belly: 0.34, BodyPart.arm: 0.10, BodyPart.thigh: 0.30, BodyPart.chest: 0.26,
  };
  static const _fatShareFemale = {
    BodyPart.belly: 0.26, BodyPart.arm: 0.12, BodyPart.thigh: 0.42, BodyPart.chest: 0.20,
  };
  static const _muscleShare = {
    BodyPart.belly: 0.12, BodyPart.arm: 0.13, BodyPart.thigh: 0.45, BodyPart.chest: 0.30,
  };

  static PartDetail of(Gender g, BodyComposition b, BodyPart part) {
    final share = g == Gender.male ? _fatShareMale : _fatShareFemale;
    // 배의 체지방 중 일부는 내장지방으로 본다.
    var sub = b.fatKg * share[part]!;
    if (part == BodyPart.belly) sub *= 0.7;
    return PartDetail(
      sub,
      b.muscleKg * _muscleShare[part]!,
      part == BodyPart.belly ? b.visceralLevel : null,
    );
  }

  static String partComment(BodyPart part, PartDetail d, BodyShape s) {
    if (part == BodyPart.belly && (d.visceralLevel ?? 0) >= 15) {
      return '내장지방이: "끙, 자리가 너무 좁아요. 조금만 덜어주세요."';
    }
    if (part == BodyPart.belly && (d.visceralLevel ?? 0) >= 10) {
      return '내장지방이: "슬슬 북적거려요. 걷기 운동 어때요?"';
    }
    if (s.muscle < 0.3) return '근육이: "저 혼자 버티기 힘들어요. 단백질 좀 주세요."';
    if (s.fatness > 0.65) return '지방이: "여기 편해서 눌러앉았어요."';
    return '근육이: "오늘도 든든하게 버티는 중이에요."';
  }
}
