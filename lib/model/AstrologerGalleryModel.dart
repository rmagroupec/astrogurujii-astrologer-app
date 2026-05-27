import 'dart:convert';

/// ===============================
/// JSON Helpers
/// ===============================

AstrologerGalleryResponse astrologerGalleryResponseFromJson(String str) =>
    AstrologerGalleryResponse.fromJson(json.decode(str));

String astrologerGalleryResponseToJson(AstrologerGalleryResponse data) =>
    json.encode(data.toJson());

/// ===============================
/// Top-Level Response Model
/// ===============================

class AstrologerGalleryResponse {
  final bool status;
  final String message;
  final List<AstrologerGalleryItem> results;

  AstrologerGalleryResponse({
    required this.status,
    required this.message,
    required this.results,
  });

  factory AstrologerGalleryResponse.fromJson(Map<String, dynamic> json) {
    return AstrologerGalleryResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => AstrologerGalleryItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}

/// ===============================
/// Gallery Item Model
/// ===============================

class AstrologerGalleryItem {
  final String id;
  final String astrologerId;
  final String file;
  final DateTime createdDate;

  AstrologerGalleryItem({
    required this.id,
    required this.astrologerId,
    required this.file,
    required this.createdDate,
  });

  factory AstrologerGalleryItem.fromJson(Map<String, dynamic> json) {
    return AstrologerGalleryItem(
      id: json['id'] ?? '',
      astrologerId: json['astrologer_id'] ?? '',
      file: json['file'] ?? '',
      createdDate: _toDate(json['Created_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'astrologer_id': astrologerId,
      'file': file,
      'Created_date': createdDate.toIso8601String(),
    };
  }

  /// ===============================
  /// Computed Helpers (Optional)
  /// ===============================

  bool get hasFile => file.isNotEmpty;
}

/// ===============================
/// Safe Date Parsing
/// ===============================

DateTime _toDate(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.tryParse(value.toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
