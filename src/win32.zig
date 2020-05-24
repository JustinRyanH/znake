const std = @import("std");
const win32 = std.os.windows;

// TYPE DEFS

pub const DWORD = win32.DWORD;
pub const HBRUSH = win32.HBRUSH;
pub const HCURSOR = win32.HCURSOR;
pub const HICON = win32.HICON;
pub const HDC = win32.HDC;
pub const HINSTANCE = win32.HINSTANCE;
pub const HMENU = win32.HMENU;
pub const HWND = win32.HWND;
pub const INT = win32.INT;
pub const LONG = win32.LONG;
pub const LPARAM = win32.LPARAM;
pub const LPCSTR = win32.LPCSTR;
pub const LPVOID = win32.LPVOID;
pub const LRESULT = win32.LRESULT;
pub const PWSTR = win32.PWSTR;
pub const UINT = win32.UINT;
pub const WORD = win32.WORD;
pub const WPARAM = win32.WPARAM;
pub const SIZE_T = win32.SIZE_T;

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

pub extern "kernel32" fn VirtualAlloc(lpAddress: ?LPVOID, dwSize: usize, flAllocationType: DWORD, flProtect: DWORD) ?LPVOID;
pub extern "kernel32" fn VirtualFree(lpAddress: LPVOID, dwSize: usize, dwFreeType: DWORD) BOOL;
pub extern "kernel32" fn OutputDebugStringA([*:0]const u8) void;

pub extern "gdi32" fn StretchDIBits(hdc: HDC, xDest: i32, yDest: i32, DestWidth: i32, DestHeight: i32, xSrc: i32, ySrc: i32, SrcWidth: i32, SrcHeight: i32, lpBits: *c_void, lpbmi: *BITMAPINFO, iUsage: UINT, rop: DWORD) i32;

/// Extern Function Definitions
///
/// ACTUAL CODE
///
pub const WindowError = error{
    FailedToCreateWindow,
    FailedToAllocateMemory,
    FailedToUnallocateMemory,
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

pub fn debug(output: [*:0]const u8) void {
    OutputDebugStringA(output);
}
