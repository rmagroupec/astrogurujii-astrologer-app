class LastCallListModel {
  bool?   result;
  String? message;
  Data2?  data2;

  LastCallListModel({this.result, this.message, this.data2});

  factory LastCallListModel.fromJson(Map<String, dynamic> json) =>
      LastCallListModel(
        result : json['result'],
        message: json['message']?.toString(),
        data2  : json['data2'] != null ? Data2.fromJson(json['data2']) : null,
      );
}

class Data2 {
  String?  id;
  String?  channelId;
  String?  fbChannelId;
  String?  astroId;
  String?  userId;
  String?  startTime;
  String?  endTime;
  int?     difference;
  String?  callDuration;
  String?  status;
  String?  callType;
  String?  country;
  dynamic  userWallet;
  String?  userName;
  String?  userImage;
  String?  astroName;
  String?  astroProfileImg;
  String?  callRate;
  String?  totalAmount;
  String?  maxMinit;
  // Kundli fields
  String?  name;
  String?  gender;
  String?  place;

  Data2({
    this.id, this.channelId, this.fbChannelId, this.astroId,
    this.userId, this.startTime, this.endTime, this.difference,
    this.callDuration, this.status, this.callType, this.country,
    this.userWallet, this.userName, this.userImage, this.astroName,
    this.astroProfileImg, this.callRate, this.totalAmount, this.maxMinit,
    this.name, this.gender, this.place,
  });

  factory Data2.fromJson(Map<String, dynamic> json) => Data2(
    id             : json['id']?.toString(),
    channelId      : json['channel_id']?.toString(),
    fbChannelId    : json['fb_channel_id']?.toString(),
    astroId        : json['astro_id']?.toString(),
    userId         : json['user_id']?.toString(),
    startTime      : json['start_time']?.toString(),
    endTime        : json['end_time']?.toString(),
    difference     : int.tryParse(json['difference']?.toString() ?? ''),
    callDuration   : json['call_duracation']?.toString(),
    status         : json['status']?.toString(),
    callType       : json['call_type']?.toString(),
    country        : json['country']?.toString(),
    userWallet     : json['user_wallet'],
    userName       : json['user_name']?.toString(),
    userImage      : json['user_image']?.toString(),
    astroName      : json['astro_name']?.toString(),
    astroProfileImg: json['astro_profile_img']?.toString(),
    callRate       : json['call_rate']?.toString(),
    totalAmount    : json['total_amount']?.toString(),
    maxMinit       : json['max_minit']?.toString(),
    name           : json['name']?.toString(),
    gender         : json['gender']?.toString(),
    place          : json['place']?.toString(),
  );
}