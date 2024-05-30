# VULCAN UONET+ SDK in Dart

## Usage

A simple usage example:

```dart
import 'package:wulkanowy/sdk.dart';

void main() async {
  final sdk = WulkanowySdk('https', 'vulcan.net.pl');
  print(await sdk.login('login', 'password', 'powiatjaroslawski'));
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/wulkanowy/sdk-dart/issues
