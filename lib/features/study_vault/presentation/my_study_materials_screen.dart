import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import '../data/models/study_material.dart';
import '../data/repositories/study_vault_repository.dart';
import 'providers/study_vault_providers.dart';

class MyStudyMaterialsScreen extends ConsumerStatefulWidget {
  const MyStudyMaterialsScreen({super.key});

  @override
  ConsumerState<MyStudyMaterialsScreen> createState() => _MyStudyMaterialsScreenState();
}

class _MyStudyMaterialsScreenState extends ConsumerState<MyStudyMaterialsScreen> {
  bool _isSubmitting = false;

  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    IconData iconData;
    Color color;

    if (ext == 'pdf') {
      iconData = Icons.picture_as_pdf_rounded;
      color = Colors.redAccent;
    } else if (ext == 'doc' || ext == 'docx') {
      iconData = Icons.description_rounded;
      color = Colors.blueAccent;
    } else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      iconData = Icons.image_rounded;
      color = Colors.greenAccent;
    } else {
      iconData = Icons.insert_drive_file_rounded;
      color = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: color, size: 28),
    );
  }

  String _formatDate(DateTime dt) {
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

  Widget _getStatusBadge(String status) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        badgeColor = Colors.greenAccent;
        label = 'Approved & Active';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'rejected':
        badgeColor = Colors.redAccent;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case 'removal_requested':
        badgeColor = Colors.orangeAccent;
        label = 'Removal Requested';
        icon = Icons.delete_sweep_outlined;
        break;
      case 'pending':
      default:
        badgeColor = Colors.amberAccent;
        label = 'Pending Review';
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRemovalRequest(StudyMaterial item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Request Removal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to request the removal of "${item.fileName}"?\n\nThis will send a request to the system administrators for review. The file will remain visible until an admin approves your request.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(studyVaultRepositoryProvider);
      await repository.requestRemoval(item.id);
      
      // Refresh views
      ref.invalidate(myStudyMaterialsProvider);
      ref.invalidate(studyMaterialsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removal request submitted successfully! An admin will review it shortly.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myMaterialsAsync = ref.watch(myStudyMaterialsProvider);

    return FullGradientScaffold(
      appBar: const EWUmateAppBar(
        title: 'My Uploaded Materials',
        showBack: true,
      ),
      body: Stack(
        children: [
          myMaterialsAsync.when(
            data: (materials) {
              if (materials.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text(
                        'You haven\'t uploaded any materials yet.',
                        style: TextStyle(color: Colors.white38, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: materials.length,
                itemBuilder: (context, index) {
                  final item = materials[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassContainer(
                      width: double.infinity,
                      borderRadius: 16,
                      borderColor: Colors.white10,
                      opacity: 0.03,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          _getFileIcon(item.fileName),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.courseCode ?? 'Unknown'} • ${item.facultyInitial ?? 'Unknown'} • ${item.fileType ?? 'Other'}',
                                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _getStatusBadge(item.status),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(item.createdAt),
                                      style: const TextStyle(fontSize: 10, color: Colors.white24),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (item.status == 'approved')
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              tooltip: 'Request Removal',
                              onPressed: () => _handleRemovalRequest(item),
                            )
                          else if (item.status == 'removal_requested')
                            const Tooltip(
                              message: 'Removal request is under review',
                              child: Icon(Icons.hourglass_bottom_rounded, color: Colors.orangeAccent, size: 20),
                            )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
            error: (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),
        ],
      ),
    );
  }
}
