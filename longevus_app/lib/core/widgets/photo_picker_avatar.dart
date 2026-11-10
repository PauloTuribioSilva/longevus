import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PhotoPickerAvatar extends StatelessWidget {
  final String? currentPhotoUrl;
  final Uint8List? selectedImageBytes;
  final VoidCallback onTapPick;
  final IconData fallbackIcon;
  final double radius;
  final bool isCircle;

  const PhotoPickerAvatar({
    super.key,
    this.currentPhotoUrl,
    this.selectedImageBytes,
    required this.onTapPick,
    this.fallbackIcon = Icons.person,
    this.radius = 52,
    this.isCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (selectedImageBytes != null) {
      imageProvider = MemoryImage(selectedImageBytes!);
    } else if (currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(currentPhotoUrl!);
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primary, width: 2),
              image: imageProvider != null
                  ? DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageProvider == null
                ? Icon(
                    fallbackIcon,
                    size: radius * 0.9,
                    color: AppTheme.primary,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: AppTheme.primary,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                onTap: onTapPick,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}