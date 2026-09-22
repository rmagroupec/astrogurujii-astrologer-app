import 'dart:convert';

OfferListResponse offerListResponseFromJson(String str) =>
    OfferListResponse.fromJson(json.decode(str));

class OfferListResponse {
  final bool status;
  final String message;
  final List<OfferItem> results;

  OfferListResponse({
    required this.status,
    required this.message,
    required this.results,
  });

  factory OfferListResponse.fromJson(Map<String, dynamic> json) =>
      OfferListResponse(
        status:  json['status']  ?? false,
        message: json['message'] ?? '',
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => OfferItem.fromJson(e))
            .toList(),
      );
}

class OfferTier {
  final double originalPrice;
  final double discountedPrice;
  final double yourShare;
  final double atShare;

  OfferTier({
    required this.originalPrice,
    required this.discountedPrice,
    required this.yourShare,
    required this.atShare,
  });

  factory OfferTier.fromJson(Map<String, dynamic>? json) => OfferTier(
        originalPrice  : double.tryParse('${json?['original_price']   ?? 0}') ?? 0,
        discountedPrice: double.tryParse('${json?['discounted_price'] ?? 0}') ?? 0,
        yourShare      : double.tryParse('${json?['your_share']       ?? 0}') ?? 0,
        atShare        : double.tryParse('${json?['at_share']         ?? 0}') ?? 0,
      );
}

class OfferItem {
  final String   id;
  final String   title;
  final String   status;      // global admin status — informational only
  final bool     isActive;    // ✅ THIS astrologer's own current toggle state
  final String   startTime;   // ✅ when they turned it on — empty if inactive
  final int      minActiveMinutes;
  final OfferTier newUser;
  final OfferTier loyalUser;
  final String   createdDate;
  final String   updatedAt;

  OfferItem({
    required this.id,
    required this.title,
    required this.status,
    required this.isActive,
    required this.startTime,
    required this.minActiveMinutes,
    required this.newUser,
    required this.loyalUser,
    required this.createdDate,
    required this.updatedAt,
  });

  factory OfferItem.fromJson(Map<String, dynamic> json) => OfferItem(
        id:          json['id']?.toString()          ?? '',
        title:       json['title']?.toString()       ?? '',
        status:      json['status']?.toString()      ?? '',
        isActive:    json['is_active'] == true,
        startTime:   json['start_time']?.toString()  ?? '',
        minActiveMinutes: int.tryParse('${json['min_active_minutes'] ?? 60}') ?? 60,
        newUser:     OfferTier.fromJson(json['new_user']   as Map<String, dynamic>?),
        loyalUser:   OfferTier.fromJson(json['loyal_user'] as Map<String, dynamic>?),
        createdDate: json['Created_date']?.toString() ?? '',
        updatedAt:   json['updated_at']?.toString()   ?? '',
      );
}

// ── History ────────────────────────────────────────────────────────────

OfferHistoryResponse offerHistoryResponseFromJson(String str) =>
    OfferHistoryResponse.fromJson(json.decode(str));

class OfferHistoryResponse {
  final bool status;
  final String message;
  final List<OfferHistoryItem> results;

  OfferHistoryResponse({
    required this.status,
    required this.message,
    required this.results,
  });

  factory OfferHistoryResponse.fromJson(Map<String, dynamic> json) =>
      OfferHistoryResponse(
        status:  json['status']  ?? false,
        message: json['message'] ?? '',
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => OfferHistoryItem.fromJson(e))
            .toList(),
      );
}

// ── Toggle result ──────────────────────────────────────────────────────
// Shared return type for ToggleOfferActivation, so both liveService.dart
// and OffersScreen.dart can reference it via the same model import.
class ToggleResult {
  final bool   success;
  final String message;
  ToggleResult(this.success, this.message);
}

class OfferHistoryItem {
  final String offerId;
  final String title;
  final String startTime;
  final String endTime;
  final String status; // "Completed"

  OfferHistoryItem({
    required this.offerId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory OfferHistoryItem.fromJson(Map<String, dynamic> json) => OfferHistoryItem(
        offerId:   json['offer_id']?.toString()   ?? '',
        title:     json['title']?.toString()      ?? '',
        startTime: json['start_time']?.toString() ?? '',
        endTime:   json['end_time']?.toString()   ?? '',
        status:    json['status']?.toString()     ?? '',
      );
}