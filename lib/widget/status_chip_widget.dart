import 'package:flutter/material.dart';

class StatusChipWidget extends StatelessWidget {
  final DateTime? licenseExpiryDate;
  const StatusChipWidget({super.key, this.licenseExpiryDate});

  @override
  Widget build(BuildContext context) {
    final bool isActive;
    if (licenseExpiryDate != null) {
      isActive = licenseExpiryDate!.isAfter(DateTime.now());
    } else {
      isActive = false;
    }
    final chipColor = isActive ? Colors.green.shade100 : Colors.red.shade100;
    final chipTextColor = isActive
        ? Colors.green.shade900
        : Colors.red.shade900;
    final chipLabel = isActive ? 'ACTIVE' : 'INACTIVE';

    return Container(
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Text(
          chipLabel,
          style: TextStyle(
            color: chipTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
