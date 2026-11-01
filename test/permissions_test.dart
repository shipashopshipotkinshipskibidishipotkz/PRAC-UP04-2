import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/permissions.dart';
import 'package:library_web/models/app_user.dart';

void main() {
  group('Права ролей ПР5', () {
    for (final entry in <(Role, Permission, bool)>[
      (Role.reader, Permission.catalog, true),
      (Role.reader, Permission.ownLoans, true),
      (Role.reader, Permission.renewLoan, true),
      (Role.reader, Permission.editCatalog, false),
      (Role.reader, Permission.users, false),
      (Role.reader, Permission.readers, false),
      (Role.librarian, Permission.editCatalog, true),
      (Role.librarian, Permission.manageLoans, true),
      (Role.librarian, Permission.hardDelete, false),
      (Role.librarian, Permission.users, false),
      (Role.admin, Permission.users, true),
      (Role.admin, Permission.statistics, true),
      (Role.admin, Permission.restore, true),
      (Role.admin, Permission.hardDelete, true),
    ]) {
      test('${entry.$1.name}: ${entry.$2.name} = ${entry.$3}', () {
        expect(allows(entry.$1, entry.$2), entry.$3);
      });
    }
    test('у каждой роли есть собственный раздел', () {
      for (final role in Role.values) {
        expect(allows(role, Permission.ownLoans), role == Role.reader);
        expect(allows(role, Permission.librarianDesk), role == Role.librarian);
        expect(allows(role, Permission.users), role == Role.admin);
      }
    });
    test('анонимному пользователю недоступны защищённые операции', () {
      for (final permission in Permission.values) {
        expect(allows(null, permission), isFalse);
      }
    });
    test('права маршрута определяются до открытия чужой формы', () {
      expect(permissionForPath('/books/new'), Permission.editCatalog);
      expect(permissionForPath('/books/1/edit'), Permission.editCatalog);
      expect(permissionForPath('/admin/users'), Permission.users);
      expect(permissionForPath('/readers/1'), Permission.readers);
    });
    test('адрес возврата допускает внутреннюю ссылку и отклоняет внешнюю', () {
      expect(safeReturnLocation('/books/1?page=2'), '/books/1?page=2');
      for (final value in [
        null,
        '//example.org',
        'https://example.org',
        '/login',
      ]) {
        expect(safeReturnLocation(value), '/');
      }
    });
  });
}
