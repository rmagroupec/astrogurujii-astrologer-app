class AstrologerGiftResponse {
  final bool status;
  final List<AstrologerGift> gifts;

  AstrologerGiftResponse({
    required this.status,
    required this.gifts,
  });

  factory AstrologerGiftResponse.fromJson(Map<String, dynamic> json) {
    return AstrologerGiftResponse(
      status: json['status'] == true,
      gifts: (json['gifts'] as List?)
              ?.map((e) => AstrologerGift.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AstrologerGift {
  final String id;
  final GiftUser fromUser;
  final GiftItem gift;
  final String type;
  final double amount;
  final DateTime createdAt;
  final LiveInfo? liveInfo;

  AstrologerGift({
    required this.id,
    required this.fromUser,
    required this.gift,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.liveInfo,
  });

  factory AstrologerGift.fromJson(Map<String, dynamic> json) {
    return AstrologerGift(
      id: json['_id']?.toString() ?? '',
      fromUser: GiftUser.fromJson(json['fromUser'] ?? {}),
      gift: GiftItem.fromJson(json['gift'] ?? {}),
      type: json['type']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      liveInfo: json['liveId'] != null && json['liveId'] is Map
          ? LiveInfo.fromJson(json['liveId'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class GiftUser {
  final String id;
  final String name;
  final String profileImg;

  GiftUser({
    required this.id,
    required this.name,
    required this.profileImg,
  });

  factory GiftUser.fromJson(Map<String, dynamic> json) {
    return GiftUser(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Anonymous',
      profileImg: json['profile_img']?.toString() ?? '',
    );
  }
}

class GiftItem {
  final String id;
  final String title;
  final String image;
  final double price;

  GiftItem({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
  });

  factory GiftItem.fromJson(Map<String, dynamic> json) {
    return GiftItem(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      price: AstrologerGift._parseDouble(json['price']),
    );
  }
}

class LiveInfo {
  final String id;
  final String title;

  LiveInfo({
    required this.id,
    required this.title,
  });

  factory LiveInfo.fromJson(Map<String, dynamic> json) {
    return LiveInfo(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
    );
  }
}
