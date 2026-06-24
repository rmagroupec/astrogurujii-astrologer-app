import 'dart:convert';

/// ===============================
/// JSON Helpers
/// ===============================

RatingListResponse ratingListResponseFromJson(String str) =>
    RatingListResponse.fromJson(json.decode(str));

String ratingListResponseToJson(RatingListResponse data) =>
    json.encode(data.toJson());

/// ===============================
/// Top-Level Response
/// ===============================

class RatingListResponse {
  final bool status;
  final String message;
  final List<RatingItem> results;
  
  // ── ADDED FIELDS FOR FLAGGED DATA METRICS ───────────────────
  final String? flaggedRatio;
  final double? flaggedValue;

  RatingListResponse({
    required this.status,
    required this.message,
    required this.results,
    this.flaggedRatio,
    this.flaggedValue,
  });

  factory RatingListResponse.fromJson(Map<String, dynamic> json) {
    return RatingListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      flaggedRatio: json['flagged_ratio'] ?? '0/10',
      flaggedValue: _toDouble(json['flagged_value']),
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => RatingItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'flagged_ratio': flaggedRatio,
      'flagged_value': flaggedValue,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}

/// ===============================
/// Rating Item Model
/// ===============================

class RatingItem {
  final String id;
  final String name;
  final String profileImg;
  final int rating;
  final String review;
  final String astrologerComment;
  final DateTime createdDate;
  
  // ── ADDED FIELDS FOR DYNAMIC FILTERING & ACTIONS ───────────
  final String type; // 'chat', 'voice', 'video', 'astromall'
  final bool isPinned;
   final String   callType;
  final bool isFlagged;

  RatingItem({
    required this.id,
    required this.name,
    required this.profileImg,
    required this.rating,
    required this.review,
    required this.astrologerComment,
    required this.createdDate,
    required this.type,
    required this.isPinned,
    required this.callType,
    required this.isFlagged,
  });

  factory RatingItem.fromJson(Map<String, dynamic> json) {
    return RatingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      profileImg: json['profile_img'] ?? '',
      rating: _toInt(json['rating']),
      review: json['review'] ?? '',
      astrologerComment: json['astr_comment'] ?? '',
      createdDate: _toDate(json['Created_date']),
      // Map the newly created fields with safe fallbacks
      type: json['type'] ?? 'chat',
      isPinned: json['is_pinned'] ?? false,
      callType          : json['call_type']?.toString()    ?? 'chat',
      isFlagged: json['is_flagged'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_img': profileImg,
      'rating': rating,
      'review': review,
      'astr_comment': astrologerComment,
      'Created_date': createdDate.toIso8601String(),
      'type': type,
      'call_type'   : callType,
      'is_pinned': isPinned,
      'is_flagged': isFlagged,
    };
  }

  /// ===============================
  /// Computed Helpers (Optional)
  /// ===============================

  bool get hasReview => review.trim().isNotEmpty;

  String get displayName =>
      name.isNotEmpty ? name : 'Anonymous';

  String get formattedDate =>
      "${createdDate.day.toString().padLeft(2, '0')}-"
      "${createdDate.month.toString().padLeft(2, '0')}-"
      "${createdDate.year}";
}

/// ===============================
/// Safe Parsing Helpers
/// ===============================

int _toInt(dynamic value) {
  if (value == null) return 0;
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  return double.tryParse(value.toString()) ?? 0.0;
}

DateTime _toDate(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.tryParse(value.toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}