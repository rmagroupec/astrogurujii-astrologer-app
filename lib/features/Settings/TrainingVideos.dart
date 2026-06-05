// lib/features/Settings/TrainingVideosScreen.dart

import 'dart:convert';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class TrainingVideo {
  final String id;
  final String title;
  final String youtubeUrl;
  final String thumbnail;
  final String category;
  final String description;

  const TrainingVideo({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.thumbnail,
    required this.category,
    required this.description,
  });

  factory TrainingVideo.fromJson(Map<String, dynamic> j) => TrainingVideo(
        id         : j['id']?.toString()          ?? '',
        title      : j['title']?.toString()       ?? '',
        youtubeUrl : j['youtube_url']?.toString() ?? '',
        thumbnail  : j['thumbnail']?.toString()   ?? '',
        category   : j['category']?.toString()    ?? '',
        description: j['description']?.toString() ?? '',
      );

  /// Extract video ID from any YouTube URL format
  String get videoId {
    final m = RegExp(r'(?:v=|youtu\.be/)([A-Za-z0-9_-]{11})')
        .firstMatch(youtubeUrl);
    return m?.group(1) ?? '';
  }

  String get autoThumbnail =>
      thumbnail.isNotEmpty
          ? thumbnail
          : 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}

// ── Screen ────────────────────────────────────────────────────────────────────
class TrainingVideosScreen extends StatefulWidget {
  const TrainingVideosScreen({super.key});

  @override
  State<TrainingVideosScreen> createState() => _TrainingVideosScreenState();
}

class _TrainingVideosScreenState extends State<TrainingVideosScreen> {
  final _client = ApiClient();

  List<TrainingVideo> _videos   = [];
  List<String>        _categories = ['All'];
  String              _selected = 'All';
  bool                _loading  = true;
  String?             _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res  = await _client.post(
        'astrologer_api/training_videos', {},
        isAuthRequired: true,
      );
      final json = jsonDecode(res.body);
      if (!mounted) return;
      if (json['result'] == true) {
        final list = (json['data'] as List)
            .map((e) => TrainingVideo.fromJson(e))
            .toList();
        final cats = <String>{'All'};
        for (final v in list) cats.add(v.category);
        setState(() {
          _videos     = list;
          _categories = cats.toList();
          _loading    = false;
        });
      } else {
        setState(() { _error = json['message']; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<TrainingVideo> get _filtered =>
      _selected == 'All'
          ? _videos
          : _videos.where((v) => v.category == _selected).toList();

  Future<void> _open(TrainingVideo v) async {
    final uri = Uri.parse(v.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open YouTube')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title          : const Text('Training Videos'),
        backgroundColor: const Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
        elevation      : 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD417)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      SizedBox(height: FigmaSize.h(12)),
                      Text(_error!, style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center),
                      SizedBox(height: FigmaSize.h(12)),
                      TextButton.icon(
                        onPressed: _load,
                        icon : const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Category filter chips ──────────────────────────────
                    if (_categories.length > 1) ...[
                      Container(
                        width      : double.infinity,
                        color      : Colors.white,
                        padding    : EdgeInsets.symmetric(
                            vertical: FigmaSize.h(10)),
                        child: SizedBox(
                          height: FigmaSize.h(36),
                          child: ListView.separated(
                            scrollDirection : Axis.horizontal,
                            padding         : EdgeInsets.symmetric(
                                horizontal: FigmaSize.w(16)),
                            itemCount       : _categories.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(width: FigmaSize.w(8)),
                            itemBuilder: (_, i) {
                              final cat      = _categories[i];
                              final selected = cat == _selected;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selected = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: FigmaSize.w(16)),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFFCD417)
                                        : const Color(0xFFF5F5F5),
                                    borderRadius:
                                        BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFFCD417)
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize  : FigmaSize.w(12),
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: selected
                                          ? Colors.black
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Divider(
                          height  : 1,
                          thickness: 1,
                          color   : Colors.grey.shade100),
                    ],

                    // ── Video list ─────────────────────────────────────────
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No videos in this category.',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: FigmaSize.w(14)),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color    : const Color(0xFFFCD417),
                              child    : ListView.separated(
                                padding: EdgeInsets.all(FigmaSize.w(16)),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: FigmaSize.h(14)),
                                itemBuilder: (_, i) =>
                                    _VideoCard(_filtered[i], onTap: _open),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final TrainingVideo video;
  final void Function(TrainingVideo) onTap;
  const _VideoCard(this.video, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(video),
      child: Container(
        decoration: BoxDecoration(
          color       : Colors.white,
          border      : Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(10),
          boxShadow   : [
            BoxShadow(
              color    : Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset   : const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play overlay
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10)),
                  child: Image.network(
                    video.autoThumbnail,
                    width     : double.infinity,
                    height    : FigmaSize.h(160),
                    fit       : BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: FigmaSize.h(160),
                      color : Colors.grey.shade100,
                      child : const Icon(Icons.video_library,
                          color: Colors.grey, size: 48),
                    ),
                  ),
                ),
                Container(
                  width : FigmaSize.w(48),
                  height: FigmaSize.h(48),
                  decoration: BoxDecoration(
                    color       : Colors.black.withOpacity(0.55),
                    shape       : BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 28),
                ),
                // Category badge
                Positioned(
                  top  : 8, right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: FigmaSize.w(8),
                        vertical  : FigmaSize.h(3)),
                    decoration: BoxDecoration(
                      color       : const Color(0xFFFCD417),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      video.category,
                      style: TextStyle(
                          fontSize  : FigmaSize.w(10),
                          fontWeight: FontWeight.w600,
                          color     : Colors.black),
                    ),
                  ),
                ),
              ],
            ),

            // Title + description
            Padding(
              padding: EdgeInsets.all(FigmaSize.w(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: TextStyle(
                      fontSize  : FigmaSize.w(14),
                      fontWeight: FontWeight.w600,
                      color     : Colors.black,
                    ),
                  ),
                  if (video.description.isNotEmpty) ...[
                    SizedBox(height: FigmaSize.h(4)),
                    Text(
                      video.description,
                      maxLines : 2,
                      overflow : TextOverflow.ellipsis,
                      style    : TextStyle(
                          fontSize: FigmaSize.w(12), color: Colors.grey),
                    ),
                  ],
                  SizedBox(height: FigmaSize.h(8)),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline,
                          color: Colors.red, size: 18),
                      SizedBox(width: FigmaSize.w(4)),
                      Text(
                        'Watch on YouTube',
                        style: TextStyle(
                          fontSize  : FigmaSize.w(12),
                          color     : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          size: 12, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}