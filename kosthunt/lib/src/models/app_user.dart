enum UserRole {
  customer,
  owner,
  admin,
}

class AppUser {
  const AppUser({
    this.profileId,
    this.authUserId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String? profileId;
  final String? authUserId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  factory AppUser.fromSupabaseAuth({
    required Map<String, Object?> authUser,
    Map<String, Object?>? profile,
  }) {
    final Object? rawMetadata = authUser['user_metadata'];
    final Map<String, Object?> metadata = rawMetadata is Map<dynamic, dynamic>
        ? Map<String, Object?>.from(rawMetadata)
        : <String, Object?>{};
    final String email = _stringValue(authUser['email']) ?? '-';
    return AppUser(
      profileId: _stringValue(profile?['id']),
      authUserId: _stringValue(authUser['id']),
      name: _stringValue(
        profile?['full_name'] ?? metadata['full_name'] ?? metadata['name'],
        fallback: email,
      )!,
      email: email,
      phone: _stringValue(
        profile?['phone'] ?? metadata['phone'],
        fallback: '-',
      )!,
      role: roleFrom(
        _stringValue(profile?['role'] ?? metadata['role']),
      ),
    );
  }

  static UserRole roleFrom(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'owner':
      case 'owner_kost':
      case 'pemilik':
        return UserRole.owner;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String get roleLabel {
    switch (role) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.owner:
        return 'Owner Kost';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static String? _stringValue(Object? value, {String? fallback}) {
    if (value == null) {
      return fallback;
    }
    final String text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
