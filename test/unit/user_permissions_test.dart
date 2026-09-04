import 'package:flutter_test/flutter_test.dart';
import 'package:esquadrao_comercial/core/constants/app_enums.dart';
import 'package:esquadrao_comercial/models/user_model.dart';

void main() {
  group('User Roles & Permissions Tests', () {
    test('Admin has full access to Operations Center', () {
      final admin = UserModel(
        id: 'u-admin',
        email: 'admin@esquadrao.com',
        fullName: 'Admin Master',
        role: UserRole.admin,
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isSupervisor, isFalse);
      expect(admin.isOperator, isFalse);
      expect(admin.canAccessAdminPanel, isTrue);
    });

    test('Supervisor can access Operations Center', () {
      final supervisor = UserModel(
        id: 'u-sup',
        email: 'sup@esquadrao.com',
        fullName: 'Supervisor Líder',
        role: UserRole.supervisor,
      );

      expect(supervisor.isAdmin, isFalse);
      expect(supervisor.isSupervisor, isTrue);
      expect(supervisor.canAccessAdminPanel, isTrue);
    });

    test('Operator is strictly redirected to Tinder deck and cannot access admin panel', () {
      final operator = UserModel(
        id: 'u-op',
        email: 'op@esquadrao.com',
        fullName: 'Operador Carlos',
        role: UserRole.operator,
      );

      expect(operator.isOperator, isTrue);
      expect(operator.canAccessAdminPanel, isFalse);
    });
  });
}
