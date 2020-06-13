const std = @import("std");
const StackTrace = @import("builtin").StackTrace;
const page_allocator = std.heap.page_allocator;
const win32 = std.os.windows;

// TYPE DEFS

pub const BOOL = win32.BOOL;
pub const DWORD = win32.DWORD;
pub const HBRUSH = win32.HBRUSH;
pub const HCURSOR = win32.HCURSOR;
pub const HICON = win32.HICON;
pub const HDC = win32.HDC;
pub const HMODULE = win32.HMODULE;
pub const HINSTANCE = win32.HINSTANCE;
pub const HMENU = win32.HMENU;
pub const HWND = win32.HWND;
pub const INT = win32.INT;
pub const LONG = win32.LONG;
pub const LARGE_INTEGER = i64;
pub const LPARAM = i64;
pub const LPCSTR = win32.LPCSTR;
pub const LPVOID = win32.LPVOID;
pub const LRESULT = win32.LRESULT;
pub const PWSTR = win32.PWSTR;
pub const UINT = win32.UINT;
pub const WORD = win32.WORD;
pub const WPARAM = win32.WPARAM;
pub const SIZE_T = win32.SIZE_Tk;
pub const FARPROC = c_longlong;

pub const BI_RGB = 0;
pub const BI_RLE8 = 1;
pub const BI_RLE4 = 2;
pub const BI_BITFIELDS = 3;
pub const BI_JPEG = 4;
pub const BI_PNG = 5;

pub const POINT = extern struct {
    x: u32,
    y: u32,
};

pub const RECT = extern struct {
    left: LONG,
    top: LONG,
    right: LONG,
    bottom: LONG,
};

pub const MSG = extern struct {
    hWnd: ?HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
    lPrivate: DWORD,
};

const WNDCLASSEXA = extern struct {
    cbSize: UINT = @sizeOf(WNDCLASSEXA),
    style: UINT = 0,
    lpfnWndProc: WNDPROC,
    cbClsExtra: i32 = 0,
    cbWndExtra: i32 = 0,
    hInstance: ?HINSTANCE = null,
    hIcon: ?HICON = null,
    hCursor: ?HCURSOR = null,
    hbrBackground: ?HBRUSH = null,
    lpszMenuName: ?LPCSTR = null,
    lpszClassName: ?LPCSTR = null,
    hIconSm: ?HICON = null,
};

pub const RGBQUAD = extern struct {
    rgbBlue: u8 = 0,
    rgbGreen: u8 = 0,
    rgbRed: u8 = 0,
    rgbReserved: u8 = 0,
};

pub const BITMAPINFOHEADER = extern struct {
    biSize: DWORD = @sizeOf(BITMAPINFOHEADER),
    biWidth: LONG,
    biHeight: LONG,
    biPlanes: WORD = 1,
    biBitCount: WORD = 32,
    biCompression: DWORD = BI_RGB,
    biSizeImage: DWORD = 0,
    biXPelsPerMeter: LONG = 0,
    biYPelsPerMeter: LONG = 0,
    biClrUsed: DWORD = 0,
    biClrImportant: DWORD = 0,
};

pub const BITMAPINFO = extern struct {
    bmiHeader: BITMAPINFOHEADER,
    bmiColors: [1]RGBQUAD,
};

// Enum Definitions

/// Based On the Win32 Styles
/// https://docs.microsoft.com/en-us/windows/win32/winmsg/window-styles
pub const WS_BORDER = 0x00800000;
pub const WS_CAPTION = 0x00C00000;
pub const WS_CHILD = 0x40000000;
pub const WS_CHILDWINDOW = 0x40000000;
pub const WS_CLIPCHILDREN = 0x02000000;
pub const WS_CLIPSIBLINGS = 0x04000000;
pub const WS_DISABLED = 0x08000000;
pub const WS_DLGFRAME = 0x00400000;
pub const WS_GROUP = 0x00020000;
pub const WS_HSCROLL = 0x00100000;
pub const WS_ICONIC = 0x20000000;
pub const WS_MAXIMIZE = 0x01000000;
pub const WS_MAXIMIZEBOX = 0x00010000;
pub const WS_MINIMIZE = 0x20000000;
pub const WS_MINIMIZEBOX = 0x00020000;
pub const WS_OVERLAPPED = 0x00000000;
pub const WS_POPUP = 0x80000000;
pub const WS_SIZEBOX = 0x00040000;
pub const WS_SYSMENU = 0x00080000;
pub const WS_TABSTOP = 0x00010000;
pub const WS_THICKFRAME = 0x00040000;
pub const WS_TILED = 0x00000000;
pub const WS_VISIBLE = 0x10000000;
pub const WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
pub const WS_TILEDWINDOW = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
pub const WS_POPUPWINDOW = (WS_POPUP | WS_BORDER | WS_SYSMENU);

