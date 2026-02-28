import 'package:flutter/material.dart';

void showAppearanceDialog(BuildContext context, Color themeColor) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A2C23),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your preferred theme',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Light Mode Option
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: themeColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: themeColor.withOpacity(0.05),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4), // Light yellow
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wb_sunny, color: Color(0xFFFBC02D), size: 24),
                  ),
                  title: const Text(
                    'Light Mode',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Bright and clear'),
                  trailing: Icon(Icons.check_circle, color: themeColor, size: 28),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Dark Mode Option (Disabled)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: ListTile(
                  enabled: false,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.nightlight_round, color: Colors.grey, size: 24),
                  ),
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  subtitle: Text(
                    'Easy on the eyes',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Coming Soon Message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), // Light blue
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Color(0xFF1976D2), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dark mode feature coming soon!',
                        style: TextStyle(
                          color: Color(0xFF1976D2),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
