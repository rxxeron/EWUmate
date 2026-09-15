import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/utils/error_utils.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final Map<String, TextEditingController> _replyControllers = {};
  final Set<String> _submittingReplyIds = {};
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
    final text = message.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to reply.')),
        );
      }
      return;
    }

    setState(() => _submittingReplyIds.add(feedbackId));

    try {
      await Supabase.instance.client.from('feedback_comments').insert({
        'feedback_id': feedbackId,
        'user_id': user.id,
        'comment': text,
        'is_admin': false,
      });

      _replyControllers[feedbackId]?.clear();
      await _fetchMyFeedbacks();
    } catch (e) {
      if (kDebugMode) debugPrint('Error submitting reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingReplyIds.remove(feedbackId));
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    for (final c in _replyControllers.values) {
      c.dispose();
    }
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
      case 'pending': return const Color(0xFFF59E0B);
      case 'in_progress': return AppColors.primaryCyan;
      case 'resolved': return const Color(0xFF10B981);
      case 'ignored': return AppColors.secondaryText;
      default: return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Feedback & Support',
          style: GoogleFonts.sora(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavyBlue.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primaryNavy,
                unselectedLabelColor: AppColors.secondaryText,
                labelStyle: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Submit Issue'),
                  Tab(text: 'My Feedbacks'),
                ],
              ),
            ),
          ),
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCyan),
      );
    }

    if (_myFeedbacks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.25), width: 1.5),
                ),
                child: const Icon(Icons.inbox_outlined, size: 36, color: AppColors.primaryCyan),
              ),
              const SizedBox(height: 18),
              Text(
                'No Feedback Yet',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Have an issue or idea? Submit feedback from the first tab and track responses here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _myFeedbacks.length,
      itemBuilder: (context, index) {
        final item = _myFeedbacks[index];
        final rawStatus = item['status'] ?? 'pending';
        final displayStatus = rawStatus.toString().replaceAll('_', ' ').toUpperCase();
        final Color statusColor = _getStatusColor(rawStatus);
        final comments = (item['feedback_comments'] as List?) ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceNavyBlue.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: Colors.white.withValues(alpha: 0.02),
              collapsedBackgroundColor: Colors.transparent,
              tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Icon(
                  rawStatus == 'resolved' ? Icons.check_circle_rounded : Icons.pending_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              title: Text(
                item['message'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        displayStatus,
                        style: GoogleFonts.sora(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.white24)),
                    const SizedBox(width: 8),
                    Text(
                      DateTime.parse(item['created_at']).toLocal().toString().split(' ')[0],
                      style: GoogleFonts.sora(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              iconColor: AppColors.secondaryText,
              collapsedIconColor: AppColors.secondaryText,
              children: [
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'YOUR MESSAGE',
                    style: GoogleFonts.sora(
                      color: AppColors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text(
                      item['message'] ?? '',
                      style: GoogleFonts.sora(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                if (comments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'CONVERSATION',
                      style: GoogleFonts.sora(
                        color: AppColors.secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...comments.map((c) {
                    final bool isAdmin = c['is_admin'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.primaryCyan.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isAdmin
                              ? AppColors.primaryCyan.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? AppColors.primaryCyan.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isAdmin ? 'SUPPORT TEAM' : 'YOU',
                                  style: GoogleFonts.sora(
                                    color: isAdmin ? AppColors.primaryCyan : AppColors.secondaryText,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              Text(
                                DateTime.parse(c['created_at']).toLocal().toString().split('.')[0].substring(11, 16),
                                style: GoogleFonts.sora(color: Colors.white30, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c['comment'] ?? '',
                            style: GoogleFonts.sora(
                              color: isAdmin ? Colors.white : Colors.white70,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final feedbackId = item['id'] as String;
                    final controller = _replyControllers.putIfAbsent(feedbackId, () => TextEditingController());
                    final isSending = _submittingReplyIds.contains(feedbackId);

                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                            enabled: !isSending,
                            decoration: InputDecoration(
                              hintText: 'Type a reply...',
                              hintStyle: GoogleFonts.sora(color: Colors.white30, fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primaryCyan),
                              ),
                            ),
                            onSubmitted: (val) {
                              _submitReply(feedbackId, val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                                  )
                                : const Icon(Icons.send_rounded, color: AppColors.primaryNavy, size: 20),
                            onPressed: isSending
                                ? null
                                : () => _submitReply(feedbackId, controller.text),
                          ),
                        ),
                      ],
                    );
                  },
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Issue Header Card
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.rate_review_rounded, color: AppColors.primaryCyan, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report an Issue',
                            style: GoogleFonts.sora(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Discrepancies, bugs, or feature suggestions',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Describe what happened or what you would like to see improved...',
                    hintStyle: GoogleFonts.sora(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                          )
                        : Text(
                            'Submit Feedback',
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Developer Details Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, color: AppColors.primaryCyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'DEVELOPER CONTACT',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contact Items Card
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.15),
                      child: Text(
                        'R',
                        style: GoogleFonts.sora(
                          color: AppColors.primaryCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'rxxeron',
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Creator & Lead Maintainer',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 8),
                _buildContactItem(
                  icon: Icons.facebook,
                  iconColor: const Color(0xFF1877F2),
                  label: 'Facebook',
                  value: 'rakibulhasanrakib.90.12',
                  onTap: () => _launchUrl('https://www.facebook.com/rakibulhasanrakib.90.12'),
                ),
                _buildContactItem(
                  icon: Icons.phone,
                  iconColor: const Color(0xFF25D366),
                  label: 'WhatsApp',
                  value: '+880601487027',
                  onTap: () => _launchUrl('https://wa.me/880601487027'),
                ),
                _buildContactItem(
                  icon: Icons.email,
                  iconColor: const Color(0xFFEA4335),
                  label: 'Personal Email',
                  value: 'rhrakibulhasan279@gmail.com',
                  onTap: () => _launchUrl('mailto:rhrakibulhasan279@gmail.com'),
                ),
                _buildContactItem(
                  icon: Icons.school,
                  iconColor: AppColors.primaryCyan,
                  label: 'University Email',
                  value: '2025-2-50-009@std.ewubd.edu',
                  onTap: () => _launchUrl('mailto:2025-2-50-009@std.ewubd.edu'),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info_outline, color: AppColors.primaryCyan, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Version',
                          style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 11),
                        ),
                        Text(
                          _currentVersion,
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.sora(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
