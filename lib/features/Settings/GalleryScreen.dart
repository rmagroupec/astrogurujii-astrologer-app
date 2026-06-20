// lib/features/Settings/GalleryScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens ──────────────────────────────────
// ── Delete API wired via astrologer_api/delete_galary (id param) ──────────────
// ── Toggle enable/disable wired via astrologer_api/update_galary_status ────────
// ── Upload, load, delete, toggle — all fully functional ──────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/CustomSwitchButton.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:astrologer_app/model/AstrologerGalleryModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:astrologer_app/service/liveService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────
class Galleryscreen extends StatefulWidget {
  const Galleryscreen({super.key});

  @override
  State<Galleryscreen> createState() => _GalleryscreenState();
}

class _GalleryscreenState extends State<Galleryscreen> {
  bool isLoading   = true;
  bool isUploading = false;
  List<AstrologerGalleryItem> data = [];

  final _picker = ImagePicker();
  final _client = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load gallery ──────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService().getGalleryList();
      setState(() {
        data      = response.results;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Gallery load error: $e');
      setState(() => isLoading = false);
    }
  }

  // ── Delete a gallery image ────────────────────────────────────────────────
  Future<bool> _deleteImage(String id) async {
    try {
      final res  = await _client.post(
        'astrologer_api/delete_galary',
        {'id': id},
        isAuthRequired: true,
      );
      final body = jsonDecode(res.body);
      return body['status'] == true;
    } catch (e) {
      debugPrint('❌ deleteImage error: $e');
      return false;
    }
  }

  // ── Toggle image enabled/disabled ────────────────────────────────────────
  Future<bool> _toggleImage(String id, bool enabled) async {
    try {
      final res  = await _client.post(
        'astrologer_api/update_galary_status',
        {'id': id, 'status': enabled ? 'on' : 'off'},
        isAuthRequired: true,
      );
      final body = jsonDecode(res.body);
      return body['status'] == true;
    } catch (e) {
      debugPrint('❌ toggleImage error: $e');
      return false;
    }
  }

