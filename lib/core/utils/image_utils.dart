/// Enterprise-level Asset & Image Utilities
/// Handles image loading, caching, and error handling across all platforms
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Asset path constants
class AssetPaths {
  AssetPaths._();

  // Base paths
  static const String _assetsBase = 'assets';
  static const String _imagesBase = '$_assetsBase/images';
  static const String iconsBase = '$_assetsBase/icons';
  static const String _langBase = '$_assetsBase/lang';

  // App logos
  static const String logo = '$_imagesBase/logo1.png';
  static const String logoLight = '$_imagesBase/logo_light.png';
  static const String logoDark = '$_imagesBase/logo_dark.png';

  // Social/Auth logos
  static const String googleLogo = '$_imagesBase/google_logo.png';

  // Placeholders
  static const String placeholderUser = '$_imagesBase/placeholder_user.png';
  static const String placeholderImage = '$_imagesBase/placeholder.png';

  // Language files
  static String langFile(String code) => '$_langBase/$code.json';
}

/// Image loading widget with error handling and placeholder support
class SafeImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const SafeImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  });

  /// Create from network URL
  const SafeImage.network({
    super.key,
    required String url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  }) : imagePath = url;

  /// Create from asset path
  const SafeImage.asset({
    super.key,
    required String assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  }) : imagePath = assetPath;

  /// Create from file path
  const SafeImage.file({
    super.key,
    required String filePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  }) : imagePath = filePath;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imagePath == null || imagePath!.isEmpty) {
      imageWidget = _buildPlaceholder();
    } else if (_isNetworkImage(imagePath!)) {
      imageWidget = _buildNetworkImage();
    } else if (_isAssetImage(imagePath!)) {
      imageWidget = _buildAssetImage();
    } else {
      imageWidget = _buildFileImage();
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: imageWidget,
    );
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool _isAssetImage(String path) {
    return path.startsWith('assets/') || path.startsWith('asset://');
  }

  Widget _buildNetworkImage() {
    return Image.network(
      imagePath!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingIndicator(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Network image error: $error');
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildAssetImage() {
    final assetPath = imagePath!.replaceFirst('asset://', '');
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Asset image error: $error for path: $assetPath');
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildFileImage() {
    // On web, file images need special handling
    if (kIsWeb) {
      return _buildErrorWidget();
    }

    final file = File(imagePath!);
    if (!file.existsSync()) {
      return _buildErrorWidget();
    }

    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('File image error: $error');
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded /
            loadingProgress.expectedTotalBytes!
        : null;

    return Center(
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ?? _defaultPlaceholder();
  }

  Widget _buildErrorWidget() {
    return errorWidget ?? _defaultErrorWidget();
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey.shade400,
        size: (width ?? height ?? 48) * 0.4,
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.grey.shade400,
        size: (width ?? height ?? 48) * 0.4,
      ),
    );
  }
}

/// User avatar widget with fallback to initials
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? filePath;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.filePath,
    this.name,
    this.size = 48,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor.withAlpha(51);
    final fgColor = foregroundColor ?? theme.primaryColor;

    Widget avatar;

    // Try to load image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = _buildImageAvatar(imageUrl!, isNetwork: true);
    } else if (filePath != null && filePath!.isNotEmpty) {
      avatar = _buildImageAvatar(filePath!, isNetwork: false);
    } else {
      avatar = _buildInitialsAvatar(bgColor, fgColor);
    }

    // Add edit badge if needed
    if (showEditBadge) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.edit,
                color: Colors.white,
                size: size * 0.25,
              ),
            ),
          ),
        ],
      );
    }

    // Make tappable if callback provided
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: avatar,
    );
  }

  Widget _buildImageAvatar(String path, {required bool isNetwork}) {
    return ClipOval(
      child: isNetwork
          ? Image.network(
              path,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildInitialsAvatar(
                  Colors.grey.shade200,
                  Colors.grey.shade600,
                );
              },
            )
          : kIsWeb
              ? _buildInitialsAvatar(
                  Colors.grey.shade200,
                  Colors.grey.shade600,
                )
              : Image.file(
                  File(path),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitialsAvatar(
                      Colors.grey.shade200,
                      Colors.grey.shade600,
                    );
                  },
                ),
    );
  }

  Widget _buildInitialsAvatar(Color bgColor, Color fgColor) {
    final initials = _getInitials(name ?? '');

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: fgColor,
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
              ),
            )
          : Icon(
              Icons.person,
              color: fgColor,
              size: size * 0.5,
            ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';

    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

/// Platform-aware image picker helper
class ImagePickerHelper {
  ImagePickerHelper._();

  /// Check if image picking is supported on current platform
  static bool get isSupported {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if camera is available
  static bool get isCameraAvailable {
    if (kIsWeb) return true; // Web can access camera through browser API
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get platform-specific image source options
  static List<ImageSourceOption> getAvailableOptions() {
    final options = <ImageSourceOption>[];

    if (isCameraAvailable) {
      options.add(ImageSourceOption.camera);
    }
    options.add(ImageSourceOption.gallery);

    return options;
  }
}

/// Image source options
enum ImageSourceOption {
  camera,
  gallery,
}

extension ImageSourceOptionExtension on ImageSourceOption {
  String get label {
    switch (this) {
      case ImageSourceOption.camera:
        return 'Take Photo';
      case ImageSourceOption.gallery:
        return 'Choose from Gallery';
    }
  }

  IconData get icon {
    switch (this) {
      case ImageSourceOption.camera:
        return Icons.camera_alt_rounded;
      case ImageSourceOption.gallery:
        return Icons.photo_library_rounded;
    }
  }
}

/// Static utility class for common image operations
class ImageUtils {
  ImageUtils._();

  /// Build a profile image with cross-platform support
  static Widget buildProfileImage({
    String? imagePath,
    String? imageUrl,
    double radius = 45,
    Color? backgroundColor,
    Widget? placeholder,
    bool showEditBadge = false,
    VoidCallback? onTap,
  }) {
    ImageProvider? imageProvider;

    // Determine the image provider based on the path/url
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    } else if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        imageProvider = NetworkImage(imagePath);
      } else if (!kIsWeb) {
        // Only use FileImage on non-web platforms
        final file = File(imagePath);
        if (file.existsSync()) {
          imageProvider = FileImage(file);
        }
      }
    }

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey.shade300,
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider != null
          ? (exception, stackTrace) {
              debugPrint('Profile image error: $exception');
            }
          : null,
      child: imageProvider == null
          ? (placeholder ??
              Icon(
                Icons.person_rounded,
                size: radius,
                color: Colors.white,
              ))
          : null,
    );

    if (showEditBadge && onTap != null) {
      avatar = Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: radius * 0.35,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null && !showEditBadge) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  /// Check if an image path is valid and accessible
  static bool isValidImagePath(String? path) {
    if (path == null || path.isEmpty) return false;

    // Network URLs are always potentially valid
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return true;
    }

    // On web, local files are not directly accessible
    if (kIsWeb) return false;

    // Check if file exists
    try {
      return File(path).existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Get image provider from path with error handling
  static ImageProvider? getImageProvider(String? path) {
    if (path == null || path.isEmpty) return null;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }

    if (!kIsWeb) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (e) {
        debugPrint('Error getting image provider: $e');
      }
    }

    return null;
  }
}
