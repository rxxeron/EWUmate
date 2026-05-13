import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/faculty.dart';

class FacultyCard extends StatelessWidget {
  final Faculty faculty;

  const FacultyCard({super.key, required this.faculty});

  @override
  Widget build(BuildContext context) {
    // Handle live photo URLs correctly
    String? finalPhotoUrl = faculty.photoUrl;
    bool isLiveUrl = finalPhotoUrl != null && finalPhotoUrl.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E2836).withOpacity(0.8),
            const Color(0xFF16202A).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: faculty.profileUrl != null ? () => _launchUrl(faculty.profileUrl!) : null,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Premium Avatar
                  Hero(
                    tag: 'faculty_${faculty.id}',
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFF16202A),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                        image: isLiveUrl
                            ? DecorationImage(
                                image: NetworkImage(finalPhotoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !isLiveUrl
                          ? const Icon(Icons.person_rounded, color: Colors.white24, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 18),
                  
                  // Info Area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                faculty.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                faculty.shortName,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // Designation Badge
                        if (faculty.designation != null && faculty.designation!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              faculty.designation!,
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 10),
                        
                        // Email Area with Copy
                        if (faculty.email != null && faculty.email!.isNotEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _launchEmail(faculty.email!),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.email_rounded, color: Color(0xFF00E5FF), size: 14),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            faculty.email!,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _ActionIconButton(
                                icon: Icons.copy_rounded,
                                label: '',
                                onTap: () => _copyEmail(context, faculty.email!),
                              ),
                            ],
                          ),
                        
                        if (faculty.profileUrl != null) ...[
                          const SizedBox(height: 8),
                          _ActionIconButton(
                            icon: Icons.open_in_new_rounded,
                            label: 'View Full Profile',
                            onTap: () => _launchUrl(faculty.profileUrl!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email copied to clipboard'),
        backgroundColor: const Color(0xFF00E5FF).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
