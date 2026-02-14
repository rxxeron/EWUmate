import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../core/services/storage_service.dart';
import '../../core/widgets/glass_kit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();

  final StorageService _storageService = StorageService();

  bool _loading = false;
  bool _passwordVisible = false;
  XFile? _imageFile; // Used for upload
  Uint8List? _imageBytes; // Used for preview (web-safe)

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Use lower quality for performance optimization
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final String uid = cred.user!.uid;
      String? photoURL;

      if (_imageFile != null) {
        photoURL = await _storageService.uploadProfileImage(_imageFile!, uid);
      }

      await cred.user?.updateDisplayName(_nicknameController.text.trim());
      if (photoURL != null) {
        await cred.user?.updatePhotoURL(photoURL);
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'phone': _phoneController.text.trim(),
        'photoURL': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingStatus': 'registered',
      }, SetOptions(merge: true));

      if (mounted) context.go('/onboarding/program'); // Direct to flow
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Registration Failed: ${e.message}"),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: GlassContainer(
            borderRadius: 24,
            opacity: 0.1,
            blur: 15,
            padding: const EdgeInsets.all(28.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text("Join EWUmate today!",
                      style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 24),

                  // Picture
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white10,
                        backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : null,
                        child: _imageFile == null
                            ? const Icon(Icons.person,
                                size: 45, color: Colors.white70)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.cyanAccent,
                          radius: 16,
                          child: IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.black),
                            onPressed: _pickImage,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: "Full Name",
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.person_outline,
                                  size: 20, color: Colors.cyanAccent),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.1))),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.cyanAccent)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05)),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _nicknameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: "Nickname",
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.face,
                                  size: 20, color: Colors.cyanAccent),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.1))),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.cyanAccent)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05)),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _studentIdController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: "Student ID",
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.badge_outlined,
                                  size: 20, color: Colors.cyanAccent),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.1))),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.cyanAccent)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05)),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: "Phone",
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.phone_outlined,
                                  size: 20, color: Colors.cyanAccent),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.1))),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.cyanAccent)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05)),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.email_outlined,
                            size: 20, color: Colors.cyanAccent),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.cyanAccent)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05)),
                    validator: (value) => value!.isEmpty || !value.contains('@')
                        ? "Valid email required"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_outline,
                          size: 20, color: Colors.cyanAccent),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.cyanAccent)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                            color: Colors.white70),
                        onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    validator: (value) =>
                        value!.length < 6 ? "Min 6 chars" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _confirmController,
                    obscureText: !_passwordVisible,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Confirm",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_outline,
                          size: 20, color: Colors.cyanAccent),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.cyanAccent)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                    ),
                    validator: (value) =>
                        value != _passwordController.text ? "Mismatch" : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: GlassContainer(
                      onTap: _loading ? null : _register,
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      borderColor: Colors.cyanAccent,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.cyanAccent, strokeWidth: 2))
                            : const Text("Create Account",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyanAccent)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Have an account?",
                          style: TextStyle(color: Colors.white70)),
                      TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text("Login",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
