import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/utils/version_utils.dart';
import '../../../core/utils/error_utils.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  late TabController _tabController;

  List<Map<String, dynamic>> _myFeedbacks = [];
  bool _isLoadingFeedbacks = true;
  String _currentVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _fetchMyFeedbacks();
      }
    });
    _fetchMyFeedbacks();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final versionInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentVersion = '${versionInfo.version} (Build ${versionInfo.buildNumber})';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentVersion = 'Unknown';
        });
      }
    }
  }

  Future<void> _fetchMyFeedbacks() async {
    setState(() => _isLoadingFeedbacks = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('feedbacks')
          .select('*, feedback_comments(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myFeedbacks = List<Map<String, dynamic>>.from(response);
          // Sort comments for each feedback
          for (var fb in _myFeedbacks) {
            if (fb['feedback_comments'] != null) {
              (fb['feedback_comments'] as List).sort((a, b) => 
                DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at']))
              );
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching feedbacks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFeedbacks = false);
      }
    }
  }

  Future<void> _submitReply(String feedbackId, String message) async {
    if (message.trim().isEmpty) return;
    
    try {
      await Supabase.instance.client.from('feedback_comments').insert({
        'feedback_id': feedbackId,
        'comment': message,
      });
      
      _fetchMyFeedbacks();
    } catch (e) {
      if (kDebugMode) debugPrint('Error submitting reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await Supabase.instance.client.from('feedbacks').insert({
        'user_id': user.id,
        'message': message,
      }).timeout(const Duration(seconds: 15));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback sent successfully! Thank you.')),
        );
        _messageController.clear();
        _fetchMyFeedbacks();
        _tabController.animateTo(1); // switch to history tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orangeAccent;
      case 'in_progress': return Colors.blueAccent;
      case 'resolved': return Colors.greenAccent;
      case 'ignored': return Colors.grey;
      default: return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Support'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: 'Submit Issue'),
            Tab(text: 'My Feedbacks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmitTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingFeedbacks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myFeedbacks.isEmpty) {
      return const Center(
        child: Text(
          'You haven\'t submitted any feedback yet.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myFeedbacks.length,
      itemBuilder: (context, index) {
        final item = _myFeedbacks[index];
        final rawStatus = item['status'] ?? 'pending';
        final displayStatus = rawStatus.toString().replaceAll('_', ' ').toUpperCase();
        final Color statusColor = _getStatusColor(rawStatus);
        final comments = (item['feedback_comments'] as List?) ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E293B).withOpacity(0.7),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: statusColor.withOpacity(0.2), width: 1),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: Colors.white.withOpacity(0.02),
              collapsedBackgroundColor: Colors.transparent,
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  rawStatus == 'resolved' ? Icons.check_circle_outline : Icons.pending_outlined,
                  color: statusColor,
                ),
              ),
              title: Text(
                item['message'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.white24)),
                    const SizedBox(width: 8),
                    Text(
                      DateTime.parse(item['created_at']).toLocal().toString().split(' ')[0],
                      style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              iconColor: Colors.white38,
              collapsedIconColor: Colors.white38,
              children: [
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Full Message:',
                    style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item['message'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ),
                if (comments.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'CONVERSATION HISTORY',
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...comments.map((c) {
                    final bool isAdmin = c['is_admin'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.blueAccent.withOpacity(0.05) : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAdmin ? Colors.blueAccent.withOpacity(0.1) : Colors.white10,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAdmin ? 'SUPPORT TEAM' : 'YOU',
                                style: TextStyle(
                                  color: isAdmin ? Colors.blueAccent : Colors.white38,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                DateTime.parse(c['created_at']).toLocal().toString().split('.')[0].substring(11, 16),
                                style: const TextStyle(color: Colors.white24, fontSize: 9),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c['comment'] ?? '',
                            style: TextStyle(
                              color: isAdmin ? Colors.white : Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Type a follow-up...',
                          hintStyle: const TextStyle(color: Colors.white24),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _submitReply(item['id'], val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.blueAccent, size: 20),
                        onPressed: () {
                          // Note: In a real app we'd need a controller per item
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            'Report an Issue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Facing discrepancies or bugs? Have a suggestion? Let us know!',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Describe the issue or suggestion...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1E293B).withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Submit Feedback',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 48),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),
          const Text(
            'Developer Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            color: const Color(0xFF1E293B).withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nickname: rxxeron',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    value: 'rakibulhasanrakib.90.12',
                    onTap: () => _launchUrl('https://www.facebook.com/rakibulhasanrakib.90.12'),
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.phone,
                    label: 'WhatsApp',
                    value: '+880601487027',
                    onTap: () => _launchUrl('https://wa.me/880601487027'),
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.email,
                    label: 'Personal Email',
                    value: 'rhrakibulhasan279@gmail.com',
                    onTap: () => _launchUrl('mailto:rhrakibulhasan279@gmail.com'),
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.school,
                    label: 'University Email',
                    value: '2025-2-50-009@std.ewubd.edu',
                    onTap: () => _launchUrl('mailto:2025-2-50-009@std.ewubd.edu'),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blueAccent, size: 24),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'App Version',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _currentVersion,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
