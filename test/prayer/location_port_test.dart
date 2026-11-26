// The approximate location through the app's own channel (feature 014, FR-004, FR-005, research D3). Errors give null
// or `denied`, never a throw.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/location_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.hafiz.mushaf/location');
  final calls = <String>[];
  Object? Function(MethodCall) answer = (_) => null;

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          final a = answer(call);
          if (a is Exception) throw a;
          return a;
        });
  });

  test('request maps the three answers; an error is denied', () async {
    const port = ChannelLocationPort();
    for (final (raw, want) in [
      ('granted', LocationAsk.granted),
      ('denied', LocationAsk.denied),
      ('deniedForever', LocationAsk.deniedForever),
      ('odd', LocationAsk.denied),
    ]) {
      answer = (_) => raw;
      expect(await port.request(), want);
    }
    answer = (_) => PlatformException(code: 'x');
    expect(await port.request(), LocationAsk.denied);
    expect(calls.toSet(), {'request'});
  });

  test('current returns a pair, null for no reading, null on error', () async {
    const port = ChannelLocationPort();
    answer = (_) => [30.06, 31.25];
    expect(await port.current(), (30.06, 31.25));
    answer = (_) => null;
    expect(await port.current(), isNull);
    answer = (_) => PlatformException(code: 'timeout');
    expect(await port.current(), isNull);
    answer = (_) => 'nonsense';
    expect(await port.current(), isNull);
  });

  test('openSettings calls the channel and never throws', () async {
    const port = ChannelLocationPort();
    answer = (_) => PlatformException(code: 'x');
    await port.openSettings();
    expect(calls, ['openSettings']);
  });

  test('the fake records requests and answers as told', () async {
    final fake = FakeLocationPort(
      ask: LocationAsk.granted,
      reading: (1.0, 2.0),
    );
    expect(await fake.request(), LocationAsk.granted);
    expect(await fake.current(), (1.0, 2.0));
    expect(fake.requests, 1);
  });
}
