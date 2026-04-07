import 'dart:math';
import 'package:flutter/material.dart';

class SecurityWatermark extends StatefulWidget {
  final String userId;
  final String? ipAddress;
  final Widget child;

  const SecurityWatermark({
    super.key,
    required this.userId,
    this.ipAddress,
    required this.child,
  });

  @override
  State<SecurityWatermark> createState() => _SecurityWatermarkState();
}

class _SecurityWatermarkState extends State<SecurityWatermark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  final Random _random = Random();
  Offset _currentPos = Offset.zero;
  Offset _targetPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _generateNextPosition();
      }
    });

    _generateNextPosition();
  }

  void _generateNextPosition() {
    _currentPos = _targetPos;
    // Generate a random position in percentage (0.0 to 0.8 to keep it within view)
    _targetPos = Offset(
      _random.nextDouble() * 0.7,
      _random.nextDouble() * 0.7,
    );

    _animation = Tween<Offset>(
      begin: _currentPos,
      end: _targetPos,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                   // Dynamic moving watermark
                  Positioned(
                    left: _animation.value.dx * MediaQuery.of(context).size.width,
                    top: _animation.value.dy * MediaQuery.of(context).size.height,
                    child: _WatermarkText(
                      text: 'USER: ${widget.userId}\nIP: ${widget.ipAddress ?? "0.0.0.0"}',
                      opacity: 0.08,
                    ),
                  ),
                  // Fixed background grid pattern (subtle)
                  ..._buildGridWatermarks(context),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGridWatermarks(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final List<Widget> items = [];
    const int rows = 5;
    const int cols = 4;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        items.add(
          Positioned(
            left: (j * size.width / cols) + 20,
            top: (i * size.height / rows) + 20,
            child: Transform.rotate(
              angle: -pi / 4,
              child: _WatermarkText(
                text: widget.userId,
                opacity: 0.03,
              ),
            ),
          ),
        );
      }
    }
    return items;
  }
}

class _WatermarkText extends StatelessWidget {
  final String text;
  final double opacity;

  const _WatermarkText({
    required this.text,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.black.withValues(alpha: opacity),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }
}
