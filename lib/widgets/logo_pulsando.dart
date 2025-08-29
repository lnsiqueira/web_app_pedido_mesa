import 'package:flutter/material.dart';

class PulsingLogo extends StatefulWidget {
  final double width;
  final String assetPath;
  final Duration duration;

  const PulsingLogo({
    Key? key,
    required this.assetPath,
    this.width = 150,
    this.duration = const Duration(seconds: 1),
  }) : super(key: key);

  @override
  _PulsingLogoState createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<PulsingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Image.asset(
        widget.assetPath,
        width: widget.width,
      ),
    );
  }
}
