import 'package:wulkanowy/src/login/login_helper.dart';

class WulkanowySdk {
  final String schema, host;
  WulkanowySdk(this.schema, this.host);

  Future<String> login(String name, String password, String symbol) async {
    final loginHelper = LoginHelper(schema, host, symbol);
    final user = await loginHelper.login(name, password);
    return user;
  }
}
