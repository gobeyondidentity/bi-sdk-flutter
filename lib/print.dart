import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('embeddedsdk_method_channel');

Future<void> _methodCallHandler(MethodCall call) async {
  switch (call.method) {
    case 'debugPrint':
      biDebugPrint(call.arguments["message"]);
      break;
    case 'print':
      biPrint(call.arguments["message"]);
      break;
    default:
      biPrint(
          "No implementation found for method ${call.method} on channel ${_channel.name}");
  }
}

void biDebugPrint(Object? object) {
  // ignore: avoid_print
  debugPrint("bi-sdk-flutter: $object");
}

void biPrint(Object? object) {
  // ignore: avoid_print
  print("bi-sdk-flutter: $object");
}

Future<Function> enablePrinting() async {
  _channel.setMethodCallHandler(_methodCallHandler);

  return () {};
}
