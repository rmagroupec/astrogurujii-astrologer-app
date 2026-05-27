import 'dart:convert';

AstrologerProfileResponse astrologerProfileResponseFromJson(String str) =>
    AstrologerProfileResponse.fromJson(json.decode(str));

class AstrologerProfileResponse {
  final bool status;
  final String message;
  final List<Astrologer> results;

  AstrologerProfileResponse({
    required this.status,
    required this.message,
    required this.results,
  });

  factory AstrologerProfileResponse.fromJson(Map<String, dynamic> json) {
    return AstrologerProfileResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => Astrologer.fromJson(e))
          .toList(),
    );
  }
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
  final String bio;
  final String about;
  final int experience;
  final String address;
  final String dob;
  final String gender;
  final String profileImg;


  final bool isChatEnabled;
  final bool isVoiceCallEnabled;
  final bool isVideoCallEnabled;
  final int perMinChat;
  final int perMinVoiceCall;
  final int perMinVideoCall;
  final int perQuestionPrice;

  final List<Skill> skill;
  final List<Language> language;
  final List<Category> category;
  final List<Gallery> galary;
  final List<Rating> rating;

  Astrologer({
    required this.id,
    required this.displayname,
    required this.email,
    required this.number,
    required this.bio,
    required this.about,
    required this.experience,
    required this.address,
    required this.dob,
    required this.gender,
    required this.profileImg,
    required this.isChatEnabled,
    required this.isVoiceCallEnabled,
    required this.isVideoCallEnabled,
    required this.perMinChat,
    required this.perMinVoiceCall,
    required this.perMinVideoCall,
    required this.perQuestionPrice,
    required this.skill,
    required this.language,
    required this.category,
    required this.galary,
    required this.rating,
  });

  factory Astrologer.fromJson(Map<String, dynamic> json) {
    return Astrologer(
      id: json["id"] ?? "",
      displayname: json["displayname"] ?? "",
      email: json["email"] ?? "",
      number: json["number"] ?? "",
      bio: json["bio"] ?? "",
      about: json["about"] ?? "",
      experience: json["experience"] ?? 0,
      address: json["address"] ?? "",
      dob: json["dob"] ?? "",
      gender: json["gender"] ?? "",
      profileImg: json["profile_img"] ?? "",
isChatEnabled: toBool(json['is_chat']),
      isVoiceCallEnabled: toBool(json['is_voice_call']),
      isVideoCallEnabled: toBool(json['is_video_call']),
      perMinChat: json["per_min_chat"] ?? 0,
      perMinVoiceCall: json["per_min_voice_call"] ?? 0,
      perMinVideoCall: json["per_min_video_call"] ?? 0,
      perQuestionPrice: json["per_question_price"] ?? 0,

      skill: json["skill"] == null
          ? []
          : List<Skill>.from(
              json["skill"].map((x) => Skill.fromJson(x))),

      language: json["language"] == null
          ? []
          : List<Language>.from(
              json["language"].map((x) => Language.fromJson(x))),

      category: json["category"] == null
          ? []
          : List<Category>.from(
              json["category"].map((x) => Category.fromJson(x))),

      galary: json["galary"] == null
          ? []
          : List<Gallery>.from(
              json["galary"].map((x) => Gallery.fromJson(x))),

      rating: json["rating"] == null
          ? []
          : List<Rating>.from(
              json["rating"].map((x) => Rating.fromJson(x))),
    );
  }
}

class Skill {
  final String id;
  final String name;

  Skill({required this.id, required this.name});

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
    );
  }
}

class Language {
  final String id;
  final String name;

  Language({required this.id, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
    );
  }
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
    );
  }
}

class Gallery {
  final String id;
  final String file;

  Gallery({required this.id, required this.file});

  factory Gallery.fromJson(Map<String, dynamic> json) {
    return Gallery(
      id: json["_id"] ?? "",
      file: json["file"] ?? "",
    );
  }
}

class Rating {
  final String id;
  final String profileImg;
  final int rating;
  final String review;
  final String createdDate;

  Rating({
    required this.id,
    required this.profileImg,
    required this.rating,
    required this.review,
    required this.createdDate,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json["id"] ?? "",
      profileImg: json["profile_img"] ?? "",
      rating: json["rating"] ?? 0,
      review: json["review"] ?? "",
      createdDate: json["Created_date"] ?? "",
    );
  }
}
