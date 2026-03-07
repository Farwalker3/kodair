import 'dart:ffi';

/// Native Windows cursor control using dart:ffi.
/// Calls user32.dll directly for proper cursor hiding/locking.
class NativeCursor {
  static final _user32 = DynamicLibrary.open('user32.dll');
  static final _kernel32 = DynamicLibrary.open('kernel32.dll');

  // int ShowCursor(BOOL bShow)
  static final _showCursor = _user32.lookupFunction<
      Int32 Function(Int32 bShow),
      int Function(int bShow)>('ShowCursor');

  // BOOL ClipCursor(const RECT *lpRect)
  static final _clipCursor = _user32.lookupFunction<
      Int32 Function(Pointer<_RECT> lpRect),
      int Function(Pointer<_RECT> lpRect)>('ClipCursor');

  // BOOL SetCursorPos(int X, int Y)
  static final _setCursorPos = _user32.lookupFunction<
      Int32 Function(Int32 x, Int32 y),
      int Function(int x, int y)>('SetCursorPos');

  // HWND GetForegroundWindow()
  static final _getForegroundWindow = _user32.lookupFunction<
      IntPtr Function(),
      int Function()>('GetForegroundWindow');

  // BOOL GetWindowRect(HWND hWnd, LPRECT lpRect)
  static final _getWindowRect = _user32.lookupFunction<
      Int32 Function(IntPtr hWnd, Pointer<_RECT> lpRect),
      int Function(int hWnd, Pointer<_RECT> lpRect)>('GetWindowRect');

  // HeapAlloc / HeapFree for memory allocation
  static final _getProcessHeap = _kernel32.lookupFunction<
      IntPtr Function(),
      int Function()>('GetProcessHeap');

  static final _heapAlloc = _kernel32.lookupFunction<
      Pointer Function(IntPtr hHeap, Uint32 dwFlags, IntPtr dwBytes),
      Pointer Function(int hHeap, int dwFlags, int dwBytes)>('HeapAlloc');

  static final _heapFree = _kernel32.lookupFunction<
      Int32 Function(IntPtr hHeap, Uint32 dwFlags, Pointer lpMem),
      int Function(int hHeap, int dwFlags, Pointer lpMem)>('HeapFree');

  static bool _isHidden = false;
  static int _hideCount = 0;

  static Pointer<_RECT> _allocRect() {
    final heap = _getProcessHeap();
    // RECT is 4 x Int32 = 16 bytes
    return _heapAlloc(heap, 0x08 /* HEAP_ZERO_MEMORY */, 16).cast<_RECT>();
  }

  static void _freeRect(Pointer<_RECT> ptr) {
    final heap = _getProcessHeap();
    _heapFree(heap, 0, ptr);
  }

  /// Hide the OS cursor and clip it to the center of the foreground window
  static void hide() {
    if (_isHidden) return;
    _isHidden = true;

    // Hide cursor (ShowCursor uses a counter)
    _hideCount = _showCursor(0);
    while (_hideCount >= 0) {
      _hideCount = _showCursor(0);
    }

    // Clip cursor to a small area in the center of the window
    final hwnd = _getForegroundWindow();
    if (hwnd != 0) {
      final rect = _allocRect();
      _getWindowRect(hwnd, rect);
      final centerX = (rect.ref.left + rect.ref.right) ~/ 2;
      final centerY = (rect.ref.top + rect.ref.bottom) ~/ 2;

      // Clip to a 1px area around center
      rect.ref.left = centerX;
      rect.ref.top = centerY;
      rect.ref.right = centerX + 1;
      rect.ref.bottom = centerY + 1;
      _clipCursor(rect);

      _setCursorPos(centerX, centerY);
      _freeRect(rect);
    }
  }

  /// Show the OS cursor and remove clip
  static void show() {
    if (!_isHidden) return;
    _isHidden = false;

    // Restore cursor (bring counter back to >= 0)
    while (_hideCount < 0) {
      _hideCount = _showCursor(1);
    }

    // Remove cursor clip (null pointer = unclip)
    _clipCursor(Pointer<_RECT>.fromAddress(0));
  }

  static bool get isHidden => _isHidden;
}

// Win32 RECT struct
final class _RECT extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
}
