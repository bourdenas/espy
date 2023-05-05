class StoreEntry {
  final String id;
  final String title;
  final String storefront;

  final String? url;
  final String? image;

  StoreEntry({
    required this.id,
    required this.title,
    required this.storefront,
    this.url,
    this.image,
  });

  StoreEntry.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          title: json['title']!,
          storefront: json['storefront_name']!,
          url: json['url'],
          image: json['image'],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'storefront_name': storefront,
      if (url != null) 'url': url,
      if (image != null) 'image': image,
    };
  }
}
