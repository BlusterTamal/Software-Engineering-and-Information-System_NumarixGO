/*
 * File: lib/widgets/feature_card.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/widgets/feature_card.dart
 * Description: Reusable feature card widget for dashboard
 */

import 'dart:ui';
import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget page;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    // --- FIX: Determine content color based on the app's theme ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Use white text for dark mode, and a dark grey text for light mode
    final contentColor = isDarkMode ? Colors.white : Colors.black87;
    // Adjust shadow color for better visibility in both themes
    final shadowColor = isDarkMode ? Colors.black54 : Colors.grey.withOpacity(0.4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.5),
                  color.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- FIX: Use the dynamic contentColor for the icon ---
                Icon(icon, size: 48, color: contentColor),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // --- FIX: Use the dynamic contentColor for the text ---
                    color: contentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        // --- FIX: Use the dynamic shadowColor ---
                        color: shadowColor,
                        offset: const Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}