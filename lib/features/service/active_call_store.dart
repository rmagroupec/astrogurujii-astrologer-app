// lib/service/active_call_store.dart
//
// Persists the currently active call/chat to SharedPreferences so it survives
// process death (app backgrounded → OS kills process → user returns).
//
// USAGE:
//   • When a call screen opens      → ActiveCallStore.save(...)
//   • When a call ends              → ActiveCallStore.clear()
//   • On app cold-start / resume    → ActiveCallStore.restore() → re-open screen

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ActiveCallType { audio, video, chat }

class ActiveCallRecord {
  final ActiveCallType type;
  final String channelId;
  final String token;
  final String userName;
  final String userAvatar;
  final String astroId;   // chat only
  final String userId;    // chat only
  final int    savedAt;   // epoch ms

  const ActiveCallRecord({
    required this.type,
    required this.channelId,
    required this.token,
    required this.userName,
    required this.userAvatar,
    this.astroId   = '',
    this.userId    = '',
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'type'       : type.name,
    'channelId'  : channelId,
    'token'      : token,
    'userName'   : userName,
    'userAvatar' : userAvatar,
    'astroId'    : astroId,
    'userId'     : userId,
    'savedAt'    : savedAt,
  };

  factory ActiveCallRecord.fromJson(Map<String, dynamic> j) =>
      ActiveCallRecord(
        type       : ActiveCallType.values.firstWhere(
                       (e) => e.name == j['type'],
                       orElse: () => ActiveCallType.audio),
        channelId  : j['channelId']  ?? '',
        token      : j['token']      ?? '',
        userName   : j['userName']   ?? '',
        userAvatar : j['userAvatar'] ?? '',
        astroId    : j['astroId']    ?? '',
        userId     : j['userId']     ?? '',
        savedAt    : j['savedAt']    ?? 0,
      );

  /// How long ago this was saved (ms)
  int get ageMs => DateTime.now().millisecondsSinceEpoch - savedAt;
}

class ActiveCallStore {
  ActiveCallStore._();

  static const _key    = 'active_call_record';
  static const _maxAge = 5 * 60 * 1000; // 5 minutes — stale after this

  // ── Save ────────────────────────────────────────────────────────────────
  static Future<void> save({
    required ActiveCallType type,
    required String channelId,
    required String token,
    required String userName,
    required String userAvatar,
    String astroId  = '',
    String userId   = '',
  }) async {
    final record = ActiveCallRecord(
      type      : type,
      channelId : channelId,
      token     : token,
      userName  : userName,
      userAvatar: userAvatar,
      astroId   : astroId,
      userId    : userId,
      savedAt   : DateTime.now().millisecondsSinceEpoch,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(record.toJson()));
  }

  // ── Clear ────────────────────────────────────────────────────────────────
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ── Restore ──────────────────────────────────────────────────────────────
  /// Returns the active call record if one exists and is not stale.
  /// Returns null if there's no record or it's too old (call likely ended).
  static Future<ActiveCallRecord?> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_key);
      if (raw == null) return null;

      final record = ActiveCallRecord.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);

      if (record.ageMs > _maxAge) {
        // Call data is stale — the call has certainly ended by now
        await clear();
        return null;
      }

      return record;
    } catch (_) {
      return null;
    }
  }
}