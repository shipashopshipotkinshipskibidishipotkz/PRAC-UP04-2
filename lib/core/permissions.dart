import '../models/app_user.dart';

enum Permission {
  catalog,
  editCatalog,
  readers,
  manageLoans,
  ownLoans,
  renewLoan,
  librarianDesk,
  users,
  statistics,
  hardDelete,
  restore,
}

bool allows(Role? role, Permission permission) {
  if (role == null) return false;
  return switch (permission) {
    Permission.catalog => true,
    Permission.editCatalog ||
    Permission.readers ||
    Permission.manageLoans => role == Role.librarian || role == Role.admin,
    Permission.ownLoans || Permission.renewLoan => role == Role.reader,
    Permission.librarianDesk => role == Role.librarian,
    Permission.users ||
    Permission.statistics ||
    Permission.hardDelete ||
    Permission.restore => role == Role.admin,
  };
}

Permission permissionForPath(String path) {
  if (path.startsWith('/admin/users')) return Permission.users;
  if (path.startsWith('/admin/statistics')) return Permission.statistics;
  if (path == '/desk') return Permission.librarianDesk;
  if (path == '/my-loans') return Permission.ownLoans;
  if (path == '/loans') return Permission.manageLoans;
  if (path.startsWith('/readers')) return Permission.readers;
  if (path.endsWith('/new') || path.endsWith('/edit')) {
    return Permission.editCatalog;
  }
  return Permission.catalog;
}

String safeReturnLocation(String? value) {
  if (value == null) return '/';
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !value.startsWith('/') ||
      value.startsWith('//') ||
      uri.hasScheme ||
      uri.hasAuthority ||
      const ['/login', '/register', '/session'].contains(uri.path)) {
    return '/';
  }
  return uri.toString();
}
