import 'dart:ffi';

Future<String?> localAIUnavailableReason() async {
  final abi = Abi.current();
  if (abi == Abi.androidArm64 || abi == Abi.iosArm64) return null;
  return 'Local AI needs a 64-bit ARM Android phone or iPhone. Manual preferences and optional cloud AI are available here.';
}
