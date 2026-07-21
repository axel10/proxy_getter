import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxy_getter/proxy_getter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  test('Can get system proxy', () async {
    final proxy = await getSystemProxy();
    expect(proxy, isNotNull);
  });
}
