import 'package:wulkanowy/sdk.dart';

void main() async {
  final sdk = WulkanowySdk('https', 'vulcan.net.pl');
  print(await sdk.login('login', 'password', 'powiatjaroslawski'));
}
