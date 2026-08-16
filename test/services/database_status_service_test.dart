import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/database_status_port.dart';
import 'package:legado_flutter/services/database_status_service.dart';

void main() {
  tearDown(DatabaseStatusService.resetPort);

  test('database status service exposes the application readiness contract', () {
    DatabaseStatusService.configurePort(const _FakeDatabaseStatusPort(true));
    expect(DatabaseStatusService.isReady, isTrue);

    DatabaseStatusService.configurePort(const _FakeDatabaseStatusPort(false));
    expect(DatabaseStatusService.isReady, isFalse);
  });
}

class _FakeDatabaseStatusPort implements DatabaseStatusPort {
  const _FakeDatabaseStatusPort(this.isReady);

  @override
  final bool isReady;
}
