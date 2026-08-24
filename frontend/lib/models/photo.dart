DateTime? _photoDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class Photo {
  const Photo({
    required this.id,
    required this.url,
    required this.caption,
    this.uploadedAt,
  });

  final String id;
  final String url;
  final String caption;
  final DateTime? uploadedAt;

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      uploadedAt: _photoDate(json['uploadedAt'] ?? json['createdAt']),
    );
  }
}
