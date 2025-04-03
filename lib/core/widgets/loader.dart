import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/themes/app_colors.dart';
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final double? dotWidth;
  final double? dotHeight;

  const TypingIndicator({
    super.key,
    this.dotWidth,
    this.dotHeight,
  });

  @override
  TypingIndicatorState createState() => TypingIndicatorState();
}

class TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 2), // Increased duration for slower animation
    )..repeat();

    _animation1 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );

    _animation2 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.8)), // Delayed fade-in
    );

    _animation3 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0)), // Further delayed fade-in
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _animation1,
          child: Dot(
            width: widget.dotWidth,
            height: widget.dotHeight,
          ),
        ),
        Constants.w4,
        FadeTransition(
          opacity: _animation2,
          child: Dot(
            width: widget.dotWidth,
            height: widget.dotHeight,
          ),
        ),
        Constants.w4,
        FadeTransition(
          opacity: _animation3,
          child: Dot(
            width: widget.dotWidth,
            height: widget.dotHeight,
          ),
        ),
      ],
    );
  }
}

class Dot extends StatelessWidget {
  final double? width;
  final double? height;

  const Dot({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 7.5,
      height: height ?? 7.5,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grey,
      ),
    );
  }
}
