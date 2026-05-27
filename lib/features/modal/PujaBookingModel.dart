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
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => PoojaBooking.fromJson(e))
          .toList(),
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
  final String? pujaId;
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
      id: json['_id'] ?? '',
      pujaBookingId: json['puja_booking_id'] ?? '',
      channelId: json['channel_id'] ?? '',
      astrologerId: json['astrologer_id'] ?? '',
      astrologerName: json['astrologer_name'] ?? '',
      users: json['users'] ?? '',
      pujaId: json['puja_id'],
      pujaDate: json['puja_date'] ?? '',
      pujaType: json['puja_type'] ?? '',
      pujaAmount: json['puja_amount'] ?? '0',
      isLive: json['is_live'] ?? false,
      isActive: json['is_active'] ?? false,
      isHomeDeliveryRequired:
          json['is_home_delivery_required'] ?? false,
      paymentMode: json['payment_mode'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      baseTotal: (json['base_total'] ?? 0).toDouble(),
      addonsTotal: (json['addons_total'] ?? 0).toDouble(),
      homeAddonsTotal: (json['home_addons_total'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      finalAmount: (json['final_amount'] ?? 0).toDouble(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      deliveryAddress:
          DeliveryAddress.fromJson(json['deliveryAddress'] ?? {}),
      room: json['room'] ?? [],
      addonsSelected: json['addons_selected'] ?? [],
      homeAddonsSelected: json['home_addons_selected'] ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
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
      pincode: json['pincode'],
      city: json['city'],
      state: json['state'],
      houseNumber: json['houseNumber'],
      area: json['area'],
      landmark: json['landmark'],
    );
  }
}

