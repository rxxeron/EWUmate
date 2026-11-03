import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';
import '../../../core/services/screen_protection_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';

class FacultyPdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String semester;

  const FacultyPdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.semester,
  });

  @override
  State<FacultyPdfViewerScreen> createState() => _FacultyPdfViewerScreenState();
}

class _FacultyPdfViewerScreenState extends State<FacultyPdfViewerScreen> {
  late final PdfViewerController _pdfController;
  PdfTextSearcher? _searcher;
  final TextEditingController _searchQueryController = TextEditingController();

  bool _isSearching = false;
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();

    // 1. Strictly enable screenshot and recording protection on entrance
    ScreenProtectionService.enableProtection();

    // 2. Fetch PDF bytes securely into memory
    _loadPdfData();
  }

  @override
  void dispose() {
    // Release screen protection on exit
    ScreenProtectionService.disableProtection();
    _searcher?.dispose();
    _searchQueryController.dispose();
    super.dispose();
  }

  String _resolveDirectUrl(String rawUrl) {
    if (rawUrl.isEmpty) return rawUrl;

    // Check for Google Drive file link: /file/d/<id>/view or id=<id>
    final fileIdRegex = RegExp(r'[-\w]{25,}');
    if (rawUrl.contains('drive.google.com') || rawUrl.contains('docs.google.com')) {
      final match = fileIdRegex.firstMatch(rawUrl);
      if (match != null) {
        final id = match.group(0);
        return 'https://drive.usercontent.google.com/download?id=$id&export=download&authuser=0&confirm=t';
      }
    }
    return rawUrl;
  }

  Future<void> _loadPdfData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final directUrl = _resolveDirectUrl(widget.pdfUrl);
      final response = await http.get(
        Uri.parse(directUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/pdf,*/*',
        },
      ).timeout(
        const Duration(seconds: 35),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _pdfBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to stream faculty schedule securely. ($e)';
          _isLoading = false;
        });
      }
    }
  }

  void _executeSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _clearSearch();
      return;
    }
    _searcher?.startTextSearch(trimmed, caseInsensitive: true, goToFirstMatch: true, searchImmediately: true);
  }

  void _clearSearch() {
    _searcher?.resetTextSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchActive = _isSearching;

    return FullGradientScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surfaceNavyBlue.withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: searchActive
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _searchQueryController,
                  autofocus: true,
                  style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _executeSearch,
                  onChanged: (val) {
                    if (val.trim().length >= 2) {
                      _executeSearch(val);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search faculty initial, course, room...',
                    hintStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryCyan, size: 18),
                    suffixIcon: _searchQueryController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                            onPressed: () {
                              _searchQueryController.clear();
                              _clearSearch();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    widget.semester,
                    style: GoogleFonts.sora(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              searchActive ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.primaryCyan,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQueryController.clear();
                  _clearSearch();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Security Warning Header (Assures IP protection & explains restrictions)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: Colors.tealAccent, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Protected In-App View • Screenshots Blocked • Downloads Restricted',
                    style: GoogleFonts.sora(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Search Results Navigation Bar (When search is active)
          if (_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavyBlue,
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Icon(Icons.find_in_page_rounded, size: 16, color: AppColors.primaryCyan),
                  const SizedBox(width: 8),
                  Text(
                    (_searcher?.matches.isNotEmpty ?? false)
                        ? '${(_searcher!.currentIndex ?? 0) + 1} of ${_searcher!.matches.length} matches'
                        : (_searchQueryController.text.trim().isEmpty ? 'Enter search term' : 'No matches found'),
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
                    tooltip: 'Previous match',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: (_searcher?.hasMatches ?? false) ? () => _searcher?.goToPrevMatch() : null,
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                    tooltip: 'Next match',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: (_searcher?.hasMatches ?? false) ? () => _searcher?.goToNextMatch() : null,
                  ),
                ],
              ),
            ),

          // Main PDF Viewport
          Expanded(
            child: _buildPdfContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryCyan),
            const SizedBox(height: 16),
            Text(
              'Decrypting & streaming schedule...',
              style: GoogleFonts.sora(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _pdfBytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Schedule Protected',
                style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unable to render protected document.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPdfData,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: const Color(0xFF04101E),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PdfViewer.data(
      _pdfBytes!,
      sourceName: 'faculty_schedule.pdf',
      controller: _pdfController,
      params: PdfViewerParams(
        onViewerReady: (document, controller) {
          if (mounted && _searcher == null) {
            setState(() {
              _searcher = PdfTextSearcher(controller)
                ..addListener(() {
                  if (mounted) setState(() {});
                });
            });
          }
        },
        pagePaintCallbacks: [
          (canvas, pageRect, page) {
            _searcher?.pageTextMatchPaintCallback(canvas, pageRect, page);
          },
        ],
      ),
    );
  }
}
