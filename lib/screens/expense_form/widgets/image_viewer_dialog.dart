import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/theme/app_text_styles.dart';

class ImageViewerDialog extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final ImageProvider Function(String)? getImageProvider;
  final bool Function(String)? isBillFileMissing;

  const ImageViewerDialog({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
    this.getImageProvider,
    this.isBillFileMissing,
  });

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformationControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    _transformationControllers.clear();
    _pageController.dispose();
    super.dispose();
  }

  TransformationController _getControllerForIndex(int index) {
    if (!_transformationControllers.containsKey(index)) {
      _transformationControllers[index] = TransformationController();
    }
    return _transformationControllers[index]!;
  }

  bool _isMissing(String path) {
    if (widget.isBillFileMissing != null) {
      return widget.isBillFileMissing!(path);
    }
    return !kIsWeb &&
        path.isNotEmpty &&
        !path.startsWith('http') &&
        !File(path).existsSync();
  }

  ImageProvider _getProvider(String path) {
    if (widget.getImageProvider != null) {
      return widget.getImageProvider!(path);
    }
    if (kIsWeb) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image viewer with PageView for swiping
          PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final path = widget.imagePaths[index];

              if (_isMissing(path)) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppDesign.surfaceElevatedOf(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64,
                          color: AppDesign.textTertiaryOf(context),
                        ),
                        const Gap(12),
                        Text(
                          'Image no longer available',
                          style: AppTextStyles.bodyMediumOf(context),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Center(
                child: InteractiveViewer(
                  transformationController: _getControllerForIndex(index),
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Image(
                    image: _getProvider(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppDesign.surfaceElevatedOf(context),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: AppDesign.textTertiaryOf(context),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Close button - top right with safe area padding
          Positioned(
            top: safePadding.top + 8,
            right: 16,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ),
          ),

          // Image counter - bottom center (only if multiple images)
          if (widget.imagePaths.length > 1)
            Positioned(
              bottom: safePadding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imagePaths.length}',
                    style: AppTextStyles.bodyMediumOf(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
