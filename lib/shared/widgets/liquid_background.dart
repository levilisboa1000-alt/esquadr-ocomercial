import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundStart,
                AppColors.backgroundEnd,
                AppColors.backgroundAccent,
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Glowing Liquid Blobs
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.actionUp.withOpacity(0.12),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purpleGlow.withOpacity(0.10),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: 50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.actionRight.withOpacity(0.08),
            ),
          ),
        ),

        // Blur overlay for smooth diffuse light
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: const SizedBox.expand(),
        ),

        // Foreground content
        child,
      ],
    );
  }
}
