// lib/model/astrologerProfileModel.dart
// TrainingVideo is NOT defined here — it lives in
// lib/features/Settings/TrainingVideos.dart to avoid the duplicate-class compile error.
import 'dart:convert';

AstrologerProfileResponse astrologerProfileResponseFromJson(String str) =>
    AstrologerProfileResponse.fromJson(json.decode(str));

class AstrologerProfileResponse {
  final bool             status;
  final String           message;
  final List<Astrologer> results;

  AstrologerProfileResponse({
    required this.status,
    required this.message,
    required this.results,
  });

  factory AstrologerProfileResponse.fromJson(Map<String, dynamic> json) =>
      AstrologerProfileResponse(
        status : json['status']  ?? false,
        message: json['message'] ?? '',
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => Astrologer.fromJson(e))
            .toList(),
      );
}

bool toBool(dynamic value) {
  if (value == null) return false;
  return value.toString().toLowerCase() == 'on';
}

class Astrologer {
  final String id;
  final String displayname;
  final String email;
  final String number;
  final String stateId;   // ← ADD (maps to state_id from backend)
final String cityId;
  final String bio;
  final String about;
  final int    experience;
  final String address;
  final String city;       // ← ADD
  final String pincode;    // ← ADD
  final String country;    // ← ADD
  final String panCard;    // ← ADD
  final String gst;  
  final String dob;
  final String gender;
  final String profileImg;
  

  // ── Service-enabled flags (permanent) ─────────────────────────────────────
  final bool isChatEnabled;
  final bool isVoiceCallEnabled;
  final bool isVideoCallEnabled;

  // ── Real-time online status (what the Home toggle controls) ───────────────
  final bool isChatOnline;
  final bool isVoiceOnline;
  final bool isVideoOnline;

  // ── Rates ─────────────────────────────────────────────────────────────────
  final int perMinChat;
  final int perMinVoiceCall;
  final int perMinVideoCall;
  final int perQuestionPrice;

  // ── Schedule next online ──────────────────────────────────────────────────
  final String nextOnlineChat;
  final String nextOnlineCall;
  final String nextOnlineVideo;

  // ── Emergency ─────────────────────────────────────────────────────────────
  final bool isEmergencyChat;
  final bool isEmergencyCall;

  // ── Auto boost ────────────────────────────────────────────────────────────
  final bool autoBoostChat;
  final bool autoBoostCall;

  // ── Sub-objects ───────────────────────────────────────────────────────────
  final List<Skill>    skill;
  final List<Language> language;
  final List<Category> category;
  final List<Gallery>  galary;
  final List<Rating>   rating;

  Astrologer({
    required this.id,
    required this.displayname,
    required this.email,
    required this.number,
    required this.bio,
    required this.about,
    required this.experience,
    required this.address,
    this.city    = '',     // ← ADD
    this.pincode = '',     // ← ADD
    this.country = '',     // ← ADD
    this.panCard = '',     // ← ADD
    this.gst     = '', 
    this.stateId = '',
this.cityId  = '',
    required this.dob,
    required this.gender,
    required this.profileImg,
    required this.isChatEnabled,
    required this.isVoiceCallEnabled,
    required this.isVideoCallEnabled,
    required this.isChatOnline,
    required this.isVoiceOnline,
    required this.isVideoOnline,
    required this.perMinChat,
    required this.perMinVoiceCall,
    required this.perMinVideoCall,
    required this.perQuestionPrice,
    required this.nextOnlineChat,
    required this.nextOnlineCall,
    required this.nextOnlineVideo,
    required this.isEmergencyChat,
    required this.isEmergencyCall,
    required this.autoBoostChat,
    required this.autoBoostCall,
    required this.skill,
    required this.language,
    required this.category,
    required this.galary,
    required this.rating,
  });

