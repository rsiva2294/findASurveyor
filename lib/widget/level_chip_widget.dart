import 'package:flutter/material.dart';

class LevelChipWidget extends StatelessWidget {
  final String? level;

  const LevelChipWidget({super.key, this.level});

  @override
  Widget build(BuildContext context) {
    // Return an empty space if there's no level to display.
    if (level == null || level!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine the styles based on the level.
    switch (level) {
      case 'Fellow':
        return _buildGradientChip(
          label: 'FELLOW',
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFFFD700)], // Rich Gold
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          backgroundColor: const Color(0xFFFFF8E1), // Light Amber/Cream
          textColor: const Color(0xFF8D6E63),       // Brownish Gold
        );

      case 'Associate':
        return _buildGradientChip(
          label: 'ASSOCIATE',
          gradient: const LinearGradient(
            colors: [Color(0xFFB0B0B0), Color(0xFFE0E0E0)], // Silver
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          backgroundColor: const Color(0xFFF5F5F5), // Very light grey
          textColor: const Color(0xFF616161),       // Dark grey
        );

      case 'Licentiate':
        return _buildGradientChip(
          label: 'LICENTIATE',
          gradient: const LinearGradient(
            colors: [Color(0xFF8C7853), Color(0xFFCD7F32)], // Bronze
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          backgroundColor: const Color(0xFFF5EFE6), // Light Tan/Beige
          textColor: const Color(0xFF6D4C41),       // Dark Brown
        );

      default:
      // If the level string is something unexpected, display nothing.
        return const SizedBox.shrink();
    }
  }

  // Helper method to build the chip with a gradient border.
  Widget _buildGradientChip({
    required String label,
    required Gradient gradient,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}