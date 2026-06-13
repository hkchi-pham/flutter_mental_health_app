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

  bool get _isDying => widget.tree.health > 0 && widget.tree.health <= 20;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = treeAssetPath(
      widget.tree.type,
      widget.tree.level,
      widget.tree.health,
    );

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
          // Whole-tree tap target — any tap inside displayWidth × displayHeight
          // opens the context overlay. The old narrow trunk-base diamond made
          // canopy taps fall through to the background. tapTarget* params are
          // kept on the widget API for back-compat but no longer scope hits.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}
