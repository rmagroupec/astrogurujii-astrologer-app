class PoojaBookingResponse {
  final bool status;
  final String message;
  final List<PoojaBooking> data;

  PoojaBookingResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PoojaBookingResponse.fromJson(Map<String, dynamic> json) {
    return PoojaBookingResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: (json['data'] as List?)
              ?.map((e) => PoojaBooking.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PoojaBooking {
  final String id;
  final String pujaBookingId;
  final String channelId;
  final String astrologerId;
  final String astrologerName;
  final String users;
 final PujaDetail? pujaId;
// ← API sends object OR null
  final String pujaDate;
  final String pujaType;
  final String pujaAmount;
  final bool isLive;
  final bool isActive;
  final bool isHomeDeliveryRequired;
  final String paymentMode;
  final String paymentStatus;
  final double baseTotal;
  final double addonsTotal;
  final double homeAddonsTotal;
  final double discount;
  final double finalAmount;
  final String startTime;
  final String endTime;
  final DeliveryAddress deliveryAddress;
  final List<dynamic> room;
  final List<dynamic> addonsSelected;
  final List<dynamic> homeAddonsSelected;
  final DateTime createdAt;
  final DateTime updatedAt;

  PoojaBooking({
    required this.id,
    required this.pujaBookingId,
    required this.channelId,
    required this.astrologerId,
    required this.astrologerName,
    required this.users,
    this.pujaId,
    required this.pujaDate,
    required this.pujaType,
    required this.pujaAmount,
    required this.isLive,
    required this.isActive,
    required this.isHomeDeliveryRequired,
    required this.paymentMode,
    required this.paymentStatus,
    required this.baseTotal,
    required this.addonsTotal,
    required this.homeAddonsTotal,
    required this.discount,
    required this.finalAmount,
    required this.startTime,
    required this.endTime,
    required this.deliveryAddress,
    required this.room,
    required this.addonsSelected,
    required this.homeAddonsSelected,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PoojaBooking.fromJson(Map<String, dynamic> json) {
    return PoojaBooking(
      id: json['_id']?.toString() ?? '',
      pujaBookingId: json['puja_booking_id']?.toString() ?? '',
      channelId: json['channel_id']?.toString() ?? '',
      astrologerId: json['astrologer_id']?.toString() ?? '',
      astrologerName: json['astrologer_name']?.toString() ?? '',
      users: json['users']?.toString() ?? '',
      pujaId: json['puja_id'] != null && json['puja_id'] is Map
    ? PujaDetail.fromJson(json['puja_id'])
    : null,

      pujaDate: json['puja_date']?.toString() ?? '',
      pujaType: json['puja_type']?.toString() ?? '',
      pujaAmount: json['puja_amount']?.toString() ?? '0',
      isLive: json['is_live'] == true,
      isActive: json['is_active'] == true,
      isHomeDeliveryRequired:
          json['is_home_delivery_required'] == true,
      paymentMode: json['payment_mode']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      baseTotal: _parseDouble(json['base_total']),
      addonsTotal: _parseDouble(json['addons_total']),
      homeAddonsTotal: _parseDouble(json['home_addons_total']),
      discount: _parseDouble(json['discount']),
      finalAmount: _parseDouble(json['final_amount']),
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      deliveryAddress: DeliveryAddress.fromJson(
        json['deliveryAddress'] ?? {},
      ),
      room: json['room'] as List? ?? [],
      addonsSelected: json['addons_selected'] as List? ?? [],
      homeAddonsSelected: json['home_addons_selected'] as List? ?? [],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  /// ================= HELPERS =================
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

class DeliveryAddress {
  final String? pincode;
  final String? city;
  final String? state;
  final String? houseNumber;
  final String? area;
  final String? landmark;

  DeliveryAddress({
    this.pincode,
    this.city,
    this.state,
    this.houseNumber,
    this.area,
    this.landmark,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      pincode: json['pincode']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      houseNumber: json['houseNumber']?.toString(),
      area: json['area']?.toString(),
      landmark: json['landmark']?.toString(),
    );
  }
}

class PujaDetail {
  final String id;
  final String title;
  final String pujaImage;
  final String mandirName;
  final String aboutPuja;

  PujaDetail({
    required this.id,
    required this.title,
    required this.pujaImage,
    required this.mandirName,
    required this.aboutPuja,
  });

  factory PujaDetail.fromJson(Map<String, dynamic> json) {
    return PujaDetail(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      pujaImage: json['pujaImage']?.toString() ?? '',
      mandirName: json['mandirName']?.toString() ?? '',
      aboutPuja: json['aboutPuja']?.toString() ?? '',
    );
  }
}
