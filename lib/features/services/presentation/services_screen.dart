import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Academic Utilities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: (1.0 / MediaQuery.textScalerOf(context).scale(1.0)).clamp(0.75, 1.0),
              children: [
                  _buildServiceCard(
                    context,
                    title: 'Cover Page Generator',
                    icon: Icons.picture_as_pdf_outlined,
                    color: Colors.blue.shade100,
                    iconColor: Colors.blue.shade700,
                    onTap: () {
                      context.push('/services/cover-page');
                    },
                  ),
                  _buildServiceCard(
                    context,
                    title: 'Faculty List (PDF)',
                    icon: Icons.picture_as_pdf_outlined,
                    color: Colors.green.shade100,
                    iconColor: Colors.green.shade700,
                    onTap: () {
                      context.push('/services/faculty-list');
                    },
                  ),
                  _buildServiceCard(
                    context,
                    title: 'Faculty Directory',
                    icon: Icons.people_alt_outlined,
                    color: Colors.purple.shade100,
                    iconColor: Colors.purple.shade700,
                    onTap: () {
                      context.push('/services/faculty-directory');
                    },
                  ),
                  _buildServiceCard(
                    context,
                    title: 'Study Materials Vault',
                    icon: Icons.folder_special_outlined,
                    color: Colors.orange.shade100,
                    iconColor: Colors.orange.shade700,
                    onTap: () {
                      context.push('/services/study-vault');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {required String title, required IconData icon, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: iconColor.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
