import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        content: Text('$label copied to clipboard!'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _submitVerification() async {
    final trxId = _trxIdController.text.trim();
    final sender = _senderController.text.trim();
    final amount = _amountController.text.trim();

    if (trxId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Transaction ID / Ref No.')),
      );
      return;
    }
    if (sender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Sender Number / Account Name')),
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
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                SizedBox(width: 10),
                Text('Submission Received', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Thank you! Your contribution details have been submitted. The developer will verify and acknowledge it shortly.',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                child: const Text('OK', style: TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit details: ${AuthErrorUtils.getFriendlyMessage(e)}'),
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
          opacity: 0.08,
          blur: 15,
          padding: const EdgeInsets.all(20),
          borderColor: const Color(0xFF22D3EE).withOpacity(0.2),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF22D3EE).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF22D3EE),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Keep EWUmate Running",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "EWUmate runs on independent servers to sync data, send notifications, and keep your schedules updated. Your generous support directly funds the server hosting fees and helps keep the application completely ad-free and open for everyone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
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
          opacity: 0.05,
          blur: 15,
          padding: const EdgeInsets.all(20),
          borderColor: Colors.white.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "BRAC Bank PLC",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "BONOSREE BRANCH",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
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
        const SizedBox(height: 24),
        
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22D3EE),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => setState(() => _showForm = true),
          child: const Text(
            "Verify Contribution Details",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          opacity: 0.05,
          blur: 15,
          padding: const EdgeInsets.all(20),
          borderColor: Colors.white.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Contribution Info",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Provide details to verify your payment. Screenshots are highly recommended.",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),

              // Payment Method
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration("Payment Method", Icons.payment_rounded),
                items: ['bKash', 'Nagad', 'BRAC Bank'].map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
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
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration(
                  _paymentMethod == 'BRAC Bank' ? "Reference / Document No." : "Transaction ID (TrxID)",
                  Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // Sender Detail
              TextField(
                controller: _senderController,
                style: const TextStyle(color: Colors.white),
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
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration("Amount (BDT - Optional)", Icons.attach_money_rounded),
              ),
              const SizedBox(height: 20),

              // Image Picker Box
              const Text(
                "Screenshot (Optional)",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickScreenshot,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                            Icon(Icons.add_photo_alternate_outlined, size: 30, color: Colors.white.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            Text(
                              "Tap to upload receipt screenshot",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.4),
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
        
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _isSubmitting ? null : _submitVerification,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  "Submit Contribution",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF22D3EE), size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF22D3EE)),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
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
      opacity: 0.05,
      blur: 15,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: Colors.white.withOpacity(0.05),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Center(
              child: Text(
                logoText,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "+88 $number",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(number, "$title Number"),
            icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white38),
            tooltip: "Copy Number",
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: const TextStyle(
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
              child: const Icon(
                Icons.copy_rounded,
                size: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.04),
      height: 16,
    );
  }
}
