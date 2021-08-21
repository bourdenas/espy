class Annotation {
  final int id;
  final String name;

  const Annotation({
    required this.id,
    required this.name,
  });

  Annotation.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name'],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
