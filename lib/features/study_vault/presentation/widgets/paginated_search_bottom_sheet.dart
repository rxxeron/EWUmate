import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaginatedSearchBottomSheet extends StatefulWidget {
  final String title;
  final String tableName;
  final String labelKey;
  final String subtitleKey;
  final String searchPlaceholder;
  final String customValueLabel;
  final bool showCustomValue;
  final Function(String code, String name) onSelected;

  const PaginatedSearchBottomSheet({
    super.key,
    required this.title,
    required this.tableName,
    required this.labelKey,
    required this.subtitleKey,
    required this.searchPlaceholder,
    required this.customValueLabel,
    this.showCustomValue = true,
    required this.onSelected,
  });

  @override
  State<PaginatedSearchBottomSheet> createState() => _PaginatedSearchBottomSheetState();
}

class _PaginatedSearchBottomSheetState extends State<PaginatedSearchBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _page = 0;
  bool _hasMore = true;
  String _searchQuery = "";
  Timer? _debounceTimer;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _fetchPage(0);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchPage(_page + 1);
      }
    }
  }

  Future<void> _fetchPage(int page, {bool isNewSearch = false}) async {
    if (isNewSearch) {
      setState(() {
        _items = [];
        _page = 0;
        _hasMore = true;
        _isLoading = true;
      });
    } else {
      setState(() {
        if (page == 0) {
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
      });
    }

    try {
      final offset = page * _pageSize;
      var queryBuilder = Supabase.instance.client
          .from(widget.tableName)
          .select('${widget.labelKey}, ${widget.subtitleKey}');

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim();
        final normalizedQ = q.replaceAll(RegExp(r'[\s\.-]'), '');
        if (normalizedQ != q && normalizedQ.isNotEmpty) {
          queryBuilder = queryBuilder.or(
            '${widget.labelKey}.ilike.%$q%,'
            '${widget.labelKey}.ilike.%$normalizedQ%,'
            '${widget.subtitleKey}.ilike.%$q%'
          );
        } else {
          queryBuilder = queryBuilder.or('${widget.labelKey}.ilike.%$q%,${widget.subtitleKey}.ilike.%$q%');
        }
      }

      final response = await queryBuilder
          .order(widget.labelKey, ascending: true)
          .range(offset, offset + _pageSize - 1);

      final rows = response as List;
      final List<Map<String, dynamic>> fetchedItems = [];
      for (var row in rows) {
        fetchedItems.add({
          'label': row[widget.labelKey]?.toString() ?? '',
          'subtitle': row[widget.subtitleKey]?.toString() ?? '',
        });
      }

      if (mounted) {
        setState(() {
          if (isNewSearch || page == 0) {
            _items = fetchedItems;
          } else {
            _items.addAll(fetchedItems);
          }
          _page = page;
          _isLoading = false;
          _isLoadingMore = false;
          if (fetchedItems.length < _pageSize) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading search page: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchPage(0, isNewSearch: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final customValue = _searchQuery.trim().toUpperCase();
    final showCustomOption = widget.showCustomValue && _searchQuery.trim().isNotEmpty;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: widget.searchPlaceholder,
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent),
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged("");
                    },
                  )
                : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  )
                : Column(
                    children: [
                      if (showCustomOption)
                        Card(
                          color: Colors.cyanAccent.withValues(alpha: 0.05),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.add_circle_outline_rounded, color: Colors.cyanAccent),
                            title: Text(
                              'Use Custom: "$customValue"',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              widget.customValueLabel,
                              style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.6), fontSize: 12),
                            ),
                            onTap: () {
                              widget.onSelected(customValue, "Custom Entry");
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      Expanded(
                        child: _items.isEmpty
                            ? const Center(
                                child: Text(
                                  'No items found',
                                  style: TextStyle(color: Colors.white38),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _items.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                                        ),
                                      ),
                                    );
                                  }

                                  final item = _items[index];
                                  final label = item['label']!;
                                  final subtitle = item['subtitle']!;

                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        title: Text(
                                          label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          subtitle,
                                          style: const TextStyle(color: Colors.white38),
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 16),
                                        onTap: () {
                                          widget.onSelected(label, subtitle);
                                          Navigator.pop(context);
                                        },
                                      ),
                                      const Divider(color: Colors.white10, height: 1),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class StaticListBottomSheet extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final Function(String value) onSelected;

  const StaticListBottomSheet({
    super.key,
    required this.title,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        item['label']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                      onTap: () {
                        onSelected(item['value']!);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
