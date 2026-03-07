import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Native Windows environment variable control using dart:ffi.
/// Used to set process-level environment variables for native libraries like WebView2.
class NativeEnv {
  static final _kernel32 = DynamicLibrary.open('kernel32.dll');

  // BOOL SetEnvironmentVariableW(LPCWSTR lpName, LPCWSTR lpValue)
  static final _setEnvironmentVariable = _kernel32.lookupFunction<
      Int32 Function(Pointer<Utf16> lpName, Pointer<Utf16> lpValue),
      int Function(Pointer<Utf16> lpName, Pointer<Utf16> lpValue)>('SetEnvironmentVariableW');

  /// Set a Windows environment variable for the current process
  static bool set(String name, String value) {
    if (!Platform.isWindows) return false;
    
    final nativeName = name.toNativeUtf16();
    final nativeValue = value.toNativeUtf16();

    final result = _setEnvironmentVariable(nativeName, nativeValue);

    calloc.free(nativeName);
    calloc.free(nativeValue);

    return result != 0;
  }
}
