import 'package:fixnum/fixnum.dart';

class Annotation {
  final Int64 id;
  final String name;

  const Annotation({
    required this.id,
    required this.name,
  });

  Annotation.fromJson(Map<String, dynamic> json)
      : this(
          id: Int64(json['id']),
          name: json['name'],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
