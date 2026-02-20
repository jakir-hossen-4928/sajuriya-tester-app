import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sajuriyatester/core/widgets/skeleton_widgets.dart';

/// Displays an app icon with cache, shimmer loading, and fallback [Icons.apps].
class AppIconWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final Color? backgroundColor;

  const AppIconWidget({
    super.key,
    required this.imageUrl,
    this.size = 50,
    this.borderRadius = 12,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.indigo.withValues(alpha: 0.1);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => ImageSkeleton(
                  size: size,
                  borderRadius: borderRadius,
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.apps_rounded,
                    color: Colors.indigo,
                    size: size * 0.55,
                  ),
                ),
              )
            : Center(
                child: Icon(
                  Icons.apps_rounded,
                  color: Colors.indigo,
                  size: size * 0.55,
                ),
              ),
      ),
    );
  }
}

/// Displays a circular profile avatar with cache, shimmer loading,
/// and initial-letter fallback when no image is available.
class ProfileAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double radius;

  const ProfileAvatarWidget({
    super.key,
    required this.imageUrl,
    required this.displayName,
    this.radius = 55,
  });

  String get _initial =>
      displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'U';

  double get _size => radius * 2;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha: 0.1),
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    CircularImageSkeleton(size: _size),
                errorWidget: (context, url, error) =>
                    _buildInitial(primaryColor),
              )
            : _buildInitial(primaryColor),
      ),
    );
  }

  Widget _buildInitial(Color primaryColor) {
    return Center(
      child: Text(
        _initial,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
