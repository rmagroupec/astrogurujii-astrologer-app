import 'dart:io';

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/CustomSwitchButton.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:astrologer_app/model/AstrologerGalleryModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:astrologer_app/service/liveService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load gallery ──────────────────────────────────────────────
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

  // ── Show camera / gallery picker ──────────────────────────────
  Future<void> _showPickerSheet() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: FigmaSize.w(20),
            vertical: FigmaSize.h(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: FigmaSize.h(20)),
              Text(
                "Upload Image",
                style: TextStyle(
                  fontSize: FigmaSize.w(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: FigmaSize.h(20)),
              Row(
                children: [
                  Expanded(
                    child: _PickerOption(
                      icon:  Icons.camera_alt_outlined,
                      label: "Camera",
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUpload(ImageSource.camera);
                      },
                    ),
                  ),
                  SizedBox(width: FigmaSize.w(16)),
                  Expanded(
                    child: _PickerOption(
                      icon:  Icons.photo_library_outlined,
                      label: "Gallery",
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
    );
  }

  // ── Pick images and upload ────────────────────────────────────
  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      List<XFile> picked = [];

      if (source == ImageSource.gallery) {
        // multiple from gallery
        picked = await _picker.pickMultiImage(imageQuality: 80);
      } else {
        // single from camera
        final img = await _picker.pickImage(
          source:       ImageSource.camera,
          imageQuality: 80,
        );
        if (img != null) picked = [img];
      }

      if (picked.isEmpty) return;

      setState(() => isUploading = true);

      final files = picked.map((x) => File(x.path)).toList();
      final success = await Liveservice().addGallery(files);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          success
              ? '${files.length} image${files.length > 1 ? 's' : ''} uploaded successfully'
              : 'Upload failed. Please try again.',
        ),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

      if (success) _loadData(); // refresh grid
    } catch (e) {
      debugPrint('❌ Pick/upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gallery"),
        backgroundColor: const Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
        actions: [
          if (isUploading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Info banner ──────────────────────────────
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(16),
                    vertical:   FigmaSize.h(10),
                  ),
                  padding: EdgeInsets.all(FigmaSize.w(12)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD417).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFFCD417).withOpacity(0.40)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.black54),
                      SizedBox(width: FigmaSize.w(8)),
                      Expanded(
                        child: Text(
                          "Admin takes up to 7 days to approve the image. "
                          "Your images will be visible to customers when you enable at least 3 images.",
                          style: TextStyle(
                            fontSize:   FigmaSize.w(11),
                            fontWeight: FontWeight.w500,
                            color:      Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tabs + grid ──────────────────────────────
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          color: const Color(0xFFFCD417).withOpacity(0.10),
                          child: TabBar(
                            dividerColor:        Colors.transparent,
                            indicatorSize:       TabBarIndicatorSize.tab,
                            labelColor:          Colors.black,
                            unselectedLabelColor: Colors.black54,
                            indicator: const UnderlineTabIndicator(
                              borderSide: BorderSide(
                                color: Color(0xFFFCD417),
                                width: 2,
                              ),
                            ),
                            tabs: const [
                              Tab(text: "Profile Gallery"),
                              Tab(text: "Live Event DP"),
                            ],
                          ),
                        ),

                        Expanded(
                          child: TabBarView(
                            children: [
                              _GalleryGrid(
                                items:    data,
                                onDelete: _loadData,
                              ),
                              _GalleryGrid(
                                items:    data,
                                onDelete: _loadData,
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

      // ── Upload button ────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          FigmaSize.w(16),
          FigmaSize.h(8),
          FigmaSize.w(16),
          FigmaSize.h(20),
        ),
        child: GradientButton(
          title: isUploading ? "Uploading..." : "+ Upload Image",
          onTap:  isUploading ? () {} : _showPickerSheet,
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
  final List<AstrologerGalleryItem> items;
  final VoidCallback onDelete;

  const _GalleryGrid({required this.items, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade300),
            SizedBox(height: FigmaSize.h(12)),
            Text(
              "No images yet\nTap '+ Upload Image' to add",
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    Colors.grey,
                fontSize: FigmaSize.w(13),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onDelete(),
      child: GridView.builder(
        padding: EdgeInsets.all(FigmaSize.w(12)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:    2,
          crossAxisSpacing:  FigmaSize.w(12),
          mainAxisSpacing:   FigmaSize.h(12),
          childAspectRatio:  0.72,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _GalleryCard(item: items[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GALLERY CARD
// ─────────────────────────────────────────────────────────────────
class _GalleryCard extends StatefulWidget {
  final AstrologerGalleryItem item;
  const _GalleryCard({required this.item});

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Image ──────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8)),
              child: widget.item.hasFile
                  ? Image.network(
                      widget.item.file,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_outlined,
                          color: Colors.grey),
                    ),
            ),
          ),

          // ── Bottom actions ──────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(8),
              vertical:   FigmaSize.h(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Verified badge
                Row(
                  children: [
                    Text(
                      "Verified",
                      style: TextStyle(
                        fontSize:   FigmaSize.w(11),
                        fontWeight: FontWeight.w500,
                        color:      Colors.black87,
                      ),
                    ),
                    SizedBox(width: FigmaSize.w(3)),
                    const Icon(Icons.verified, size: 14, color: Colors.green),
                  ],
                ),

                // Toggle + delete
                Row(
                  children: [
                    CustomToggleSwitch(
                      height: 18,
                      width:  45,
                      value:  _enabled,
                      onChanged: (val) => setState(() => _enabled = val),
                    ),
                    SizedBox(width: FigmaSize.w(6)),
                    GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: SvgPicture.asset(
                        "assets/images/delete.svg",
                        height: FigmaSize.h(16),
                        width:  FigmaSize.w(16),
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
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Image?"),
        content: const Text(
            "This image will be permanently removed from your gallery."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    // delete API can be wired here once backend exposes it
    if (yes == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Delete API not yet available from backend"),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// PICKER OPTION BUTTON
// ─────────────────────────────────────────────────────────────────
class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(20)),
        decoration: BoxDecoration(
          color: const Color(0xFFFCD417).withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFCD417).withOpacity(0.40)),
        ),
        child: Column(
          children: [
            Icon(icon, size: FigmaSize.w(36), color: Colors.black87),
            SizedBox(height: FigmaSize.h(8)),
            Text(
              label,
              style: TextStyle(
                fontSize:   FigmaSize.w(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}