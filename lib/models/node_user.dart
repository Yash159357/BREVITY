class NodeUser {
  final String id;
  final String name;
  final String email;
  final String? profileImage;

  NodeUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
  });

  factory NodeUser.fromJson(Map<String, dynamic> json) => NodeUser(
        id: json['_id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        profileImage: json['profileImage'] as String?,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'profileImage': profileImage,
      };
}