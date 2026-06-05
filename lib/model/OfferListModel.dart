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

class OfferItem {
  final String id;
  final String title;
  final String chatPrice;
  final String audioPrice;
  final String videoPrice;
  final String status;
  final String createdDate;
  final String updatedAt;

  OfferItem({
    required this.id,
    required this.title,
    required this.chatPrice,
    required this.audioPrice,
    required this.videoPrice,
    required this.status,
    required this.createdDate,
    required this.updatedAt,
  });

  factory OfferItem.fromJson(Map<String, dynamic> json) => OfferItem(
        id:          json['id']           ?? '',
        title:       json['title']        ?? '',
        chatPrice:   json['chat_price']   ?? '0',
        audioPrice:  json['audio_price']  ?? '0',
        videoPrice:  json['video_price']  ?? '0',
        status:      json['status']       ?? '',
        createdDate: json['Created_date'] ?? '',
        updatedAt:   json['updated_at']   ?? '',
      );
}