/// Based on the Win32 PeekMessage
/// https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-peekmessagea
pub const PM_NOREMOVE = 0x0000;
pub const PM_REMOVE = 0x0001;
pub const PM_NOYIELD = 0x0002;

/// Window Messages
pub const WM_NULL = 0x0000;
pub const WM_CREATE = 0x0001;
pub const WM_DESTROY = 0x0002;
pub const WM_MOVE = 0x0003;
pub const WM_SIZE = 0x0005;
pub const WM_SETFOCUS = 0x0007;
pub const WM_KILLFOCUS = 0x0008;
pub const WM_ENABLE = 0x000A;
pub const WM_SETREDRAW = 0x000B;
pub const WM_SETTEXT = 0x000C;
pub const WM_GETTEXT = 0x000D;
pub const WM_GETTEXTLENGTH = 0x000E;
pub const WM_PAINT = 0x000F;
pub const WM_CLOSE = 0x0010;
pub const WM_QUIT = 0x0012;
pub const WM_ERASEBKGND = 0x0014;
pub const WM_SYSCOLORCHANGE = 0x0015;
pub const WM_SHOWWINDOW = 0x0018;
pub const WM_WININICHANGE = 0x001A;
pub const WM_NCDESTROY = 0x0082;
pub const WM_KEYDOWN = 0x0100;
pub const WM_KEYUP = 0x0101;
pub const WM_SYSKEYDOWN = 0x0104;
pub const WM_SYSKEYUP = 0x0105;
pub const WM_SYSCOMMAND = 0x0112;
pub const WM_ENTERSIZEMOVE = 0x0231;
pub const WM_EXITSIZEMOVE = 0x0232;

pub const CW_USEDEFAULT: i32 = -0x80000000;

pub const CS_HREDRAW = 0x0002;
pub const CS_VREDRAW = 0x0001;
pub const CS_OWNDC = 0x0020;

pub const MEM_COMMIT = 0x00001000;
pub const MEM_RESERVE = 0x00002000;
pub const MEM_REPLACE_PLACEHOLDER = 0x00004000;
pub const MEM_RESERVE_PLACEHOLDER = 0x00040000;
pub const MEM_RESET = 0x00080000;
pub const MEM_TOP_DOWN = 0x00100000;
pub const MEM_WRITE_WATCH = 0x00200000;
pub const MEM_PHYSICAL = 0x00400000;
pub const MEM_ROTATE = 0x00800000;
pub const MEM_DIFFERENT_IMAGE_BASE_OK = 0x00800000;
pub const MEM_RESET_UNDO = 0x01000000;
pub const MEM_LARGE_PAGES = 0x20000000;
pub const MEM_4MB_PAGES = 0x80000000;
pub const MEM_64K_PAGES = (MEM_LARGE_PAGES | MEM_PHYSICAL);
pub const MEM_UNMAP_WITH_TRANSIENT_BOOST = 0x00000001;
pub const MEM_COALESCE_PLACEHOLDERS = 0x00000001;
pub const MEM_PRESERVE_PLACEHOLDER = 0x00000002;
pub const MEM_DECOMMIT = 0x00004000;
pub const MEM_RELEASE = 0x00008000;
pub const MEM_FREE = 0x00010000;