  factory Astrologer.fromJson(Map<String, dynamic> json) => Astrologer(
    id             : json['id']           ?? '',
    displayname    : json['displayname']  ?? '',
    email          : json['email']        ?? '',
    number         : json['number']       ?? '',
    bio            : json['bio']          ?? '',
    about          : json['about']        ?? '',
    experience     : _toInt(json['experience']),
    address        : json['address']      ?? '',
    city        : json['city']        ?? '',     // ← ADD
    pincode     : json['pincode']     ?? '',     // ← ADD
    country     : json['country']     ?? 'India',// ← ADD
    panCard     : json['pan_card']    ?? '',     // ← ADD
    gst         : json['gst']         ?? '', 
    dob            : json['dob']          ?? '',
    gender         : json['gender']       ?? '',
    profileImg     : json['profile_img']  ?? '',
    stateId : json['state_id']?.toString() ?? '',
cityId  : json['city_id']?.toString()  ?? '',

    isChatEnabled      : toBool(json['is_chat']),
    isVoiceCallEnabled : toBool(json['is_voice_call']),
    isVideoCallEnabled : toBool(json['is_video_call']),

    isChatOnline  : toBool(json['is_chat_online']),
    isVoiceOnline : toBool(json['is_voice_online']),
    isVideoOnline : toBool(json['is_video_online']),

    perMinChat        : _toInt(json['per_min_chat']),
    perMinVoiceCall   : _toInt(json['per_min_voice_call']),
    perMinVideoCall   : _toInt(json['per_min_video_call']),
    perQuestionPrice  : _toInt(json['per_question_price']),

    nextOnlineChat  : json['next_online_chat']  ?? '',
    nextOnlineCall  : json['next_online_call']  ?? '',
    nextOnlineVideo : json['next_online_video'] ?? '',

    isEmergencyChat : toBool(json['is_emergency_chat']),
    isEmergencyCall : toBool(json['is_emergency_call']),

    autoBoostChat   : toBool(json['auto_boost_chat']),
    autoBoostCall   : toBool(json['auto_boost_call']),

    skill    : (json['skill']    as List<dynamic>? ?? []).map((e) => Skill.fromJson(e)).toList(),
    language : (json['language'] as List<dynamic>? ?? []).map((e) => Language.fromJson(e)).toList(),
    category : (json['category'] as List<dynamic>? ?? []).map((e) => Category.fromJson(e)).toList(),
    galary   : (json['galary']   as List<dynamic>? ?? []).map((e) => Gallery.fromJson(e)).toList(),
    rating   : (json['rating']   as List<dynamic>? ?? []).map((e) => Rating.fromJson(e)).toList(),
  );

  static int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

// ── Sub-models ────────────────────────────────────────────────────────────────
class Skill {
  final String id, name;
  Skill({required this.id, required this.name});
  factory Skill.fromJson(Map<String, dynamic> j) =>
      Skill(id: j['_id'] ?? '', name: j['name'] ?? '');
}

class Language {
  final String id, name;
  Language({required this.id, required this.name});
  factory Language.fromJson(Map<String, dynamic> j) =>
      Language(id: j['_id'] ?? '', name: j['name'] ?? '');
}

class Category {
  final String id, name;
  Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['_id'] ?? '', name: j['name'] ?? '');
}

class Gallery {
  final String id, file;
  Gallery({required this.id, required this.file});
  factory Gallery.fromJson(Map<String, dynamic> j) =>
      Gallery(id: j['_id'] ?? '', file: j['file'] ?? '');
}

class Rating {
  final String id, profileImg, review, createdDate;
  final int    rating;
  Rating({
    required this.id,
    required this.profileImg,
    required this.rating,
    required this.review,
    required this.createdDate,
  });
  factory Rating.fromJson(Map<String, dynamic> j) => Rating(
    id          : j['id']           ?? '',
    profileImg  : j['profile_img']  ?? '',
    rating      : int.tryParse(j['rating']?.toString() ?? '0') ?? 0,
    review      : j['review']       ?? '',
    createdDate : j['Created_date'] ?? '',
  );
}