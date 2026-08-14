import 'package:flutter/material.dart';

class FloatingElement extends StatefulWidget {
  final Widget child;
  final double yOffset;
  final double rotation;
  final Duration duration;

  const FloatingElement({
    Key? key,
    required this.child,
    this.yOffset = 15.0,
    this.rotation = 0.05,
    this.duration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<FloatingElement> createState() => _FloatingElementState();
}

class _FloatingElementState extends State<FloatingElement> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _rotAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    
    _yAnimation = Tween<double>(begin: -widget.yOffset, end: widget.yOffset).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    
    _rotAnimation = Tween<double>(begin: -widget.rotation, end: widget.rotation).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            ..translate(0.0, _yAnimation.value, 0.0)
            ..rotateZ(_rotAnimation.value),
          child: widget.child,
        );
      },
    );
  }
}
