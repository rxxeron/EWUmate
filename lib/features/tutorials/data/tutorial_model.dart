class Tutorial {
  final String id;
  final String title;
  final String youtubeUrl;
  final String? description;
  final String category;
  final String? thumbnailUrl;
  final bool isFeatured;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;

  const Tutorial({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    this.description,
    this.category = 'General',
    this.thumbnailUrl,
    this.isFeatured = false,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  String get youtubeVideoId {
    try {
      final uri = Uri.parse(youtubeUrl);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      }
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v']!;
      }
      if (uri.pathSegments.contains('embed') && uri.pathSegments.length > 1) {
        final idx = uri.pathSegments.indexOf('embed');
        return uri.pathSegments[idx + 1];
      }
    } catch (_) {}
    return '';
  }

  String get resolvedThumbnail {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl!;
    final vid = youtubeVideoId;
    if (vid.isNotEmpty) return 'https://img.youtube.com/vi/$vid/hqdefault.jpg';
    return '';
  }

  factory Tutorial.fromMap(Map<String, dynamic> map) {
    return Tutorial(
      id: map['id'] as String,
      title: map['title'] as String,
      youtubeUrl: map['youtube_url'] as String,
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'General',
      thumbnailUrl: map['thumbnail_url'] as String?,
      isFeatured: map['is_featured'] as bool? ?? false,
      displayOrder: map['display_order'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