  // ── Show picker sheet ─────────────────────────────────────────────────────
  Future<void> _showPickerSheet() async {
    final c = context.colors;
    await showModalBottomSheet(
      context           : context,
      backgroundColor   : Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color       : c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(20),
              vertical  : FigmaSize.h(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width : 40, height: 4,
                  decoration: BoxDecoration(
                    color       : c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: FigmaSize.h(20)),
                Text(
                  'Upload Image',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(16),
                    fontWeight: FontWeight.bold,
                    color     : c.text,
                  ),
                ),
                SizedBox(height: FigmaSize.h(20)),
                Row(
                  children: [
                    Expanded(
                      child: _PickerOption(
                        icon : Icons.camera_alt_outlined,
                        label: 'Camera',
                        c    : c,
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndUpload(ImageSource.camera);
                        },
                      ),
                    ),
                    SizedBox(width: FigmaSize.w(16)),
                    Expanded(
                      child: _PickerOption(
                        icon : Icons.photo_library_outlined,
                        label: 'Gallery',
                        c    : c,
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndUpload(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: FigmaSize.h(16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Pick + upload ─────────────────────────────────────────────────────────
  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      List<XFile> picked = [];
      if (source == ImageSource.gallery) {
        picked = await _picker.pickMultiImage(imageQuality: 80);
      } else {
        final img = await _picker.pickImage(
            source: ImageSource.camera, imageQuality: 80);
        if (img != null) picked = [img];
      }

      if (picked.isEmpty) return;
      setState(() => isUploading = true);

      final files   = picked.map((x) => File(x.path)).toList();
      final success = await Liveservice().addGallery(files);

      if (!mounted) return;
      _showSnack(
        success
            ? '${files.length} image${files.length > 1 ? 's' : ''} uploaded successfully'
            : 'Upload failed. Please try again.',
        isError: !success,
      );
      if (success) _loadData();
    } catch (e) {
      debugPrint('❌ Pick/upload error: $e');
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: isError ? AppTheme.accentRed : Colors.green.shade700,
      behavior       : SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Gallery'),
        actions: [
          if (isUploading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color      : AppTheme.primaryYellow,
                  ),
                ),
              ),
            ),
        ],
      ),

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryYellow))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Info banner ──────────────────────────────────────────
                Container(
                  margin : EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(16),
                    vertical  : FigmaSize.h(10),
                  ),
                  padding: EdgeInsets.all(FigmaSize.w(12)),
                  decoration: BoxDecoration(
                    color       : AppTheme.primaryYellow.withOpacity(
                        isDark ? 0.12 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border      : Border.all(
                      color: AppTheme.primaryYellow.withOpacity(0.40)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: c.subText),
                      SizedBox(width: FigmaSize.w(8)),
                      Expanded(
                        child: Text(
                          'Admin takes up to 7 days to approve the image. '
                          'Your images will be visible to customers when you enable at least 3 images.',
                          style: TextStyle(
                            fontSize  : FigmaSize.w(11),
                            fontWeight: FontWeight.w500,
                            color     : c.subText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tabs + grid ──────────────────────────────────────────
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : AppTheme.primaryYellow.withOpacity(0.10),
                          child: TabBar(
                            dividerColor         : Colors.transparent,
                            indicatorSize        : TabBarIndicatorSize.tab,
                            labelColor           : isDark
                                ? Colors.white
                                : Colors.black,
                            unselectedLabelColor : isDark
                                ? Colors.white38
                                : Colors.black54,
                            indicator: const UnderlineTabIndicator(
                              borderSide: BorderSide(
                                  color: AppTheme.primaryYellow, width: 2),
                            ),
                            tabs: const [
                              Tab(text: 'Profile Gallery'),
                              Tab(text: 'Live Event DP'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _GalleryGrid(
                                items      : data,
                                c          : c,
                                isDark     : isDark,
                                onRefresh  : _loadData,
                                onDelete   : _deleteImage,
                                onToggle   : _toggleImage,
                                onDeleteDone: _loadData,
                              ),
                              _GalleryGrid(
                                items      : data,
                                c          : c,
                                isDark     : isDark,
                                onRefresh  : _loadData,
                                onDelete   : _deleteImage,
                                onToggle   : _toggleImage,
                                onDeleteDone: _loadData,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // ── Upload button ────────────────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          FigmaSize.w(16),
          FigmaSize.h(8),
          FigmaSize.w(16),
          FigmaSize.h(20),
        ),
        child: GradientButton(
          title       : isUploading ? 'Uploading...' : '+ Upload Image',
          onTap       : isUploading ? () {} : _showPickerSheet,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GALLERY GRID
// ─────────────────────────────────────────────────────────────────
class _GalleryGrid extends StatelessWidget {
  final List<AstrologerGalleryItem>         items;
  final AppColors                           c;
  final bool                                isDark;
  final Future<void> Function()             onRefresh;
  final Future<bool> Function(String id)    onDelete;
  final Future<bool> Function(String, bool) onToggle;
  final VoidCallback                        onDeleteDone;

  const _GalleryGrid({
    required this.items,
    required this.c,
    required this.isDark,
    required this.onRefresh,
    required this.onDelete,
    required this.onToggle,
    required this.onDeleteDone,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined,
                size: 64, color: c.subText.withOpacity(0.35)),
            SizedBox(height: FigmaSize.h(12)),
            Text(
              "No images yet\nTap '+ Upload Image' to add",
              textAlign: TextAlign.center,
              style: TextStyle(color: c.subText, fontSize: FigmaSize.w(13)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color    : AppTheme.primaryYellow,
      child    : GridView.builder(
        padding: EdgeInsets.all(FigmaSize.w(12)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount  : 2,
          crossAxisSpacing: FigmaSize.w(12),
          mainAxisSpacing : FigmaSize.h(12),
          childAspectRatio: 0.72,
        ),
        itemCount  : items.length,
        itemBuilder: (_, i) => _GalleryCard(
          item        : items[i],
          c           : c,
          isDark      : isDark,
          onDelete    : onDelete,
          onToggle    : onToggle,
          onDeleteDone: onDeleteDone,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GALLERY CARD
// ─────────────────────────────────────────────────────────────────
class _GalleryCard extends StatefulWidget {
  final AstrologerGalleryItem               item;
  final AppColors                           c;
  final bool                                isDark;
  final Future<bool> Function(String id)    onDelete;
  final Future<bool> Function(String, bool) onToggle;
  final VoidCallback                        onDeleteDone;

  const _GalleryCard({
    required this.item,
    required this.c,
    required this.isDark,
    required this.onDelete,
    required this.onToggle,
    required this.onDeleteDone,
  });

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  bool _enabled   = true;
  bool _toggling  = false;
  bool _deleting  = false;

  @override
  Widget build(BuildContext context) {
    final c      = widget.c;
    final isDark = widget.isDark;

    return Container(
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: BorderRadius.circular(8),
        border      : Border.all(color: c.border),
        boxShadow   : isDark
            ? []
            : [
                BoxShadow(
                  color     : Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset    : const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Image ──────────────────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8)),
              child: widget.item.hasFile
                  ? Image.network(
                      widget.item.file,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color     : AppTheme.primaryYellow)),
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? c.toggleBg : Colors.grey.shade100,
                        child: Icon(Icons.broken_image_outlined,
                            color: c.subText),
                      ),
                    )
                  : Container(
                      color: isDark ? c.toggleBg : Colors.grey.shade100,
                      child: Icon(Icons.image_outlined, color: c.subText),
                    ),
            ),
          ),

          // ── Bottom actions ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(8),
              vertical  : FigmaSize.h(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Verified badge
                Row(
                  children: [
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize  : FigmaSize.w(11),
                        fontWeight: FontWeight.w500,
                        color     : c.text,
                      ),
                    ),
                    SizedBox(width: FigmaSize.w(3)),
                    const Icon(Icons.verified, size: 14, color: Colors.green),
                  ],
                ),

                // Toggle + delete
                Row(
                  children: [
                    // Toggle
                    _toggling
                        ? SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryYellow))
                        : CustomToggleSwitch(
                            height   : 18,
                            width    : 45,
                            value    : _enabled,
                            onChanged: (val) async {
                              setState(() => _toggling = true);
                              final ok = await widget.onToggle(
                                  widget.item.id, val);
                              setState(() {
                                if (ok) _enabled = val;
                                _toggling = false;
                              });
                            },
                          ),
                    SizedBox(width: FigmaSize.w(6)),

                    // Delete
                    _deleting
                        ? SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentRed))
                        : GestureDetector(
                            onTap: () => _confirmDelete(context),
                            child: SvgPicture.asset(
                              'assets/images/delete.svg',
                              height: FigmaSize.h(16),
                              width : FigmaSize.w(16),
                              colorFilter: ColorFilter.mode(
                                  AppTheme.accentRed, BlendMode.srcIn),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final c = widget.c;
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title  : Text('Delete Image?',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
        content: Text(
            'This image will be permanently removed from your gallery.',
            style: TextStyle(color: c.subText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : Text('Cancel',
                style: TextStyle(color: c.subText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child    : const Text('Delete',
                style: TextStyle(
                    color     : AppTheme.accentRed,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (yes != true || !context.mounted) return;
    setState(() => _deleting = true);
    final ok = await widget.onDelete(widget.item.id);
    if (!context.mounted) return;
    setState(() => _deleting = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(ok ? 'Image deleted' : 'Delete failed'),
      backgroundColor: ok ? Colors.green.shade700 : AppTheme.accentRed,
      behavior       : SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    if (ok) widget.onDeleteDone();
  }
}

// ─────────────────────────────────────────────────────────────────
// PICKER OPTION BUTTON
// ─────────────────────────────────────────────────────────────────
class _PickerOption extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final AppColors    c;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(20)),
        decoration: BoxDecoration(
          color       : AppTheme.primaryYellow.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(
              color: AppTheme.primaryYellow.withOpacity(0.40)),
        ),
        child: Column(
          children: [
            Icon(icon, size: FigmaSize.w(36), color: c.text),
            SizedBox(height: FigmaSize.h(8)),
            Text(
              label,
              style: TextStyle(
                fontSize  : FigmaSize.w(13),
                fontWeight: FontWeight.w600,
                color     : c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}