import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provide a way to access the current shell's scaffold key
final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  // This will be overridden in MainShell
  throw UnimplementedError('scaffoldKeyProvider must be accessed within a MainShell');
});
