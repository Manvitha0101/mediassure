
import 'package:flutter/material.dart';

import '../../screens/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.email,
    required this.onLogout,
  });

  final String email;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName(email);
    final initials  = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(initials: initials),
          const SizedBox(width: 14),
          Expanded(child: _Greeting(firstName: firstName, email: email)),
          _LogoutButton(onLogout: onLogout),
        ],
      ),
    );
  }

  String _firstName(String email) {
    final raw = email.contains('@') ? email.split('@').first : email;
    return raw.isNotEmpty ? raw[0].toUpperCase() + raw.substring(1) : raw;
  }
}

// ─── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF7B8FF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

// ─── Greeting ─────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName, required this.email});
  final String firstName;
  final String email;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back,', style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            firstName,
            style: AppTextStyles.headingLarge,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            email,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
}

// ─── Logout Button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onLogout,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: AppColors.danger,
            size: 20,
          ),
        ),
      );
}