class CryptoNews {
  final String id;
  final String title;
  final String body;
  final String url;
  final String? imageUrl;
  final String source;
  final DateTime publishedOn;
  final List<String> categories;
  final List<String> tags;
  final String lang;

  const CryptoNews({
    required this.id,
    required this.title,
    required this.body,
    required this.url,
    this.imageUrl,
    required this.source,
    required this.publishedOn,
    required this.categories,
    required this.tags,
    required this.lang,
  });

  factory CryptoNews.fromJson(Map<String, dynamic> json) {
    return CryptoNews(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      source: json['source']?.toString() ?? '',
      publishedOn: DateTime.fromMillisecondsSinceEpoch(
        (json['publishedOn'] as num?)?.toInt() ?? 0,
      ),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      lang: json['lang']?.toString() ?? 'EN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'url': url,
      'imageUrl': imageUrl,
      'source': source,
      'publishedOn': publishedOn.millisecondsSinceEpoch,
      'categories': categories,
      'tags': tags,
      'lang': lang,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedOn);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get shortBody {
    if (body.length <= 150) return body;
    return '${body.substring(0, 147)}...';
  }

  @override
  String toString() {
    return 'CryptoNews{id: $id, title: $title, source: $source, publishedOn: $publishedOn}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CryptoNews &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