pub const PAGE_NOACCESS = 0x01;
pub const PAGE_READONLY = 0x02;
pub const PAGE_READWRITE = 0x04;
pub const PAGE_WRITECOPY = 0x08;
pub const PAGE_EXECUTE = 0x10;
pub const PAGE_EXECUTE_READ = 0x20;
pub const PAGE_EXECUTE_READWRITE = 0x40;
pub const PAGE_EXECUTE_WRITECOPY = 0x80;
pub const PAGE_GUARD = 0x100;
pub const PAGE_NOCACHE = 0x200;
pub const PAGE_WRITECOMBINE = 0x400;
pub const PAGE_GRAPHICS_NOACCESS = 0x0800;
pub const PAGE_GRAPHICS_READONLY = 0x1000;
pub const PAGE_GRAPHICS_READWRITE = 0x2000;
pub const PAGE_GRAPHICS_EXECUTE = 0x4000;
pub const PAGE_GRAPHICS_EXECUTE_READ = 0x8000;
pub const PAGE_GRAPHICS_EXECUTE_READWRITE = 0x10000;
pub const PAGE_GRAPHICS_COHERENT = 0x20000;
pub const PAGE_ENCLAVE_THREAD_CONTROL = 0x80000000;
pub const PAGE_REVERT_TO_FILE_MAP = 0x80000000;
pub const PAGE_TARGETS_NO_UPDATE = 0x40000000;
pub const PAGE_TARGETS_INVALID = 0x40000000;
pub const PAGE_ENCLAVE_UNVALIDATED = 0x20000000;
pub const PAGE_ENCLAVE_DECOMMIT = 0x10000000;

// /*
//  * Virtual Keys, Standard Set
//  */
pub const VK_LBUTTON = 0x01;
pub const VK_RBUTTON = 0x02;
pub const VK_CANCEL = 0x03;
pub const VK_MBUTTON = 0x04;
pub const VK_XBUTTON1 = 0x05;
pub const VK_XBUTTON2 = 0x06;
pub const VK_BACK = 0x08;
pub const VK_TAB = 0x09;
pub const VK_CLEAR = 0x0C;
pub const VK_RETURN = 0x0D;
pub const VK_SHIFT = 0x10;
pub const VK_CONTROL = 0x11;
pub const VK_MENU = 0x12;
pub const VK_PAUSE = 0x13;
pub const VK_CAPITAL = 0x14;
pub const VK_KANA = 0x15;
pub const VK_HANGEUL = 0x15;
pub const VK_HANGUL = 0x15;
pub const VK_JUNJA = 0x17;
pub const VK_FINAL = 0x18;
pub const VK_HANJA = 0x19;
pub const VK_KANJI = 0x19;
pub const VK_ESCAPE = 0x1B;

pub const VK_CONVERT = 0x1C;
pub const VK_NONCONVERT = 0x1D;
pub const VK_ACCEPT = 0x1E;
pub const VK_MODECHANGE = 0x1F;

