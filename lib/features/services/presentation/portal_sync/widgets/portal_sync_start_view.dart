import 'package:flutter/material.dart';

class PortalSyncStartView extends StatelessWidget {
  final TextEditingController studentIdController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscurePassword;
  final String? errorMessage;
  final VoidCallback onStartSync;
  final List<Map<String, dynamic>> availableSemesters;
  final Map<String, dynamic>? selectedSemester;
  final ValueChanged<Map<String, dynamic>?> onSelectSemester;
  final bool rememberCredentials;
  final ValueChanged<bool> onToggleRememberCredentials;

  const PortalSyncStartView({
    super.key,
    required this.studentIdController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscurePassword,
    required this.errorMessage,
    required this.onStartSync,
    this.availableSemesters = const [],
    this.selectedSemester,
    required this.onSelectSemester,
    required this.rememberCredentials,
    required this.onToggleRememberCredentials,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('start_sync'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero EWU Building Graphic Box
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF071B36), Color(0xFF0F325E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x3319D9F5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF19D9F5).withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 160,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF19D9F5).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFF19D9F5), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.cloud_sync_rounded,
                          color: Color(0xFF19D9F5),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "EAST WEST UNIVERSITY",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: Color(0xFF19D9F5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title & Subtitle
          const Text(
            "Connect Your\nEWU Portal",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Fetch your routine, faculty, room numbers and academic history directly from portal.ewubd.edu",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Semester Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Semester to Sync",
                style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                ),
                child: const Text(
                  "Default: Active",
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF071426),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: selectedSemester,
                isExpanded: true,
                dropdownColor: const Color(0xFF0A192F),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF19D9F5)),
                hint: const Text("Select Semester", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                items: availableSemesters.map((sem) {
                  final title = sem['title']?.toString() ?? sem['code']?.toString() ?? '';
                  final isActive = sem['is_active'] == true;
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: sem,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF19D9F5), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Active",
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onSelectSemester,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Student ID Field
          const Text(
            "Student ID",
            style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF071426),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: TextField(
              controller: studentIdController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "2025-2-50-009",
                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF19D9F5), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Portal Password Field
          const Text(
            "Portal Password",
            style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF071426),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "••••••••••••",
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF19D9F5), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: onToggleObscurePassword,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Remember Credentials Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF071426),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: rememberCredentials ? const Color(0x6619D9F5) : Colors.white10),
            ),
            child: Row(
              children: [
                Icon(
                  rememberCredentials ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
                  color: rememberCredentials ? const Color(0xFF19D9F5) : const Color(0xFF64748B),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Remember on this device",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Saved securely in local storage only. Never sent to database.",
                        style: TextStyle(
                          color: rememberCredentials ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rememberCredentials,
                  activeThumbColor: const Color(0xFF19D9F5),
                  activeTrackColor: const Color(0xFF19D9F5).withValues(alpha: 0.3),
                  onChanged: onToggleRememberCredentials,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security reassurance card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A192F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x2219D9F5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: Color(0xFF19D9F5), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Your credentials are used in real-time only to fetch your data. We never store your password on our servers.",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Fetch & Preview Data Button
          GestureDetector(
            onTap: onStartSync,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF19D9F5),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF19D9F5).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                "Fetch & Preview Data",
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: Color(0xFF071426),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
