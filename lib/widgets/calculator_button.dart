/*
 * File: lib/widgets/calculator_button.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/widgets/calculator_button.dart
 * Description: Glassmorphic calculator button widget with blur effect
 */

import 'package:flutter/material.dart';
import 'dart:ui';

class CalculatorButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const CalculatorButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Determine default colors from the theme if not provided
    final buttonTextColor = textColor ?? Colors.white;
    // The background color is now a gradient on the container, so backgroundColor is not used directly.

    return Padding(
      padding: const EdgeInsets.all(4.0),
      // Use ClipRRect to contain the BackdropFilter effect
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          // This creates the frosted glass blur effect
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              // The semi-transparent gradient gives the glass look
              gradient: LinearGradient(
                colors: [
                  backgroundColor?.withOpacity(0.25) ?? Colors.white.withOpacity(0.25),
                  backgroundColor?.withOpacity(0.1) ?? Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              // A subtle border to define the button's edge
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                // The ripple effect will be contained by the rounded border
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.05),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize ?? 22,
                        color: buttonTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}