pub const VK_SPACE = 0x20;
pub const VK_PRIOR = 0x21;
pub const VK_NEXT = 0x22;
pub const VK_END = 0x23;
pub const VK_HOME = 0x24;
pub const VK_LEFT = 0x25;
pub const VK_UP = 0x26;
pub const VK_RIGHT = 0x27;
pub const VK_DOWN = 0x28;
pub const VK_SELECT = 0x29;
pub const VK_PRINT = 0x2A;
pub const VK_EXECUTE = 0x2B;
pub const VK_SNAPSHOT = 0x2C;
pub const VK_INSERT = 0x2D;
pub const VK_DELETE = 0x2E;
pub const VK_HELP = 0x2F;
pub const VK_NUMPAD0 = 0x60;
pub const VK_NUMPAD1 = 0x61;
pub const VK_NUMPAD2 = 0x62;
pub const VK_NUMPAD3 = 0x63;
pub const VK_NUMPAD4 = 0x64;
pub const VK_NUMPAD5 = 0x65;
pub const VK_NUMPAD6 = 0x66;
pub const VK_NUMPAD7 = 0x67;
pub const VK_NUMPAD8 = 0x68;
pub const VK_NUMPAD9 = 0x69;
pub const VK_MULTIPLY = 0x6A;
pub const VK_ADD = 0x6B;
pub const VK_SEPARATOR = 0x6C;
pub const VK_SUBTRACT = 0x6D;
pub const VK_DECIMAL = 0x6E;
pub const VK_DIVIDE = 0x6F;
pub const VK_F1 = 0x70;
pub const VK_F2 = 0x71;
pub const VK_F3 = 0x72;
pub const VK_F4 = 0x73;
pub const VK_F5 = 0x74;
pub const VK_F6 = 0x75;
pub const VK_F7 = 0x76;
pub const VK_F8 = 0x77;
pub const VK_F9 = 0x78;
pub const VK_F10 = 0x79;
pub const VK_F11 = 0x7A;
pub const VK_F12 = 0x7B;
pub const VK_F13 = 0x7C;
pub const VK_F14 = 0x7D;
pub const VK_F15 = 0x7E;
pub const VK_F16 = 0x7F;
pub const VK_F17 = 0x80;
pub const VK_F18 = 0x81;
pub const VK_F19 = 0x82;
pub const VK_F20 = 0x83;
pub const VK_F21 = 0x84;
pub const VK_F22 = 0x85;
pub const VK_F23 = 0x86;
pub const VK_F24 = 0x87;
pub const VK_NAVIGATION_VIEW = 0x88; // reserved
pub const VK_NAVIGATION_MENU = 0x89; // reserved
pub const VK_NAVIGATION_UP = 0x8A; // reserved
pub const VK_NAVIGATION_DOWN = 0x8B; // reserved
pub const VK_NAVIGATION_LEFT = 0x8C; // reserved
pub const VK_NAVIGATION_RIGHT = 0x8D; // reserved
pub const VK_NAVIGATION_ACCEPT = 0x8E; // reserved
pub const VK_NAVIGATION_CANCEL = 0x8F; // reserved
pub const VK_NUMLOCK = 0x90;
pub const VK_SCROLL = 0x91;
pub const VK_OEM_FJ_JISHO = 0x92; // 'Dictionary' key
pub const VK_OEM_FJ_MASSHOU = 0x93; // 'Unregister word' key
pub const VK_OEM_FJ_TOUROKU = 0x94; // 'Register word' key
pub const VK_OEM_FJ_LOYA = 0x95; // 'Left OYAYUBI' key
pub const VK_OEM_FJ_ROYA = 0x96; // 'Right OYAYUBI' key
pub const VK_LSHIFT = 0xA0;
pub const VK_RSHIFT = 0xA1;
pub const VK_LCONTROL = 0xA2;
pub const VK_RCONTROL = 0xA3;
pub const VK_LMENU = 0xA4;
pub const VK_RMENU = 0xA5;
pub const VK_BROWSER_BACK = 0xA6;
pub const VK_BROWSER_FORWARD = 0xA7;
pub const VK_BROWSER_REFRESH = 0xA8;
pub const VK_BROWSER_STOP = 0xA9;
pub const VK_BROWSER_SEARCH = 0xAA;
pub const VK_BROWSER_FAVORITES = 0xAB;
pub const VK_BROWSER_HOME = 0xAC;
pub const VK_VOLUME_MUTE = 0xAD;
pub const VK_VOLUME_DOWN = 0xAE;
pub const VK_VOLUME_UP = 0xAF;
pub const VK_MEDIA_NEXT_TRACK = 0xB0;
pub const VK_MEDIA_PREV_TRACK = 0xB1;
pub const VK_MEDIA_STOP = 0xB2;
pub const VK_MEDIA_PLAY_PAUSE = 0xB3;
pub const VK_LAUNCH_MAIL = 0xB4;
pub const VK_LAUNCH_MEDIA_SELECT = 0xB5;
pub const VK_LAUNCH_APP1 = 0xB6;
pub const VK_LAUNCH_APP2 = 0xB7;
pub const VK_OEM_1 = 0xBA; // ';:' for US
pub const VK_OEM_PLUS = 0xBB; // '+' any country
pub const VK_OEM_COMMA = 0xBC; // ',' any country
pub const VK_OEM_MINUS = 0xBD; // '-' any country
pub const VK_OEM_PERIOD = 0xBE; // '.' any country
pub const VK_OEM_2 = 0xBF; // '/?' for US
pub const VK_OEM_3 = 0xC0; // '`~' for US
pub const VK_OEM_4 = 0xDB; //  '[{' for US
pub const VK_OEM_5 = 0xDC; //  '\|' for US
pub const VK_OEM_6 = 0xDD; //  ']}' for US
pub const VK_OEM_7 = 0xDE; //  ''"' for US
pub const VK_OEM_8 = 0xDF;
pub const VK_OEM_AX = 0xE1; //  'AX' key on Japanese AX kbd
pub const VK_OEM_102 = 0xE2; //  "<>" or "\|" on RT 102-key kbd.
pub const VK_ICO_HELP = 0xE3; //  Help key on ICO
pub const VK_ICO_00 = 0xE4; //  00 key on ICO
pub const VK_PROCESSKEY = 0xE5;
pub const VK_ICO_CLEAR = 0xE6;
pub const VK_PACKET = 0xE7;
pub const VK_OEM_RESET = 0xE9;
pub const VK_OEM_JUMP = 0xEA;
pub const VK_OEM_PA1 = 0xEB;
pub const VK_OEM_PA2 = 0xEC;
pub const VK_OEM_PA3 = 0xED;
pub const VK_OEM_WSCTRL = 0xEE;
pub const VK_OEM_CUSEL = 0xEF;
pub const VK_OEM_ATTN = 0xF0;
pub const VK_OEM_FINISH = 0xF1;
pub const VK_OEM_COPY = 0xF2;
pub const VK_OEM_AUTO = 0xF3;
pub const VK_OEM_ENLW = 0xF4;
pub const VK_OEM_BACKTAB = 0xF5;
pub const VK_ATTN = 0xF6;
pub const VK_CRSEL = 0xF7;
pub const VK_EXSEL = 0xF8;
pub const VK_EREOF = 0xF9;
pub const VK_PLAY = 0xFA;
pub const VK_ZOOM = 0xFB;
pub const VK_NONAME = 0xFC;
pub const VK_PA1 = 0xFD;
pub const VK_OEM_CLEAR = 0xFE;

