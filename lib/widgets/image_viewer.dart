import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'image_donwload_helper.dart';

class FullScreenImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String? title;
  final Object heroTag; // 👈 for smooth transition

  const FullScreenImageViewer({
    Key? key,
    required this.imageBytes,
    this.title,
    required this.heroTag,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  double _rotationAngle = 0.0;
  bool _showControls = true;
  bool _isDownloading = false;


  @override
  void initState() {
    super.initState();

    // ✅ Delay system UI changes until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    // ✅ Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // ✅ Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      await ImageDownloadHelper.downloadImage(widget.imageBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image downloaded successfully'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download image'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }


  void _rotateImage() {
    setState(() {
      _rotationAngle += 1.5708; // 90 degrees
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // behavior: HitTestBehavior.opaque,
        behavior: HitTestBehavior.translucent,
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✅ FULLSCREEN IMAGE WITH HERO
            SizedBox.expand(
              child: Hero(
                tag: widget.heroTag,
                transitionOnUserGestures: true,
                child: Material(
                  color: Colors.transparent,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: Transform.rotate(
                      angle: _rotationAngle,
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 🔄 ROTATE BUTTON (BOTTOM CENTER)
            Positioned(
              bottom: 24,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: GestureDetector(
                  onTap: _rotateImage,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.rotate_right,
                      color: Colors.white,
                      size: 32,
                    ),

                  ),
                ),
              ),
            ),

// ⬇️ DOWNLOAD BUTTON (TOP-LEFT)
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: IconButton(
                    onPressed: _downloadImage,
                    icon: _isDownloading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
