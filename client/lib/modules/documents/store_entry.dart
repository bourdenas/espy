import 'package:fixnum/fixnum.dart';

class StoreEntry {
  final Int64 id;
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
          id: Int64(json['id']!),
          title: json['title']!,
          storefront: json['storefront_name']!,
          url: json['url'],
          image: json['image'],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'storefront': storefront,
      if (url != null) 'url': url,
      if (image != null) 'image': image,
    };
  }
}
