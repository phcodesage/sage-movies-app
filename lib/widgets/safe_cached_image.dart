import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SafeCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const SafeCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return errorWidget?.call(context, imageUrl, 'Invalid URL') ?? _defaultFallback();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      placeholder: placeholder ?? (context, url) => _defaultPlaceholder(),
      errorWidget: errorWidget ?? (context, url, error) => _defaultFallback(),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: const Color(0xFF1F1F23),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFE50914),
          ),
        ),
      ),
    );
  }

  Widget _defaultFallback() {
    return Container(
      color: const Color(0xFF1F1F23),
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: Colors.white24,
          size: 32,
        ),
      ),
    );
  }
}
