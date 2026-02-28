enum UserRole { donor, ngo, volunteer }

extension UserRoleX on UserRole {
  String get key {
    switch (this) {
      case UserRole.donor:
        return 'donor';
      case UserRole.ngo:
        return 'ngo';
      case UserRole.volunteer:
        return 'volunteer';
    }
  }

  String get label {
    switch (this) {
      case UserRole.donor:
        return 'Donor';
      case UserRole.ngo:
        return 'NGO/Charity';
      case UserRole.volunteer:
        return 'Volunteer';
    }
  }
}
