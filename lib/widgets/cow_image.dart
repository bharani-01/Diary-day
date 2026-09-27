import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants.dart';

/// Network cow photo backed by an on-disk cache and decoded at display size, so scrolling
/// never re-downloads photos that were evicted from the in-memory image cache.
class CowImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double placeholderIconSize;

  const CowImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) return _placeholder(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final logicalWidth = width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : null);
        final cacheWidth = logicalWidth != null && logicalWidth.isFinite
            ? (logicalWidth * dpr).round()
            : null;

        return CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: cacheWidth,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (context, _) => _loading(context),
          errorWidget: (context, _, __) => _error(context),
        );
      },
    );
  }

  Widget _loading(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _error(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).cardColor,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: placeholderIconSize * 0.6),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppConstants.primaryColor.withOpacity(0.08),
      alignment: Alignment.center,
      child: Icon(Icons.pets, size: placeholderIconSize, color: AppConstants.primaryColor.withOpacity(0.3)),
    );
  }
}
