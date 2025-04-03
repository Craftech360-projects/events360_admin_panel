import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String placeholderImage;
  final double radius;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.placeholderImage,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl!) as ImageProvider
          : AssetImage(placeholderImage),
      onBackgroundImageError: imageUrl != null && imageUrl!.isNotEmpty
          ? (_, __) {
              // Handle network image loading error
            }
          : null,
    );
  }
}
