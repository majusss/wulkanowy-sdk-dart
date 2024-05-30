import 'package:test/test.dart';
import 'package:wulkanowy/sdk.dart';

void main() {
  group('Standard login', () {
    late WulkanowySdk sdk;

    setUp(() {
      sdk = WulkanowySdk('https', 'wulkanowy.net.pl');
    });

    test('should successfully login', () async {
      final login =
          await sdk.login('jan@fakelog.cf', 'jan123', 'powiatwulkanowy');
      expect(login, isNotEmpty);
    });
  });
}
