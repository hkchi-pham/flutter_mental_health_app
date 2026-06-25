import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../shared/models/garden_model.dart';

class TreeWidget extends StatefulWidget {
  final Tree tree;
  final double displayHeight;
  final double displayWidth;
  final VoidCallback onTap;
  final double tapTargetWidth;
  final double tapTargetHeight;
  final double trunkBaseYFrac;

  const TreeWidget({
    super.key,
    required this.tree,
    required this.displayHeight,
    required this.displayWidth,
    required this.onTap,
    required this.tapTargetWidth,
    required this.tapTargetHeight,
    required this.trunkBaseYFrac,
  });

  @override
  State<TreeWidget> createState() => _TreeWidgetState();
}

class _TreeWidgetState extends State<TreeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  // Decoded alpha channel of the current asset, for per-pixel hit-testing.
  Uint8List? _rgba;
  int _imgW = 0;
  int _imgH = 0;
  String? _alphaAsset; // asset whose alpha is currently loaded / loading
  ImageStream? _imageStream;
  ImageStreamListener? _streamListener;

  bool get _isDying => widget.tree.health > 0 && widget.tree.health <= 20;

  String get _currentAsset =>
      treeAssetPath(widget.tree.type, widget.tree.level, widget.tree.health);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_isDying) {
      _pulseController.repeat(reverse: true);
    }
    _loadAlpha(_currentAsset);
  }

  @override
  void didUpdateWidget(covariant TreeWidget old) {
    super.didUpdateWidget(old);
    final dying = _isDying;
    final wasDying = old.tree.health > 0 && old.tree.health <= 20;
    if (dying && !wasDying) {
      _pulseController.repeat(reverse: true);
    } else if (!dying && wasDying) {
      _pulseController.stop();
      _pulseController.value = 0.0; // reset _pulseScale to begin (1.0)
    }
    // Reload alpha if the asset changed (level/health bucket swap).
    if (_currentAsset != _alphaAsset) {
      _loadAlpha(_currentAsset);
    }
  }

  /// Decodes [asset] and keeps its raw RGBA bytes so [_AlphaMask] can sample the
  /// alpha channel during hit-testing. Until the bytes arrive the mask behaves
  /// as fully opaque (whole-rect tappable) so taps are never lost.
  void _loadAlpha(String asset) {
    _alphaAsset = asset;
    _detachStream();
    final stream = AssetImage(asset).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) async {
      final image = info.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (!mounted || data == null) return;
      // Ignore late callbacks for a stale asset.
      if (asset != _alphaAsset) return;
      setState(() {
        _rgba = data.buffer.asUint8List();
        _imgW = image.width;
        _imgH = image.height;
      });
    });
    _imageStream = stream;
    _streamListener = listener;
    stream.addListener(listener);
  }

  void _detachStream() {
    if (_imageStream != null && _streamListener != null) {
      _imageStream!.removeListener(_streamListener!);
    }
    _imageStream = null;
    _streamListener = null;
  }

  @override
  void dispose() {
    _detachStream();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _currentAsset;

    return SizedBox(
      width: widget.displayWidth,
      height: widget.displayHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ScaleTransition(
                scale: _pulseScale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  width: widget.displayWidth,
                  height: widget.displayHeight,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: Image.asset(
                      asset,
                      key: ValueKey<String>(asset),
                      width: widget.displayWidth,
                      height: widget.displayHeight,
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) => SizedBox(
                        width: widget.displayWidth,
                        height: widget.displayHeight,
                        child: const Center(
                          child: Text('🌳', style: TextStyle(fontSize: 32)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Per-pixel tap target: a tap only registers on OPAQUE pixels of the
          // tree sprite. Taps on the transparent canopy corners fall through to
          // whatever sits behind (another tree, or the grid), so a large tree
          // no longer blocks taps to a smaller plant behind it. Any opaque part
          // of the canopy/trunk remains tappable.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: widget.onTap,
              child: _AlphaMask(rgba: _rgba, imgW: _imgW, imgH: _imgH),
            ),
          ),
        ],
      ),
    );
  }
}

/// A leaf render box that reports a hit only where the source sprite's alpha
/// is above [_kAlphaThreshold]. Used so transparent regions of a tree fall
/// through to widgets painted behind it.
class _AlphaMask extends LeafRenderObjectWidget {
  final Uint8List? rgba;
  final int imgW;
  final int imgH;

  const _AlphaMask({required this.rgba, required this.imgW, required this.imgH});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _AlphaMaskRender(rgba, imgW, imgH);

  @override
  void updateRenderObject(BuildContext context, _AlphaMaskRender renderObject) {
    renderObject
      ..rgba = rgba
      ..imgW = imgW
      ..imgH = imgH;
  }
}

/// Alpha below this (0-255) is treated as transparent / non-tappable.
const int _kAlphaThreshold = 12;

class _AlphaMaskRender extends RenderBox {
  Uint8List? rgba;
  int imgW;
  int imgH;

  _AlphaMaskRender(this.rgba, this.imgW, this.imgH);

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  bool hitTestSelf(Offset position) {
    final data = rgba;
    // Not decoded yet → behave as opaque so the tap is never lost.
    if (data == null || imgW == 0 || imgH == 0) return true;
    if (size.width <= 0 || size.height <= 0) return false;

    final px = (position.dx / size.width * imgW).floor().clamp(0, imgW - 1);
    final py = (position.dy / size.height * imgH).floor().clamp(0, imgH - 1);
    final idx = (py * imgW + px) * 4 + 3; // alpha byte in RGBA
    if (idx < 0 || idx >= data.length) return true;
    return data[idx] > _kAlphaThreshold;
  }
}
