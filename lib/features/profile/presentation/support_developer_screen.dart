import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/utils/error_utils.dart';

class SupportDeveloperScreen extends ConsumerStatefulWidget {
  const SupportDeveloperScreen({super.key});

  @override
  ConsumerState<SupportDeveloperScreen> createState() => _SupportDeveloperScreenState();
}

class _SupportDeveloperScreenState extends ConsumerState<SupportDeveloperScreen> {
  bool _showForm = false;
  
  // Form fields
  String _paymentMethod = 'bKash';
  final _trxIdController = TextEditingController();
  final _senderController = TextEditingController();
  final _amountController = TextEditingController();
  
  File? _screenshotFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _trxIdController.dispose();
    _senderController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied to clipboard!',
          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickScreenshot() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
      );
      
      if (pickedFile != null) {
        setState(() {
          _screenshotFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    final trxId = _trxIdController.text.trim();
    final sender = _senderController.text.trim();
    final amount = _amountController.text.trim();

    if (trxId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the Transaction ID / Ref No.', style: GoogleFonts.sora()),
        ),
      );
      return;
    }
    if (sender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the Sender Number / Account Name', style: GoogleFonts.sora()),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      String? screenshotUrl;

      // 1. Upload screenshot if available
      if (_screenshotFile != null) {
        final fileExt = _screenshotFile!.path.split('.').last.toLowerCase();
        final fileName = 'donations/${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await supabase.storage
            .from('profile_images')
            .upload(
              fileName,
              _screenshotFile!,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );

        screenshotUrl = supabase.storage
            .from('profile_images')
            .getPublicUrl(fileName);
      }

      // 2. Insert details directly into public.donations table
      final double? parsedAmount = double.tryParse(amount);
      await supabase.from('donations').insert({
        'user_id': user.id,
        'payment_method': _paymentMethod,
        'transaction_id': trxId,
        'sender_info': sender,
        'amount': parsedAmount,
        'screenshot_url': screenshotUrl,
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceNavyBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
            ),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                const SizedBox(width: 10),
                Text(
                  'Submission Received',
                  style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              'Thank you! Your contribution details have been submitted. The developer will verify and acknowledge it shortly.',
              style: GoogleFonts.sora(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // pop dialog
                  setState(() {
                    _showForm = false;
                    _trxIdController.clear();
                    _senderController.clear();
                    _amountController.clear();
                    _screenshotFile = null;
                  });
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.sora(color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit details: ${AuthErrorUtils.getFriendlyMessage(e)}', style: GoogleFonts.sora()),
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
    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          _showForm ? 'Verify Contribution' : 'Support the Developer',
          style: GoogleFonts.sora(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_showForm) {
              setState(() => _showForm = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 40.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showForm ? _buildFormSection() : _buildPaymentDetailsSection(),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro Card
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryCyan.withValues(alpha: 0.2),
                      AppColors.secondarySoftBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primaryCyan,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Keep EWUmate Running",
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "EWUmate runs on independent servers to sync data, send notifications, and keep your schedules updated. Your generous support directly funds server hosting fees and keeps the application completely ad-free and open for everyone.",
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Mobile Banking Title
        _buildSectionHeader("Mobile Banking (BD)"),
        const SizedBox(height: 12),

        // bKash & Nagad
        _buildMobilePaymentCard(
          title: "bKash",
          number: "01601487027",
          color: const Color(0xFFE2125D),
          logoText: "bK",
        ),
        const SizedBox(height: 12),
        _buildMobilePaymentCard(
          title: "Nagad",
          number: "01601487027",
          color: const Color(0xFFF57224),
          logoText: "N",
        ),
        const SizedBox(height: 24),

        // Bank Accounts Title
        _buildSectionHeader("Bank Account Transfer"),
        const SizedBox(height: 12),

        // Bank Account Details Card
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "BRAC Bank PLC",
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "BONOSREE BRANCH",
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildDetailRow("Account Name", "MD. RAKIBUL HASAN", canCopy: false),
              _buildDivider(),
              _buildDetailRow("Account Number", "1065876490002", canCopy: true),
              _buildDivider(),
              _buildDetailRow("Routing Number", "060260727", canCopy: true),
              _buildDivider(),
              _buildDetailRow("SWIFT Code", "BRAKBDDH", canCopy: true),
            ],
          ),
        ),
        const SizedBox(height: 28),
        
        Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryCyan.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => setState(() => _showForm = true),
            child: Text(
              "Verify Contribution Details",
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Contribution Info",
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Provide details to verify your payment. Screenshots are highly recommended.",
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),

              // Payment Method
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                dropdownColor: AppColors.surfaceNavyBlue,
                style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                decoration: _getInputDecoration("Payment Method", Icons.payment_rounded),
                items: ['bKash', 'Nagad', 'BRAC Bank'].map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method, style: GoogleFonts.sora(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _paymentMethod = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Transaction ID
              TextField(
                controller: _trxIdController,
                style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                decoration: _getInputDecoration(
                  _paymentMethod == 'BRAC Bank' ? "Reference / Document No." : "Transaction ID (TrxID)",
                  Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // Sender Detail
              TextField(
                controller: _senderController,
                style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                decoration: _getInputDecoration(
                  _paymentMethod == 'BRAC Bank' ? "Sender Account Name" : "Sender Mobile Number",
                  Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                decoration: _getInputDecoration("Amount (BDT - Optional)", Icons.attach_money_rounded),
              ),
              const SizedBox(height: 20),

              // Image Picker Box
              Text(
                "Screenshot (Optional)",
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickScreenshot,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: _screenshotFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(_screenshotFile!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => setState(() => _screenshotFile = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 30, color: AppColors.primaryCyan.withValues(alpha: 0.6)),
                            const SizedBox(height: 8),
                            Text(
                              "Tap to upload receipt screenshot",
                              style: GoogleFonts.sora(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isSubmitting ? null : _submitVerification,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    "Submit Contribution",
                    style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primaryCyan, size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.02),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.sora(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryText,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMobilePaymentCard({
    required String title,
    required String number,
    required Color color,
    required String logoText,
  }) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Center(
              child: Text(
                logoText,
                style: GoogleFonts.sora(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "+88 $number",
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () => _copyToClipboard(number, "$title Number"),
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryCyan),
              tooltip: "Copy Number",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required bool canCopy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyToClipboard(value, label),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.primaryCyan,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.06),
      height: 16,
    );
  }
}