pub const DIB_RGB_COLORS = 0;
pub const DIB_PAL_COLORS = 1;

pub const SRCCOPY: DWORD = 0x00CC0020;
pub const SRCPAINT: DWORD = 0x00EE0086;
pub const SRCAND: DWORD = 0x008800C6;
pub const SRCINVERT: DWORD = 0x00660046;
pub const SRCERASE: DWORD = 0x00440328;
pub const NOTSRCCOPY: DWORD = 0x00330008;
pub const NOTSRCERASE: DWORD = 0x001100A6;
pub const MERGECOPY: DWORD = 0x00C000CA;
pub const MERGEPAINT: DWORD = 0x00BB0226;
pub const PATCOPY: DWORD = 0x00F00021;
pub const PATPAINT: DWORD = 0x00FB0A09;
pub const PATINVERT: DWORD = 0x005A0049;
pub const DSTINVERT: DWORD = 0x00550009;
pub const BLACKNESS: DWORD = 0x00000042;
pub const WHITENESS: DWORD = 0x00FF0062;

// Function Definitions
pub const WNDPROC = fn (HWND, UINT, WPARAM, LPARAM) callconv(.Stdcall) LRESULT;
pub extern "user32" fn RegisterClassExA(*const WNDCLASSEXA) callconv(.Stdcall) c_ushort;
pub extern "user32" fn CreateWindowExA(DWORD, LPCSTR, LPCSTR, DWORD, i32, i32, i32, i32, ?HWND, ?HMENU, HINSTANCE, ?LPVOID) callconv(.Stdcall) ?HWND;
pub extern "user32" fn PeekMessageA(*MSG, HWND, u32, u32, u32) callconv(.Stdcall) bool;
pub extern "user32" fn DefWindowProcA(HWND, UINT, WPARAM, LPARAM) callconv(.Stdcall) LRESULT;
pub extern "user32" fn TranslateMessage(*MSG) callconv(.Stdcall) bool;
pub extern "user32" fn DispatchMessageA(*MSG) callconv(.Stdcall) LRESULT;
pub extern "user32" fn GetDC(hWnd: HWND) HDC;
pub extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) BOOL;

pub extern "kernel32" fn VirtualAlloc(lpAddress: ?LPVOID, dwSize: usize, flAllocationType: DWORD, flProtect: DWORD) ?LPVOID;
pub extern "kernel32" fn VirtualFree(lpAddress: LPVOID, dwSize: usize, dwFreeType: DWORD) BOOL;
pub extern "kernel32" fn OutputDebugStringA([*:0]const u8) void;
pub extern "kernel32" fn QueryPerformanceCounter(*LARGE_INTEGER) bool;
pub extern "kernel32" fn QueryPerformanceFrequency(*LARGE_INTEGER) bool;
pub extern "kernel32" fn LoadLibraryA([*:0]const u8) ?HMODULE;

