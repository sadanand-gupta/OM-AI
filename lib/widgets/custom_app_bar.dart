import 'package:flutter/material.dart';
import 'package:om_ai/screens/login_screen.dart';
import 'package:om_ai/screens/profile_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: App icon + OM AI text
            Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/Om_app_icon.webp',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: 'OM ',
                        style: TextStyle(color: Color(0xFF1A1A1A)),
                      ),
                      TextSpan(
                        text: 'AI',
                        style: TextStyle(color: Color(0xFF3F51B5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Right: Profile avatar with popup
            PopupMenuButton<String>(
              offset: const Offset(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.white,
              elevation: 6,
              shadowColor: const Color(0xFF2C3E50).withValues(alpha: 0.12),
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  );
                } else if (value == 'logout') {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 20,
                          color: const Color(0xFF2C3E50)
                              .withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          size: 20,
                          color: const Color(0xFFEF4444)
                              .withValues(alpha: 0.8)),
                      const SizedBox(width: 10),
                      const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Om_app_icon.webp',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
