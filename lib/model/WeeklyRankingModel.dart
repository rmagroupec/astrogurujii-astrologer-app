class WeeklyRankingResponse {
  final bool result;
  final String message;
  final WeekRange weekRange;
  final List<RankingItem> ranking;
  final YourStats yourStats;

  WeeklyRankingResponse({
    required this.result,
    required this.message,
    required this.weekRange,
    required this.ranking,
    required this.yourStats,
  });

  factory WeeklyRankingResponse.fromJson(Map<String, dynamic> json) {
    return WeeklyRankingResponse(
      result: json['result'] ?? false,
      message: json['message'] ?? '',
      weekRange: WeekRange.fromJson(json['week_range'] ?? {}),
      ranking: (json['ranking'] as List<dynamic>? ?? [])
          .map((e) => RankingItem.fromJson(e))
          .toList(),
      yourStats: YourStats.fromJson(json['your_stats'] ?? {}),
    );
  }
}
class WeekRange {
  final String from;
  final String to;

  WeekRange({
    required this.from,
    required this.to,
  });

  factory WeekRange.fromJson(Map<String, dynamic> json) {
    return WeekRange(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
    );
  }
}
class RankingItem {
  final String rank;
  final String astrologerId;
  final String earning;

  RankingItem({
    required this.rank,
    required this.astrologerId,
    required this.earning,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    return RankingItem(
      rank: json['rank'] ?? '0',
      astrologerId: json['astrologer_id'] ?? '',
      earning: json['earning'] ?? '0',
    );
  }
}
class YourStats {
  final String yourRank;
  final String yourWeeklyEarning;

  YourStats({
    required this.yourRank,
    required this.yourWeeklyEarning,
  });

  factory YourStats.fromJson(Map<String, dynamic> json) {
    return YourStats(
      yourRank: json['your_rank'] ?? '0',
      yourWeeklyEarning: json['your_weekly_earning'] ?? '0',
    );
  }
}
