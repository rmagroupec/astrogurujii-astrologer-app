import 'package:flutter/material.dart';
import '../../core/config/theme_config.dart';
import '../../core/utils/size_config.dart';

class DivinConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const DivinConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(FigmaSize.w(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: FigmaSize.w(16),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: FigmaSize.h(10)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: FigmaSize.w(13),
                color: Colors.black87,
              ),
            ),
            SizedBox(height: FigmaSize.h(20)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onNo,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "No",
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                SizedBox(width: FigmaSize.w(12)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onYes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Yes",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
