enum UserRole {
  wife('Wife', 'wife'),
  husband('Husband', 'husband');

  final String displayName;
  final String code;
  const UserRole(this.displayName, this.code);

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.wife;
    final normalized = value.trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.code == normalized || role.name.toLowerCase() == normalized) {
        return role;
      }
    }
    return UserRole.wife;
  }
}
