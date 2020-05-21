const std = @import("std");
const win32 = std.os.windows;

// TYPE DEFS

pub const DWORD = win32.DWORD;
pub const HBRUSH = win32.HBRUSH;
pub const HCURSOR = win32.HCURSOR;
pub const HICON = win32.HICON;
pub const HINSTANCE = win32.HINSTANCE;
pub const HMENU = win32.HMENU;
pub const HWND = win32.HWND;
pub const INT = win32.INT;
pub const LPARAM = win32.LPARAM;
pub const LPCSTR = win32.LPCSTR;
pub const LPVOID = win32.LPVOID;
pub const LRESULT = win32.LRESULT;
pub const PWSTR = win32.PWSTR;
pub const UINT = win32.UINT;
pub const WPARAM = win32.WPARAM;

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

// Function Definitions
pub const WNDPROC = fn (HWND, UINT, WPARAM, LPARAM) callconv(.Stdcall) LRESULT;
pub extern "user32" fn RegisterClassExA(*const WNDCLASSEXA) callconv(.Stdcall) c_ushort;
pub extern "user32" fn CreateWindowExA(DWORD, LPCSTR, LPCSTR, DWORD, i32, i32, i32, i32, ?HWND, ?HMENU, HINSTANCE, ?LPVOID) callconv(.Stdcall) ?HWND;
pub extern "user32" fn PeekMessageA(*MSG, HWND, u32, u32, u32) callconv(.Stdcall) bool;
pub extern "user32" fn DefWindowProcA(HWND, UINT, WPARAM, LPARAM) callconv(.Stdcall) LRESULT;
pub extern "user32" fn TranslateMessage(*MSG) callconv(.Stdcall) bool;
pub extern "user32" fn DispatchMessageA(*MSG) callconv(.Stdcall) LRESULT;
pub extern "kernel32" fn OutputDebugStringA([*:0]const u8) void;
// Extern Function Definitions

///
/// ACTUAL CODE
///
pub const WindowError = error{FailedTOCreateWindow};
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
            return WindowError.FailedTOCreateWindow;
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
