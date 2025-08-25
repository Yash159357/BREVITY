class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profileImageUrl;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.emailVerified = false,
    this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
  });

  // Convert to map for sending data to the backend
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
    };
  }

  // ✅ Add fromMap for deserialization
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      emailVerified: map['emailVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null,
      profileImageUrl: map['profileImageUrl'],
    );
  }

  // Create empty user
  factory UserModel.empty() {
    return UserModel(
      uid: '',
      displayName: '',
      email: '',
    );
  }

  // Add copyWith method
  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
