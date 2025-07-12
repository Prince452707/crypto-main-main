class DeFiPool {
  final String id;
  final String name;
  final String protocol;
  final List<String> tokens;
  final double apy;
  final double tvl;
  final double volume24h;
  final double fees24h;
  final PoolType type;
  final RiskLevel riskLevel;
  final List<PoolReward> rewards;
  final bool isActive;
  final DateTime createdAt;

  const DeFiPool({
    required this.id,
    required this.name,
    required this.protocol,
    required this.tokens,
    required this.apy,
    required this.tvl,
    required this.volume24h,
    required this.fees24h,
    required this.type,
    required this.riskLevel,
    required this.rewards,
    required this.isActive,
    required this.createdAt,
  });

  factory DeFiPool.fromJson(Map<String, dynamic> json) {
    return DeFiPool(
      id: json['id'],
      name: json['name'],
      protocol: json['protocol'],
      tokens: List<String>.from(json['tokens']),
      apy: (json['apy'] as num).toDouble(),
      tvl: (json['tvl'] as num).toDouble(),
      volume24h: (json['volume24h'] as num).toDouble(),
      fees24h: (json['fees24h'] as num).toDouble(),
      type: PoolType.values.firstWhere((e) => e.name == json['type']),
      riskLevel: RiskLevel.values.firstWhere((e) => e.name == json['riskLevel']),
      rewards: (json['rewards'] as List)
          .map((item) => PoolReward.fromJson(item))
          .toList(),
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'protocol': protocol,
      'tokens': tokens,
      'apy': apy,
      'tvl': tvl,
      'volume24h': volume24h,
      'fees24h': fees24h,
      'type': type.name,
      'riskLevel': riskLevel.name,
      'rewards': rewards.map((item) => item.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PoolReward {
  final String token;
  final double apy;
  final double dailyReward;
  final RewardType type;

  const PoolReward({
    required this.token,
    required this.apy,
    required this.dailyReward,
    required this.type,
  });

  factory PoolReward.fromJson(Map<String, dynamic> json) {
    return PoolReward(
      token: json['token'],
      apy: (json['apy'] as num).toDouble(),
      dailyReward: (json['dailyReward'] as num).toDouble(),
      type: RewardType.values.firstWhere((e) => e.name == json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'apy': apy,
      'dailyReward': dailyReward,
      'type': type.name,
    };
  }
}

enum PoolType {
  liquidityPool,
  stakingPool,
  yieldFarm,
  lending,
  borrowing,
}

enum RiskLevel {
  low,
  medium,
  high,
  extreme,
}

enum RewardType {
  trading,
  staking,
  governance,
  liquidity,
}

class YieldPosition {
  final String id;
  final String poolId;
  final String poolName;
  final double amount;
  final double value;
  final double apy;
  final double earnedRewards;
  final List<EarnedReward> rewardBreakdown;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  const YieldPosition({
    required this.id,
    required this.poolId,
    required this.poolName,
    required this.amount,
    required this.value,
    required this.apy,
    required this.earnedRewards,
    required this.rewardBreakdown,
    required this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory YieldPosition.fromJson(Map<String, dynamic> json) {
    return YieldPosition(
      id: json['id'],
      poolId: json['poolId'],
      poolName: json['poolName'],
      amount: (json['amount'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      apy: (json['apy'] as num).toDouble(),
      earnedRewards: (json['earnedRewards'] as num).toDouble(),
      rewardBreakdown: (json['rewardBreakdown'] as List)
          .map((item) => EarnedReward.fromJson(item))
          .toList(),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poolId': poolId,
      'poolName': poolName,
      'amount': amount,
      'value': value,
      'apy': apy,
      'earnedRewards': earnedRewards,
      'rewardBreakdown': rewardBreakdown.map((item) => item.toJson()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  double get dailyRewards => (earnedRewards * apy / 365) / 100;
  int get daysActive => DateTime.now().difference(startDate).inDays;
}

class EarnedReward {
  final String token;
  final double amount;
  final double value;
  final RewardType type;

  const EarnedReward({
    required this.token,
    required this.amount,
    required this.value,
    required this.type,
  });

  factory EarnedReward.fromJson(Map<String, dynamic> json) {
    return EarnedReward(
      token: json['token'],
      amount: (json['amount'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      type: RewardType.values.firstWhere((e) => e.name == json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'amount': amount,
      'value': value,
      'type': type.name,
    };
  }
}
