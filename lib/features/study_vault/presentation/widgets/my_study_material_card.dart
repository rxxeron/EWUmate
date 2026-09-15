import 'package:flutter/material.dart';
import '../../data/models/study_material.dart';

class MyStudyMaterialCard extends StatelessWidget {
  final StudyMaterial item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const MyStudyMaterialCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  static Widget buildFileTypeBadge(String fileName, {String? fileType}) {
    final ext = fileName.split('.').last.toLowerCase();
    Color bgColor;
    Color textColor;
    String badgeText;
    IconData icon;

    if (ext == 'pdf' || (fileType?.toLowerCase().contains('pdf') ?? false)) {
      bgColor = const Color(0xFFEF4444);
      textColor = Colors.white;
      badgeText = 'PDF';
      icon = Icons.picture_as_pdf_rounded;
    } else if (['xlsx', 'xls', 'csv'].contains(ext) || (fileType?.toLowerCase().contains('excel') ?? false)) {
      bgColor = const Color(0xFF10B981);
      textColor = Colors.white;
      badgeText = 'XLS';
      icon = Icons.table_chart_rounded;
    } else if (['doc', 'docx'].contains(ext) || (fileType?.toLowerCase().contains('doc') ?? false)) {
      bgColor = const Color(0xFF3B82F6);
      textColor = Colors.white;
      badgeText = 'DOC';
      icon = Icons.description_rounded;
    } else if (['ppt', 'pptx'].contains(ext) || (fileType?.toLowerCase().contains('slide') ?? false)) {
      bgColor = const Color(0xFFF97316);
      textColor = Colors.white;
      badgeText = 'PPT';
      icon = Icons.slideshow_rounded;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      bgColor = const Color(0xFF8B5CF6);
      textColor = Colors.white;
      badgeText = 'IMG';
      icon = Icons.image_rounded;
    } else {
      bgColor = const Color(0xFF06B6D4);
      textColor = Colors.white;
      badgeText = 'NOTE';
      icon = Icons.article_rounded;
    }

    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: bgColor),
          const SizedBox(height: 2),
          Text(
            badgeText,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  static Widget getStatusBadge(String status) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        badgeColor = const Color(0xFF10B981);
        label = 'Approved & Active';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        badgeColor = const Color(0xFFEF4444);
        label = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
      case 'removal_requested':
        badgeColor = const Color(0xFF64748B);
        label = 'Removal Requested';
        icon = Icons.archive_rounded;
        break;
      case 'pending':
      default:
        badgeColor = const Color(0xFF38BDF8);
        label = 'Pending Review';
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A192F),
            Color(0xFF0D2342),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x2219D9F5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left File Type Badge
                buildFileTypeBadge(item.fileName, fileType: item.fileType),
                const SizedBox(width: 14),

                // Central Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.fileName,
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Subtitle: Course • Faculty • Type
                      Text(
                        '${item.courseCode ?? 'Unknown'} • ${item.facultyInitial ?? 'Dept'} • ${item.fileType ?? 'Material'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Bottom row: Size & Date + Status Badge
                      Row(
                        children: [
                          Text(
                            '${formatFileSize(item.fileSizeBytes)} • ${formatDate(item.createdAt)}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          getStatusBadge(item.status),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3-dot options menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  color: const Color(0xFF0B1B32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: Color(0x3319D9F5),
                      width: 1,
                    ),
                  ),
                  onSelected: (action) {
                    if (action == 'open') {
                      onOpen();
                    } else if (action == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new_rounded, color: Color(0xFF19D9F5), size: 18),
                          SizedBox(width: 10),
                          Text('Open / View', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                          SizedBox(width: 10),
                          Text('Delete Material', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
