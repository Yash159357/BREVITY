class NodeArticle {
  final String id;
  final String title;
  final String description;
  final String url;
  final String? urlToImage;
  final DateTime publishedAt;
  final String sourceName;

  NodeArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
    required this.sourceName,
  });

  factory NodeArticle.fromJson(Map<String, dynamic> json) => NodeArticle(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        url: json['url'] ?? '',
        urlToImage: json['urlToImage'],
        publishedAt: DateTime.parse(json['publishedAt']),
        sourceName: json['source']?['name'] ?? 'Unknown',
      );
}