import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_nearby_connections');
  TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (_) async => '42');
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, (_) => null);
  });

  test('getPlatformVersion', () async {});
}
