import 'package:flutter/material.dart';

class Parallax3DObject extends StatefulWidget {
  final Widget child;
  final double depth;
  final double maxRotation;

  const Parallax3DObject({
    Key? key,
    required this.child,
    this.depth = 50.0,
    this.maxRotation = 0.1,
  }) : super(key: key);

  @override
  State<Parallax3DObject> createState() => _Parallax3DObjectState();
}

class _Parallax3DObjectState extends State<Parallax3DObject> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateOffset(PointerEvent event) {
    if (!mounted) return;
    final size = context.size;
    if (size == null) return;

    // Normalize from -1 to 1 based on center of object
    final x = (event.localPosition.dx / size.width) * 2 - 1;
    final y = (event.localPosition.dy / size.height) * 2 - 1;

    final targetOffset = Offset(x, y);

    _animation = Tween<Offset>(
      begin: _animation.value,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward(from: 0);
  }

  void _resetOffset() {
    if (!mounted) return;
    _animation = Tween<Offset>(
      begin: _animation.value,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _updateOffset,
      onExit: (_) => _resetOffset(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = _animation.value;
          
          return Transform(
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(-offset.dy * widget.maxRotation)
              ..rotateY(offset.dx * widget.maxRotation)
              ..multiply(Matrix4.translationValues(
                (offset.dx * widget.depth).toDouble(),
                (offset.dy * widget.depth).toDouble(),
                0.0,
              )),
            child: widget.child,
          );
        },
      ),
    );
  }
}