pub extern "gdi32" fn StretchDIBits(hdc: HDC, xDest: i32, yDest: i32, DestWidth: i32, DestHeight: i32, xSrc: i32, ySrc: i32, SrcWidth: i32, SrcHeight: i32, lpBits: *c_void, lpbmi: *BITMAPINFO, iUsage: UINT, rop: DWORD) i32;
pub extern "gdi32" fn PatBlt(hdc: HDC, x: c_int, y: c_int, w: c_int, h: c_int, rop: DWORD) BOOL;

// Minimum timer resolution, in milliseconds, for the application or device driver. A lower value specifies a higher (more accurate) resolution.
pub extern "Winmm" fn timeBeginPeriod(u32) u32;
// Minimum timer resolution specified in the previous call to the timeBeginPeriod function.
pub extern "Winmm" fn timeEndPeriod(u32) u32;

/// Extern Function Definitions
///
/// ACTUAL CODE
///
pub const WindowError = error{
    FailedToCreateWindow,
    FailedToAllocateMemory,
    FailedToUnallocateMemory,
    LibraryLoadError,
    TimerNoCanDo,
};
pub const Win32Message = MSG;

pub const Win32Config = struct {
    wnd_proc: WNDPROC,
    style: DWORD = CS_HREDRAW | CS_VREDRAW | CS_OWNDC,
    window_name: LPCSTR,
    window_class_name: LPCSTR,
    display_style: DWORD = WS_OVERLAPPEDWINDOW | WS_VISIBLE,
    x: i32 = CW_USEDEFAULT,
    y: i32 = CW_USEDEFAULT,
    width: i32 = CW_USEDEFAULT,
    height: i32 = CW_USEDEFAULT,
    h_instance: HINSTANCE,
};

pub const Window = struct {
    const Self = @This();
    window: HWND,
    msg: Win32Message = undefined,

    pub fn init(config: Win32Config) !Window {
        const window_class = WNDCLASSEXA{
            .style = config.style,
            .lpfnWndProc = config.wnd_proc,
            .hInstance = config.h_instance,
            .lpszClassName = config.window_class_name,
        };
        _ = RegisterClassExA(&window_class);

        if (CreateWindowExA(
            0,
            config.window_class_name,
            config.window_name,
            config.display_style,
            config.x,
            config.y,
            config.width,
            config.height,
            null,
            null,
            config.h_instance,
            null,
        )) |window| {
            return Window{
                .window = window,
            };
        } else {
            return WindowError.FailedToCreateWindow;
        }
    }

    pub fn peek_message(self: *Self) ?*Win32Message {
        if (PeekMessageA(&self.msg, self.window, 0, 0, PM_REMOVE)) {
            return &self.msg;
        } else {
            return null;
        }
    }

    pub fn dispatch_message(self: *Self, message: *Win32Message) void {
        _ = TranslateMessage(message);
        _ = DispatchMessageA(message);
    }
};

pub fn debug(comptime fmt: []const u8, args: var) void {
    const output = std.fmt.allocPrint0(page_allocator, fmt, args) catch unreachable;
    OutputDebugStringA(@ptrCast([*:0]const u8, output.ptr));
    page_allocator.free(output);
}

pub inline fn GetWallClock() i64 {
    var result: i64 = 0;
    _ = QueryPerformanceCounter(&result);
    return result;
}

pub inline fn GetFreq() i64 {
    var result: i64 = 0;
    _ = QueryPerformanceFrequency(&result);
    return result;
}

pub fn win32_panic(message: []const u8, stack_trace: ?*StackTrace) noreturn {
    debug("Panic: {}\n{}\n", .{ message, stack_trace });
    std.os.abort();
}

pub fn time_begin_period(period: u32) !void {
    if (timeBeginPeriod(period) != 0) {
        return WindowError.TimerNoCanDo;
    }
}

pub fn time_end_period(period: u32) !void {
    if (timeEndPeriod(period) != 0) {
        return WindowError.TimerNoCanDo;
    }
}
