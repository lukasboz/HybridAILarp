import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('navigator.gpu')
external JSObject? get _gpu;
@JS('navigator.gpu.requestAdapter')
external JSPromise<JSObject?> _requestAdapter();
@JS('meetLoadLocalAI')
external JSPromise<JSAny?> _loadRuntime();

Future<String?> localAIUnavailableReason() async {
  if (!web.window.isSecureContext || _gpu == null) {
    return 'Local AI needs a secure browser with WebGPU. Try a recent Chrome or Edge browser, or use manual preferences or optional cloud AI.';
  }
  try {
    if (await _requestAdapter().toDart == null) {
      return 'This browser has no available WebGPU adapter. Manual preferences and optional cloud AI still work.';
    }
  } catch (_) {
    return 'This browser cannot access its GPU for local AI. Manual preferences and optional cloud AI still work.';
  }
  try {
    await _loadRuntime().toDart;
  } catch (_) {
    return 'The local AI browser runtime could not load. Connect once to prepare it, then try again.';
  }
  return null;
}
