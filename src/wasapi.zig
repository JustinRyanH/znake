const std = @import("std");
usingnamespace std.os.windows;

// Data1: c_ulong,
// Data2: c_ushort,
// Data3: c_ushort,
// Data4: [8]u8,
pub const IID_IAudioClient = GUID{
    .Data1 = 0x1CB9AD4C,
    .Data2 = 0xDBFA,
    .Data3 = 0x4c32,
    .Data4 = [_]u8{ 0xB1, 0x78, 0xC2, 0xF5, 0x68, 0xA7, 0x03, 0xB2 },
};
// pub const IID_IAudioRenderClient = GUID{ 0xF294ACFC, 0x3146, 0x4483, 0xA7, 0xBF, 0xAD, 0xDC, 0xA7, 0xC2, 0x60, 0xE2 };

// Data1: c_ulong,
// Data2: c_ushort,
// Data3: c_ushort,
// Data4: [8]u8,
pub const CLSID_MMDeviceEnumerator = GUID{
    .Data1 = 0xBCDE0395,
    .Data2 = 0xE52F,
    .Data3 = 0x467C,
    .Data4 = [_]u8{ 0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E },
};

pub const IID_IMMDeviceEnumerator = GUID{
    .Data1 = 0xA95664D2,
    .Data2 = 0x9614,
    .Data3 = 0x4F35,
    .Data4 = [_]u8{ 0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6 },
};
// pub const IID_IMMDeviceEnumerator = GUID{ 0xA95664D2, 0x9614, 0x4F35, 0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6 };

/// Basic Window Components
pub const IID = GUID;
pub const VARTYPE = c_ushort;
pub const VARIANT_BOOL = c_short;
pub const SCODE = LONG;
pub const CLSID = GUID;
pub const LCID = DWORD;
pub const DATE = f64;
pub const OLECHAR = WCHAR;
pub const LPOLESTR = [*c]OLECHAR;
pub const LPCOLESTR = [*c]const OLECHAR;
pub const BSTR = [*c]OLECHAR;
pub const DISPID = LONG;
pub const MEMBERID = DISPID;
pub const HREFTYPE = DWORD;
pub const MEMBERID_NIL = -1;
pub const REFERENCE_TIME = c_longlong;

pub const ReferenceTime = i64;

pub const EDataFlow = extern enum(c_int) {
    eRender = 0,
    eCapture = 1,
    eAll = 2,
    EDataFlow_enum_count = 3,
    _,
};

pub const BLOB = extern struct {
    cbSize: ULONG,
    pBlobData: [*c]BYTE,
};

pub const CURRENCY = CY;
pub const SAFEARRAYBOUND = extern struct {
    cElements: ULONG,
    lLbound: LONG,
};

pub const BSTRBLOB = extern struct {
    cbSize: ULONG,
    pData: [*c]BYTE,
};
pub const CLIPDATA = extern struct {
    cbSize: ULONG,
    ulClipFmt: LONG,
    pClipData: [*c]BYTE,
};

pub const SAFEARRAY = extern struct {
    cDims: USHORT,
    fFeatures: USHORT,
    cbElements: ULONG,
    cLocks: ULONG,
    pvData: PVOID,
    rgsabound: [1]SAFEARRAYBOUND,
};

pub const TYPEKIND = extern enum(c_int) {
    TKIND_ENUM = 0,
    TKIND_RECORD = 1,
    TKIND_MODULE = 2,
    TKIND_INTERFACE = 3,
    TKIND_DISPATCH = 4,
    TKIND_COCLASS = 5,
    TKIND_ALIAS = 6,
    TKIND_UNION = 7,
    TKIND_MAX = 8,
    _,
};

pub const TKIND_ENUM = @enumToInt(TYPEKIND.TKIND_ENUM);
pub const TKIND_RECORD = @enumToInt(TYPEKIND.TKIND_RECORD);
pub const TKIND_MODULE = @enumToInt(TYPEKIND.TKIND_MODULE);
pub const TKIND_INTERFACE = @enumToInt(TYPEKIND.TKIND_INTERFACE);
pub const TKIND_DISPATCH = @enumToInt(TYPEKIND.TKIND_DISPATCH);
pub const TKIND_COCLASS = @enumToInt(TYPEKIND.TKIND_COCLASS);
pub const TKIND_ALIAS = @enumToInt(TYPEKIND.TKIND_ALIAS);
pub const TKIND_UNION = @enumToInt(TYPEKIND.TKIND_UNION);
pub const TKIND_MAX = @enumToInt(TYPEKIND.TKIND_MAX);

pub const DECIMAL = extern struct {
    wReserved: USHORT,
    unnamed_0: extern union {
        unnamed_0: extern struct {
            scale: BYTE,
            sign: BYTE,
        },
        signscale: USHORT,
    },
    Hi32: ULONG,
    unnamed_1: extern union {
        unnamed_0: extern struct {
            Lo32: ULONG,
            Mid32: ULONG,
        },
        Lo64: ULONGLONG,
    },
};

pub const CY = extern union {
    unnamed_0: extern struct {
        Lo: ULONG,
        Hi: LONG,
    },
    int64: LONGLONG,
};

pub const TYPEDESC = extern struct {
    unnamed_0: extern union {
        lptdesc: [*c]TYPEDESC,
        lpadesc: [*c]extern struct {
            tdescElem: TYPEDESC,
            cDims: USHORT,
            rgbounds: [1]SAFEARRAYBOUND,
        },
        hreftype: HREFTYPE,
    },
    vt: VARTYPE,
};

pub const IDLDESC = extern struct {
    dwReserved: ULONG_PTR,
    wIDLFlags: USHORT,
};

pub const DESCKIND = extern enum(c_int) {
    DESCKIND_NONE = 0,
    DESCKIND_FUNCDESC = 1,
    DESCKIND_VARDESC = 2,
    DESCKIND_TYPECOMP = 3,
    DESCKIND_IMPLICITAPPOBJ = 4,
    DESCKIND_MAX = 5,
    _,
};
pub const DESCKIND_NONE = @enumToInt(DESCKIND.DESCKIND_NONE);
pub const DESCKIND_FUNCDESC = @enumToInt(DESCKIND.DESCKIND_FUNCDESC);
pub const DESCKIND_VARDESC = @enumToInt(DESCKIND.DESCKIND_VARDESC);
pub const DESCKIND_TYPECOMP = @enumToInt(DESCKIND.DESCKIND_TYPECOMP);
pub const DESCKIND_IMPLICITAPPOBJ = @enumToInt(DESCKIND.DESCKIND_IMPLICITAPPOBJ);
pub const DESCKIND_MAX = @enumToInt(DESCKIND.DESCKIND_MAX);

pub const TYPEATTR = extern struct {
    guid: GUID,
    lcid: LCID,
    dwReserved: DWORD,
    memidConstructor: MEMBERID,
    memidDestructor: MEMBERID,
    lpstrSchema: LPOLESTR,
    cbSizeInstance: ULONG,
    typekind: TYPEKIND,
    cFuncs: WORD,
    cVars: WORD,
    cImplTypes: WORD,
    cbSizeVft: WORD,
    cbAlignment: WORD,
    wTypeFlags: WORD,
    wMajorVerNum: WORD,
    wMinorVerNum: WORD,
    tdescAlias: TYPEDESC,
    idldescType: IDLDESC,
};

pub const VARIANT = extern struct {
    unnamed_0: extern union {
        unnamed_0: extern struct {
            vt: VARTYPE,
            wReserved1: WORD,
            wReserved2: WORD,
            wReserved3: WORD,
            unnamed_0: extern union {
                llVal: LONGLONG,
                lVal: LONG,
                bVal: BYTE,
                iVal: SHORT,
                fltVal: FLOAT,
                dblVal: f64,
                boolVal: VARIANT_BOOL,
                __OBSOLETE__VARIANT_BOOL: VARIANT_BOOL,
                scode: SCODE,
                cyVal: CY,
                date: DATE,
                bstrVal: BSTR,
                punkVal: [*c]IUnknown,
                pdispVal: [*c]IDispatch,
                parray: [*c]SAFEARRAY,
                pbVal: [*c]BYTE,
                piVal: [*c]SHORT,
                plVal: [*c]LONG,
                pllVal: [*c]LONGLONG,
                pfltVal: [*c]f32,
                pdblVal: [*c]f64,
                pboolVal: [*c]VARIANT_BOOL,
                __OBSOLETE__VARIANT_PBOOL: [*c]VARIANT_BOOL,
                pscode: [*c]SCODE,
                pcyVal: [*c]CY,
                pdate: [*c]DATE,
                pbstrVal: [*c]BSTR,
                ppunkVal: [*c][*c]IUnknown,
                ppdispVal: [*c][*c]IDispatch,
                pparray: [*c][*c]SAFEARRAY,
                pvarVal: [*c]VARIANT,
                byref: PVOID,
                cVal: CHAR,
                uiVal: USHORT,
                ulVal: ULONG,
                ullVal: ULONGLONG,
                intVal: INT,
                uintVal: UINT,
                pdecVal: [*c]DECIMAL,
                pcVal: [*c]CHAR,
                puiVal: [*c]USHORT,
                pulVal: [*c]ULONG,
                pullVal: [*c]ULONGLONG,
                pintVal: [*c]INT,
                puintVal: [*c]UINT,
                unnamed_0: extern struct {
                    pvRecord: PVOID,
                    pRecInfo: [*c]IRecordInfo,
                },
            },
        },
        decVal: DECIMAL,
    },
};

pub const VARIANTARG = VARIANT;

pub const PARAMDESCEX = extern struct {
    cBytes: ULONG,
    varDefaultValue: VARIANTARG,
};
pub const LPPARAMDESCEX = [*c]PARAMDESCEX;

pub const PARAMDESC = extern struct {
    pparamdescex: LPPARAMDESCEX,
    wParamFlags: USHORT,
};

pub const ELEMDESC = extern struct {
    tdesc: TYPEDESC, unnamed_0: extern union {
        idldesc: IDLDESC,
        paramdesc: PARAMDESC,
    }
};

pub const CALLCONV = extern enum(c_int) {
    CC_FASTCALL = 0,
    CC_CDECL = 1,
    CC_MSCPASCAL = 2,
    CC_PASCAL = 2,
    CC_MACPASCAL = 3,
    CC_STDCALL = 4,
    CC_FPFASTCALL = 5,
    CC_SYSCALL = 6,
    CC_MPWCDECL = 7,
    CC_MPWPASCAL = 8,
    CC_MAX = 9,
    _,
};

pub const FUNCKIND = extern enum(c_int) {
    FUNC_VIRTUAL = 0,
    FUNC_PUREVIRTUAL = 1,
    FUNC_NONVIRTUAL = 2,
    FUNC_STATIC = 3,
    FUNC_DISPATCH = 4,
    _,
};
pub const FUNC_VIRTUAL = @enumToInt(FUNCKIND.FUNC_VIRTUAL);
pub const FUNC_PUREVIRTUAL = @enumToInt(FUNCKIND.FUNC_PUREVIRTUAL);
pub const FUNC_NONVIRTUAL = @enumToInt(FUNCKIND.FUNC_NONVIRTUAL);
pub const FUNC_STATIC = @enumToInt(FUNCKIND.FUNC_STATIC);
pub const FUNC_DISPATCH = @enumToInt(FUNCKIND.FUNC_DISPATCH);

pub const INVOKEKIND = extern enum(c_int) {
    INVOKE_FUNC = 1,
    INVOKE_PROPERTYGET = 2,
    INVOKE_PROPERTYPUT = 4,
    INVOKE_PROPERTYPUTREF = 8,
    _,
};

pub const INVOKE_FUNC = @enumToInt(INVOKEKIND.INVOKE_FUNC);
pub const INVOKE_PROPERTYGET = @enumToInt(INVOKEKIND.INVOKE_PROPERTYGET);
pub const INVOKE_PROPERTYPUT = @enumToInt(INVOKEKIND.INVOKE_PROPERTYPUT);
pub const INVOKE_PROPERTYPUTREF = @enumToInt(INVOKEKIND.INVOKE_PROPERTYPUTREF);

pub const FUNCDESC = extern struct {
    memid: MEMBERID,
    lprgscode: [*c]SCODE,
    lprgelemdescParam: [*c]ELEMDESC,
    funckind: FUNCKIND,
    invkind: INVOKEKIND,
    @"callconv": CALLCONV,
    cParams: SHORT,
    cParamsOpt: SHORT,
    oVft: SHORT,
    cScodes: SHORT,
    elemdescFunc: ELEMDESC,
    wFuncFlags: WORD,
};
pub const LPFUNCDESC = [*c]FUNCDESC;

pub const VARKIND = extern enum(c_int) {
    VAR_PERINSTANCE = 0,
    VAR_STATIC = 1,
    VAR_CONST = 2,
    VAR_DISPATCH = 3,
    _,
};
pub const VAR_PERINSTANCE = @enumToInt(VARKIND.VAR_PERINSTANCE);
pub const VAR_STATIC = @enumToInt(VARKIND.VAR_STATIC);
pub const VAR_CONST = @enumToInt(VARKIND.VAR_CONST);
pub const VAR_DISPATCH = @enumToInt(VARKIND.VAR_DISPATCH);

pub const VARDESC = extern struct {
    memid: MEMBERID,
    lpstrSchema: LPOLESTR,
    unnamed_0: extern union {
        oInst: ULONG,
        lpvarValue: [*c]VARIANT,
    },
    elemdescVar: ELEMDESC,
    wVarFlags: WORD,
    varkind: VARKIND,
};

pub const LPBINDPTR = [*c]BINDPTR;
pub const BINDPTR = extern union {
    lpfuncdesc: [*c]FUNCDESC,
    lpvardesc: [*c]VARDESC,
    lptcomp: [*c]ITypeComp,
};

pub const SYSKIND = extern enum(c_int) {
    SYS_WIN16 = 0,
    SYS_WIN32 = 1,
    SYS_MAC = 2,
    SYS_WIN64 = 3,
    _,
};
pub const SYS_WIN16 = @enumToInt(SYSKIND.SYS_WIN16);
pub const SYS_WIN32 = @enumToInt(SYSKIND.SYS_WIN32);
pub const SYS_MAC = @enumToInt(SYSKIND.SYS_MAC);
pub const SYS_WIN64 = @enumToInt(SYSKIND.SYS_WIN64);

pub const CLSCTX = extern enum(c_int) {
    CLSCTX_INPROC_SERVER = 1,
    CLSCTX_INPROC_HANDLER = 2,
    CLSCTX_LOCAL_SERVER = 4,
    CLSCTX_INPROC_SERVER16 = 8,
    CLSCTX_REMOTE_SERVER = 16,
    CLSCTX_INPROC_HANDLER16 = 32,
    CLSCTX_RESERVED1 = 64,
    CLSCTX_RESERVED2 = 128,
    CLSCTX_RESERVED3 = 256,
    CLSCTX_RESERVED4 = 512,
    CLSCTX_NO_CODE_DOWNLOAD = 1024,
    CLSCTX_RESERVED5 = 2048,
    CLSCTX_NO_CUSTOM_MARSHAL = 4096,
    CLSCTX_ENABLE_CODE_DOWNLOAD = 8192,
    CLSCTX_NO_FAILURE_LOG = 16384,
    CLSCTX_DISABLE_AAA = 32768,
    CLSCTX_ENABLE_AAA = 65536,
    CLSCTX_FROM_DEFAULT_CONTEXT = 131072,
    CLSCTX_ACTIVATE_X86_SERVER = 262144,
    CLSCTX_ACTIVATE_32_BIT_SERVER = 262144,
    CLSCTX_ACTIVATE_64_BIT_SERVER = 524288,
    CLSCTX_ENABLE_CLOAKING = 1048576,
    CLSCTX_APPCONTAINER = 4194304,
    CLSCTX_ACTIVATE_AAA_AS_IU = 8388608,
    CLSCTX_RESERVED6 = 16777216,
    CLSCTX_ACTIVATE_ARM32_SERVER = 33554432,
    CLSCTX_PS_DLL = -2147483648,
    _,
};
pub const CLSCTX_INPROC_SERVER = @enumToInt(CLSCTX.CLSCTX_INPROC_SERVER);
pub const CLSCTX_INPROC_HANDLER = @enumToInt(CLSCTX.CLSCTX_INPROC_HANDLER);
pub const CLSCTX_LOCAL_SERVER = @enumToInt(CLSCTX.CLSCTX_LOCAL_SERVER);
pub const CLSCTX_INPROC_SERVER16 = @enumToInt(CLSCTX.CLSCTX_INPROC_SERVER16);
pub const CLSCTX_REMOTE_SERVER = @enumToInt(CLSCTX.CLSCTX_REMOTE_SERVER);
pub const CLSCTX_INPROC_HANDLER16 = @enumToInt(CLSCTX.CLSCTX_INPROC_HANDLER16);
pub const CLSCTX_RESERVED1 = @enumToInt(CLSCTX.CLSCTX_RESERVED1);
pub const CLSCTX_RESERVED2 = @enumToInt(CLSCTX.CLSCTX_RESERVED2);
pub const CLSCTX_RESERVED3 = @enumToInt(CLSCTX.CLSCTX_RESERVED3);
pub const CLSCTX_RESERVED4 = @enumToInt(CLSCTX.CLSCTX_RESERVED4);
pub const CLSCTX_NO_CODE_DOWNLOAD = @enumToInt(CLSCTX.CLSCTX_NO_CODE_DOWNLOAD);
pub const CLSCTX_RESERVED5 = @enumToInt(CLSCTX.CLSCTX_RESERVED5);
pub const CLSCTX_NO_CUSTOM_MARSHAL = @enumToInt(CLSCTX.CLSCTX_NO_CUSTOM_MARSHAL);
pub const CLSCTX_ENABLE_CODE_DOWNLOAD = @enumToInt(CLSCTX.CLSCTX_ENABLE_CODE_DOWNLOAD);
pub const CLSCTX_NO_FAILURE_LOG = @enumToInt(CLSCTX.CLSCTX_NO_FAILURE_LOG);
pub const CLSCTX_DISABLE_AAA = @enumToInt(CLSCTX.CLSCTX_DISABLE_AAA);
pub const CLSCTX_ENABLE_AAA = @enumToInt(CLSCTX.CLSCTX_ENABLE_AAA);
pub const CLSCTX_FROM_DEFAULT_CONTEXT = @enumToInt(CLSCTX.CLSCTX_FROM_DEFAULT_CONTEXT);
pub const CLSCTX_ACTIVATE_X86_SERVER = @enumToInt(CLSCTX.CLSCTX_ACTIVATE_X86_SERVER);
pub const CLSCTX_ACTIVATE_32_BIT_SERVER = @enumToInt(CLSCTX.CLSCTX_ACTIVATE_32_BIT_SERVER);
pub const CLSCTX_ACTIVATE_64_BIT_SERVER = @enumToInt(CLSCTX.CLSCTX_ACTIVATE_64_BIT_SERVER);
pub const CLSCTX_ENABLE_CLOAKING = @enumToInt(CLSCTX.CLSCTX_ENABLE_CLOAKING);
pub const CLSCTX_APPCONTAINER = @enumToInt(CLSCTX.CLSCTX_APPCONTAINER);
pub const CLSCTX_ACTIVATE_AAA_AS_IU = @enumToInt(CLSCTX.CLSCTX_ACTIVATE_AAA_AS_IU);
pub const CLSCTX_RESERVED6 = @enumToInt(CLSCTX.CLSCTX_RESERVED6);
pub const CLSCTX_ACTIVATE_ARM32_SERVER = @enumToInt(CLSCTX.CLSCTX_ACTIVATE_ARM32_SERVER);
pub const CLSCTX_PS_DLL = @enumToInt(CLSCTX.CLSCTX_PS_DLL);
pub const CLSCTX_ALL = CLSCTX_INPROC_SERVER | (CLSCTX_INPROC_HANDLER | (CLSCTX_LOCAL_SERVER | CLSCTX_REMOTE_SERVER));

pub const LPTYPELIB = [*c]ITypeLib;
pub const TLIBATTR = extern struct {
    guid: GUID,
    lcid: LCID,
    syskind: SYSKIND,
    wMajorVerNum: WORD,
    wMinorVerNum: WORD,
    wLibFlags: WORD,
};

pub const EXCEPINFO = extern struct {
    wCode: WORD,
    wReserved: WORD,
    bstrSource: BSTR,
    bstrDescription: BSTR,
    bstrHelpFile: BSTR,
    dwHelpContext: DWORD,
    pvReserved: PVOID,
    pfnDeferredFillIn: ?fn ([*c]EXCEPINFO) callconv(.C) HRESULT,
    scode: SCODE,
};

pub const DISPPARAMS = extern struct {
    rgvarg: [*c]VARIANTARG,
    rgdispidNamedArgs: [*c]DISPID,
    cArgs: UINT,
    cNamedArgs: UINT,
};

pub const VERSIONEDSTREAM = extern struct {
    guidVersion: GUID,
    pStream: [*c]IStream,
};
pub const LPVERSIONEDSTREAM = [*c]VERSIONEDSTREAM;

pub const CAC = extern struct {
    cElems: ULONG,
    pElems: [*c]CHAR,
};
pub const CAUB = extern struct {
    cElems: ULONG,
    pElems: [*c]UCHAR,
};

pub const CAI = extern struct {
    cElems: ULONG,
    pElems: [*c]SHORT,
};
pub const CAUI = extern struct {
    cElems: ULONG,
    pElems: [*c]USHORT,
};

pub const CAL = extern struct {
    cElems: ULONG,
    pElems: [*c]LONG,
};

pub const CAUL = extern struct {
    cElems: ULONG,
    pElems: [*c]ULONG,
};

pub const CAFLT = extern struct {
    cElems: ULONG,
    pElems: [*c]f32,
};

pub const CADBL = extern struct {
    cElems: ULONG,
    pElems: [*c]f64,
};

pub const CACY = extern struct {
    cElems: ULONG,
    pElems: [*c]CY,
};
pub const CADATE = extern struct {
    cElems: ULONG,
    pElems: [*c]DATE,
};

pub const CABSTR = extern struct {
    cElems: ULONG,
    pElems: [*c]BSTR,
};

pub const CABSTRBLOB = extern struct {
    cElems: ULONG,
    pElems: [*c]BSTRBLOB,
};

pub const CABOOL = extern struct {
    cElems: ULONG,
    pElems: [*c]VARIANT_BOOL,
};

pub const CASCODE = extern struct {
    cElems: ULONG,
    pElems: [*c]SCODE,
};

pub const CAPROPVARIANT = extern struct {
    cElems: ULONG,
    pElems: [*c]PROPVARIANT,
};

pub const CAH = extern struct {
    cElems: ULONG,
    pElems: [*c]LARGE_INTEGER,
};

pub const CAUH = extern struct {
    cElems: ULONG,
    pElems: [*c]ULARGE_INTEGER,
};

pub const CALPSTR = extern struct {
    cElems: ULONG,
    pElems: [*c]LPSTR,
};

pub const CALPWSTR = extern struct {
    cElems: ULONG,
    pElems: [*c]LPWSTR,
};

pub const CAFILETIME = extern struct {
    cElems: ULONG,
    pElems: [*c]FILETIME,
};

pub const CACLIPDATA = extern struct {
    cElems: ULONG,
    pElems: [*c]CLIPDATA,
};
pub const CACLSID = extern struct {
    cElems: ULONG,
    pElems: [*c]CLSID,
};

pub const PROPERTYKEY = extern struct {
    fmtid: GUID,
    pid: DWORD,
};

pub const WAVEFORMAT = extern struct {
    wFormatTag: WaveFormat,
    nChannels: WORD,
    nSamplesPerSec: DWORD,
    nAvgBytesPerSec: DWORD,
    nBlockAlign: WORD,
};

pub const WAVEFORMATEX = extern struct {
    wFormatTag: WaveFormat,
    nChannels: WORD,
    nSamplesPerSec: DWORD,
    nAvgBytesPerSec: DWORD,
    nBlockAlign: WORD,
    wBitsPerSample: WORD,
    cbSize: WORD,
};

pub const REFCLSID = *const GUID;
pub const REFIID = *const GUID;

pub const PROPVAR_PAD1 = WORD;
pub const PROPVAR_PAD2 = WORD;
pub const PROPVAR_PAD3 = WORD;

pub const PROPVARIANT = extern struct {
    unnamed_0: extern union {
        unnamed_0: extern struct {
            vt: VARTYPE,
            wReserved1: PROPVAR_PAD1,
            wReserved2: PROPVAR_PAD2,
            wReserved3: PROPVAR_PAD3,
            unnamed_0: extern union {
                cVal: CHAR,
                bVal: UCHAR,
                iVal: SHORT,
                uiVal: USHORT,
                lVal: LONG,
                ulVal: ULONG,
                intVal: INT,
                uintVal: UINT,
                hVal: LARGE_INTEGER,
                uhVal: ULARGE_INTEGER,
                fltVal: f32,
                dblVal: f64,
                boolVal: VARIANT_BOOL,
                __OBSOLETE__VARIANT_BOOL: VARIANT_BOOL,
                scode: SCODE,
                cyVal: c_longlong,
                date: DATE,
                filetime: FILETIME,
                puuid: [*c]CLSID,
                pclipdata: [*c]CLIPDATA,
                bstrVal: BSTR,
                bstrblobVal: BSTRBLOB,
                blob: BLOB,
                pszVal: LPSTR,
                pwszVal: LPWSTR,
                punkVal: [*c]IUnknown,
                pdispVal: [*c]IDispatch,
                pStream: [*c]IStream,
                pStorage: [*c]IStorage,
                pVersionedStream: LPVERSIONEDSTREAM,
                parray: [*c]SAFEARRAY,
                cac: CAC,
                caub: CAUB,
                cai: CAI,
                caui: CAUI,
                cal: CAL,
                caul: CAUL,
                cah: CAH,
                cauh: CAUH,
                caflt: CAFLT,
                cadbl: CADBL,
                cabool: CABOOL,
                cascode: CASCODE,
                cacy: CACY,
                cadate: CADATE,
                cafiletime: CAFILETIME,
                cauuid: CACLSID,
                caclipdata: CACLIPDATA,
                cabstr: CABSTR,
                cabstrblob: CABSTRBLOB,
                calpstr: CALPSTR,
                calpwstr: CALPWSTR,
                capropvar: CAPROPVARIANT,
                pcVal: [*c]CHAR,
                pbVal: [*c]UCHAR,
                piVal: [*c]SHORT,
                puiVal: [*c]USHORT,
                plVal: [*c]LONG,
                pulVal: [*c]ULONG,
                pintVal: [*c]INT,
                puintVal: [*c]UINT,
                pfltVal: [*c]FLOAT,
                pdblVal: [*c]f64,
                pboolVal: [*c]VARIANT_BOOL,
                pdecVal: [*c]DECIMAL,
                pscode: [*c]SCODE,
                pcyVal: [*c]CY,
                pdate: [*c]DATE,
                pbstrVal: [*c]BSTR,
                ppunkVal: [*c][*c]IUnknown,
                ppdispVal: [*c][*c]IDispatch,
                pparray: [*c][*]SAFEARRAY,
                pvarVal: [*c]PROPVARIANT,
            },
        },
        decVal: DECIMAL,
    },
};

/// WASAPI Enumerators
pub const ERole = extern enum(c_int) {
    eConsole = 0,
    eMultimedia = 1,
    eCommunications = 2,
    ERole_enum_count = 3,
    _,
};

pub const WaveFormat = extern enum(c_int) {
    UNKNOWN = 0x0000, // Microsoft Corporation
    ADPCM = 0x0002, // Microsoft Corporation
    IEEE_FLOAT = 0x0003, // Microsoft Corporation
    VSELP = 0x0004, // Compaq Computer Corp.
    IBM_CVSD = 0x0005, // IBM Corporation
    ALAW = 0x0006, // Microsoft Corporation
    MULAW = 0x0007, // Microsoft Corporation
    DTS = 0x0008, // Microsoft Corporation
    DRM = 0x0009, // Microsoft Corporation
    WMAVOICE9 = 0x000A, // Microsoft Corporation
    WMAVOICE10 = 0x000B, // Microsoft Corporation
    OKI_ADPCM = 0x0010, // OKI
    DVI_ADPCM = 0x0011, // Intel Corporation
    MEDIASPACE_ADPCM = 0x0012, // Videologic
    SIERRA_ADPCM = 0x0013, // Sierra Semiconductor Corp
    G723_ADPCM = 0x0014, // Antex Electronics Corporation
    DIGISTD = 0x0015, // DSP Solutions, Inc.
    DIGIFIX = 0x0016, // DSP Solutions, Inc.
    DIALOGIC_OKI_ADPCM = 0x0017, // Dialogic Corporation
    MEDIAVISION_ADPCM = 0x0018, // Media Vision, Inc.
    CU_CODEC = 0x0019, // Hewlett-Packard Company
    HP_DYN_VOICE = 0x001A, // Hewlett-Packard Company
    YAMAHA_ADPCM = 0x0020, // Yamaha Corporation of America
    SONARC = 0x0021, // Speech Compression
    DSPGROUP_TRUESPEECH = 0x0022, // DSP Group, Inc
    ECHOSC1 = 0x0023, // Echo Speech Corporation
    AUDIOFILE_AF36 = 0x0024, // Virtual Music, Inc.
    APTX = 0x0025, // Audio Processing Technology
    AUDIOFILE_AF10 = 0x0026, // Virtual Music, Inc.
    PROSODY_1612 = 0x0027, // Aculab plc
    LRC = 0x0028, // Merging Technologies S.A.
    DOLBY_AC2 = 0x0030, // Dolby Laboratories
    GSM610 = 0x0031, // Microsoft Corporation
    MSNAUDIO = 0x0032, // Microsoft Corporation
    ANTEX_ADPCME = 0x0033, // Antex Electronics Corporation
    CONTROL_RES_VQLPC = 0x0034, // Control Resources Limited
    DIGIREAL = 0x0035, // DSP Solutions, Inc.
    DIGIADPCM = 0x0036, // DSP Solutions, Inc.
    CONTROL_RES_CR10 = 0x0037, // Control Resources Limited
    NMS_VBXADPCM = 0x0038, // Natural MicroSystems
    CS_IMAADPCM = 0x0039, // Crystal Semiconductor IMA ADPCM
    ECHOSC3 = 0x003A, // Echo Speech Corporation
    ROCKWELL_ADPCM = 0x003B, // Rockwell International
    ROCKWELL_DIGITALK = 0x003C, // Rockwell International
    XEBEC = 0x003D, // Xebec Multimedia Solutions Limited
    G721_ADPCM = 0x0040, // Antex Electronics Corporation
    G728_CELP = 0x0041, // Antex Electronics Corporation
    MSG723 = 0x0042, // Microsoft Corporation
    INTEL_G723_1 = 0x0043, // Intel Corp.
    INTEL_G729 = 0x0044, // Intel Corp.
    SHARP_G726 = 0x0045, // Sharp
    MPEG = 0x0050, // Microsoft Corporation
    RT24 = 0x0052, // InSoft, Inc.
    PAC = 0x0053, // InSoft, Inc.
    MPEGLAYER3 = 0x0055, // ISO/MPEG Layer3 Format Tag
    LUCENT_G723 = 0x0059, // Lucent Technologies
    CIRRUS = 0x0060, // Cirrus Logic
    ESPCM = 0x0061, // ESS Technology
    VOXWARE = 0x0062, // Voxware Inc
    CANOPUS_ATRAC = 0x0063, // Canopus, co., Ltd.
    G726_ADPCM = 0x0064, // APICOM
    G722_ADPCM = 0x0065, // APICOM
    DSAT = 0x0066, // Microsoft Corporation
    DSAT_DISPLAY = 0x0067, // Microsoft Corporation
    VOXWARE_BYTE_ALIGNED = 0x0069, // Voxware Inc
    VOXWARE_AC8 = 0x0070, // Voxware Inc
    VOXWARE_AC10 = 0x0071, // Voxware Inc
    VOXWARE_AC16 = 0x0072, // Voxware Inc
    VOXWARE_AC20 = 0x0073, // Voxware Inc
    VOXWARE_RT24 = 0x0074, // Voxware Inc
    VOXWARE_RT29 = 0x0075, // Voxware Inc
    VOXWARE_RT29HW = 0x0076, // Voxware Inc
    VOXWARE_VR12 = 0x0077, // Voxware Inc
    VOXWARE_VR18 = 0x0078, // Voxware Inc
    VOXWARE_TQ40 = 0x0079, // Voxware Inc
    VOXWARE_SC3 = 0x007A, // Voxware Inc
    VOXWARE_SC3_1 = 0x007B, // Voxware Inc
    SOFTSOUND = 0x0080, // Softsound, Ltd.
    VOXWARE_TQ60 = 0x0081, // Voxware Inc
    MSRT24 = 0x0082, // Microsoft Corporation
    G729A = 0x0083, // AT&T Labs, Inc.
    MVI_MVI2 = 0x0084, // Motion Pixels
    DF_G726 = 0x0085, // DataFusion Systems (Pty) (Ltd)
    DF_GSM610 = 0x0086, // DataFusion Systems (Pty) (Ltd)
    ISIAUDIO = 0x0088, // Iterated Systems, Inc.
    ONLIVE = 0x0089, // OnLive! Technologies, Inc.
    MULTITUDE_FT_SX20 = 0x008A, // Multitude Inc.
    INFOCOM_ITS_G721_ADPCM = 0x008B, // Infocom
    CONVEDIA_G729 = 0x008C, // Convedia Corp.
    CONGRUENCY = 0x008D, // Congruency Inc.
    SBC24 = 0x0091, // Siemens Business Communications Sys
    DOLBY_AC3_SPDIF = 0x0092, // Sonic Foundry
    MEDIASONIC_G723 = 0x0093, // MediaSonic
    PROSODY_8KBPS = 0x0094, // Aculab plc
    ZYXEL_ADPCM = 0x0097, // ZyXEL Communications, Inc.
    PHILIPS_LPCBB = 0x0098, // Philips Speech Processing
    PACKED = 0x0099, // Studer Professional Audio AG
    MALDEN_PHONYTALK = 0x00A0, // Malden Electronics Ltd.
    RACAL_RECORDER_GSM = 0x00A1, // Racal recorders
    RACAL_RECORDER_G720_A = 0x00A2, // Racal recorders
    RACAL_RECORDER_G723_1 = 0x00A3, // Racal recorders
    RACAL_RECORDER_TETRA_ACELP = 0x00A4, // Racal recorders
    NEC_AAC = 0x00B0, // NEC Corp.
    RAW_AAC1 = 0x00FF, // For Raw AAC, with format block AudioSpecificConfig() (as defined by MPEG-4), that follows WAVEFORMATEX
    RHETOREX_ADPCM = 0x0100, // Rhetorex Inc.
    IRAT = 0x0101, // BeCubed Software Inc.
    VIVO_G723 = 0x0111, // Vivo Software
    VIVO_SIREN = 0x0112, // Vivo Software
    PHILIPS_CELP = 0x0120, // Philips Speech Processing
    PHILIPS_GRUNDIG = 0x0121, // Philips Speech Processing
    DIGITAL_G723 = 0x0123, // Digital Equipment Corporation
    SANYO_LD_ADPCM = 0x0125, // Sanyo Electric Co., Ltd.
    SIPROLAB_ACEPLNET = 0x0130, // Sipro Lab Telecom Inc.
    SIPROLAB_ACELP4800 = 0x0131, // Sipro Lab Telecom Inc.
    SIPROLAB_ACELP8V3 = 0x0132, // Sipro Lab Telecom Inc.
    SIPROLAB_G729 = 0x0133, // Sipro Lab Telecom Inc.
    SIPROLAB_G729A = 0x0134, // Sipro Lab Telecom Inc.
    SIPROLAB_KELVIN = 0x0135, // Sipro Lab Telecom Inc.
    VOICEAGE_AMR = 0x0136, // VoiceAge Corp.
    G726ADPCM = 0x0140, // Dictaphone Corporation
    DICTAPHONE_CELP68 = 0x0141, // Dictaphone Corporation
    DICTAPHONE_CELP54 = 0x0142, // Dictaphone Corporation
    QUALCOMM_PUREVOICE = 0x0150, // Qualcomm, Inc.
    QUALCOMM_HALFRATE = 0x0151, // Qualcomm, Inc.
    TUBGSM = 0x0155, // Ring Zero Systems, Inc.
    MSAUDIO1 = 0x0160, // Microsoft Corporation
    WMAUDIO2 = 0x0161, // Microsoft Corporation
    WMAUDIO3 = 0x0162, // Microsoft Corporation
    WMAUDIO_LOSSLESS = 0x0163, // Microsoft Corporation
    WMASPDIF = 0x0164, // Microsoft Corporation
    UNISYS_NAP_ADPCM = 0x0170, // Unisys Corp.
    UNISYS_NAP_ULAW = 0x0171, // Unisys Corp.
    UNISYS_NAP_ALAW = 0x0172, // Unisys Corp.
    UNISYS_NAP_16K = 0x0173, // Unisys Corp.
    SYCOM_ACM_SYC008 = 0x0174, // SyCom Technologies
    SYCOM_ACM_SYC701_G726L = 0x0175, // SyCom Technologies
    SYCOM_ACM_SYC701_CELP54 = 0x0176, // SyCom Technologies
    SYCOM_ACM_SYC701_CELP68 = 0x0177, // SyCom Technologies
    KNOWLEDGE_ADVENTURE_ADPCM = 0x0178, // Knowledge Adventure, Inc.
    FRAUNHOFER_IIS_MPEG2_AAC = 0x0180, // Fraunhofer IIS
    DTS_DS = 0x0190, // Digital Theatre Systems, Inc.
    CREATIVE_ADPCM = 0x0200, // Creative Labs, Inc
    CREATIVE_FASTSPEECH8 = 0x0202, // Creative Labs, Inc
    CREATIVE_FASTSPEECH10 = 0x0203, // Creative Labs, Inc
    UHER_ADPCM = 0x0210, // UHER informatic GmbH
    ULEAD_DV_AUDIO = 0x0215, // Ulead Systems, Inc.
    ULEAD_DV_AUDIO_1 = 0x0216, // Ulead Systems, Inc.
    QUARTERDECK = 0x0220, // Quarterdeck Corporation
    ILINK_VC = 0x0230, // I-link Worldwide
    RAW_SPORT = 0x0240, // Aureal Semiconductor
    ESST_AC3 = 0x0241, // ESS Technology, Inc.
    GENERIC_PASSTHRU = 0x0249,
    IPI_HSX = 0x0250, // Interactive Products, Inc.
    IPI_RPELP = 0x0251, // Interactive Products, Inc.
    CS2 = 0x0260, // Consistent Software
    SONY_SCX = 0x0270, // Sony Corp.
    SONY_SCY = 0x0271, // Sony Corp.
    SONY_ATRAC3 = 0x0272, // Sony Corp.
    SONY_SPC = 0x0273, // Sony Corp.
    TELUM_AUDIO = 0x0280, // Telum Inc.
    TELUM_IA_AUDIO = 0x0281, // Telum Inc.
    NORCOM_VOICE_SYSTEMS_ADPCM = 0x0285, // Norcom Electronics Corp.
    FM_TOWNS_SND = 0x0300, // Fujitsu Corp.
    MICRONAS = 0x0350, // Micronas Semiconductors, Inc.
    MICRONAS_CELP833 = 0x0351, // Micronas Semiconductors, Inc.
    BTV_DIGITAL = 0x0400, // Brooktree Corporation
    INTEL_MUSIC_CODER = 0x0401, // Intel Corp.
    INDEO_AUDIO = 0x0402, // Ligos
    QDESIGN_MUSIC = 0x0450, // QDesign Corporation
    ON2_VP7_AUDIO = 0x0500, // On2 Technologies
    ON2_VP6_AUDIO = 0x0501, // On2 Technologies
    VME_VMPCM = 0x0680, // AT&T Labs, Inc.
    TPC = 0x0681, // AT&T Labs, Inc.
    LIGHTWAVE_LOSSLESS = 0x08AE, // Clearjump
    OLIGSM = 0x1000, // Ing C. Olivetti & C., S.p.A.
    OLIADPCM = 0x1001, // Ing C. Olivetti & C., S.p.A.
    OLICELP = 0x1002, // Ing C. Olivetti & C., S.p.A.
    OLISBC = 0x1003, // Ing C. Olivetti & C., S.p.A.
    OLIOPR = 0x1004, // Ing C. Olivetti & C., S.p.A.
    LH_CODEC = 0x1100, // Lernout & Hauspie
    LH_CODEC_CELP = 0x1101, // Lernout & Hauspie
    LH_CODEC_SBC8 = 0x1102, // Lernout & Hauspie
    LH_CODEC_SBC12 = 0x1103, // Lernout & Hauspie
    LH_CODEC_SBC16 = 0x1104, // Lernout & Hauspie
    NORRIS = 0x1400, // Norris Communications, Inc.
    ISIAUDIO_2 = 0x1401, // ISIAudio
    SOUNDSPACE_MUSICOMPRESS = 0x1500, // AT&T Labs, Inc.
    MPEG_ADTS_AAC = 0x1600, // Microsoft Corporation
    MPEG_RAW_AAC = 0x1601, // Microsoft Corporation
    MPEG_LOAS = 0x1602, // Microsoft Corporation (MPEG-4 Audio Transport Streams (LOAS/LATM)
    NOKIA_MPEG_ADTS_AAC = 0x1608, // Microsoft Corporation
    NOKIA_MPEG_RAW_AAC = 0x1609, // Microsoft Corporation
    VODAFONE_MPEG_ADTS_AAC = 0x160A, // Microsoft Corporation
    VODAFONE_MPEG_RAW_AAC = 0x160B, // Microsoft Corporation
    MPEG_HEAAC = 0x1610, // Microsoft Corporation (MPEG-2 AAC or MPEG-4 HE-AAC v1/v2 streams with any payload (ADTS, ADIF, LOAS/LATM, RAW). Format block includes MP4 AudioSpecificConfig() -- see HEAACWAVEFORMAT below
    VOXWARE_RT24_SPEECH = 0x181C, // Voxware Inc.
    SONICFOUNDRY_LOSSLESS = 0x1971, // Sonic Foundry
    INNINGS_TELECOM_ADPCM = 0x1979, // Innings Telecom Inc.
    LUCENT_SX8300P = 0x1C07, // Lucent Technologies
    LUCENT_SX5363S = 0x1C0C, // Lucent Technologies
    CUSEEME = 0x1F03, // CUSeeMe
    NTCSOFT_ALF2CM_ACM = 0x1FC4, // NTCSoft
    DVM = 0x2000, // FAST Multimedia AG
    DTS2 = 0x2001,
    MAKEAVIS = 0x3313,
    DIVIO_MPEG4_AAC = 0x4143, // Divio, Inc.
    NOKIA_ADAPTIVE_MULTIRATE = 0x4201, // Nokia
    DIVIO_G726 = 0x4243, // Divio, Inc.
    LEAD_SPEECH = 0x434C, // LEAD Technologies
    LEAD_VORBIS = 0x564C, // LEAD Technologies
    WAVPACK_AUDIO = 0x5756, // xiph.org
    ALAC = 0x6C61, // Apple Lossless
    OGG_VORBIS_MODE_1 = 0x674F, // Ogg Vorbis
    OGG_VORBIS_MODE_2 = 0x6750, // Ogg Vorbis
    OGG_VORBIS_MODE_3 = 0x6751, // Ogg Vorbis
    OGG_VORBIS_MODE_1_PLUS = 0x676F, // Ogg Vorbis
    OGG_VORBIS_MODE_2_PLUS = 0x6770, // Ogg Vorbis
    OGG_VORBIS_MODE_3_PLUS = 0x6771, // Ogg Vorbis
    @"3COM_NBX" = 0x7000, // 3COM Corp.
    OPUS = 0x704F, // Opus
    FAAD_AAC = 0x706D,
    AMR_NB = 0x7361, // AMR Narrowband
    AMR_WB = 0x7362, // AMR Wideband
    AMR_WP = 0x7363, // AMR Wideband Plus
    GSM_AMR_CBR = 0x7A21, // GSMA/3GPP
    GSM_AMR_VBR_SID = 0x7A22, // GSMA/3GPP
    COMVERSE_INFOSYS_G723_1 = 0xA100, // Comverse Infosys
    COMVERSE_INFOSYS_AVQSBC = 0xA101, // Comverse Infosys
    COMVERSE_INFOSYS_SBC = 0xA102, // Comverse Infosys
    SYMBOL_G729_A = 0xA103, // Symbol Technologies
    VOICEAGE_AMR_WB = 0xA104, // VoiceAge Corp.
    INGENIENT_G726 = 0xA105, // Ingenient Technologies, Inc.
    MPEG4_AAC = 0xA106, // ISO/MPEG-4
    ENCORE_G726 = 0xA107, // Encore Software
    ZOLL_ASAO = 0xA108, // ZOLL Medical Corp.
    SPEEX_VOICE = 0xA109, // xiph.org
    VIANIX_MASC = 0xA10A, // Vianix LLC
    WM9_SPECTRUM_ANALYZER = 0xA10B, // Microsoft
    WMF_SPECTRUM_ANAYZER = 0xA10C, // Microsoft
    GSM_610 = 0xA10D,
    GSM_620 = 0xA10E,
    GSM_660 = 0xA10F,
    GSM_690 = 0xA110,
    GSM_ADAPTIVE_MULTIRATE_WB = 0xA111,
    POLYCOM_G722 = 0xA112, // Polycom
    POLYCOM_G728 = 0xA113, // Polycom
    POLYCOM_G729_A = 0xA114, // Polycom
    POLYCOM_SIREN = 0xA115, // Polycom
    GLOBAL_IP_ILBC = 0xA116, // Global IP
    RADIOTIME_TIME_SHIFT_RADIO = 0xA117, // RadioTime
    NICE_ACA = 0xA118, // Nice Systems
    NICE_ADPCM = 0xA119, // Nice Systems
    VOCORD_G721 = 0xA11A, // Vocord Telecom
    VOCORD_G726 = 0xA11B, // Vocord Telecom
    VOCORD_G722_1 = 0xA11C, // Vocord Telecom
    VOCORD_G728 = 0xA11D, // Vocord Telecom
    VOCORD_G729 = 0xA11E, // Vocord Telecom
    VOCORD_G729_A = 0xA11F, // Vocord Telecom
    VOCORD_G723_1 = 0xA120, // Vocord Telecom
    VOCORD_LBC = 0xA121, // Vocord Telecom
    NICE_G728 = 0xA122, // Nice Systems
    FRACE_TELECOM_G729 = 0xA123, // France Telecom
    CODIAN = 0xA124, // CODIAN
    FLAC = 0xF1AC, // flac.sourceforge.net
};

pub const AUDCLNT_SHAREMODE_SHARED = @enumToInt(AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_SHARED);
pub const AUDCLNT_SHAREMODE_EXCLUSIVE = @enumToInt(enum__AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_EXCLUSIVE);
pub const AUDCLNT_SHAREMODE = extern enum(c_int) {
    AUDCLNT_SHAREMODE_SHARED,
    AUDCLNT_SHAREMODE_EXCLUSIVE,
    _,
};

/// WASAPI Interfaces
pub const IRecordInfo = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IRecordInfo, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IRecordInfo) callconv(.C) ULONG,
        Release: ?fn ([*c]IRecordInfo) callconv(.C) ULONG,
        RecordInit: ?fn ([*c]IRecordInfo, PVOID) callconv(.C) HRESULT,
        RecordClear: ?fn ([*c]IRecordInfo, PVOID) callconv(.C) HRESULT,
        RecordCopy: ?fn ([*c]IRecordInfo, PVOID, PVOID) callconv(.C) HRESULT,
        GetGuid: ?fn ([*c]IRecordInfo, [*c]GUID) callconv(.C) HRESULT,
        GetName: ?fn ([*c]IRecordInfo, [*c]BSTR) callconv(.C) HRESULT,
        GetSize: ?fn ([*c]IRecordInfo, [*c]ULONG) callconv(.C) HRESULT,
        GetTypeInfo: ?fn ([*c]IRecordInfo, [*c][*c]ITypeInfo) callconv(.C) HRESULT,
        GetField: ?fn ([*c]IRecordInfo, PVOID, LPCOLESTR, [*c]VARIANT) callconv(.C) HRESULT,
        GetFieldNoCopy: ?fn ([*c]IRecordInfo, PVOID, LPCOLESTR, [*c]VARIANT, [*c]PVOID) callconv(.C) HRESULT,
        PutField: ?fn ([*c]IRecordInfo, ULONG, PVOID, LPCOLESTR, [*c]VARIANT) callconv(.C) HRESULT,
        PutFieldNoCopy: ?fn ([*c]IRecordInfo, ULONG, PVOID, LPCOLESTR, [*c]VARIANT) callconv(.C) HRESULT,
        GetFieldNames: ?fn ([*c]IRecordInfo, [*c]ULONG, [*c]BSTR) callconv(.C) HRESULT,
        IsMatchingType: ?fn ([*c]IRecordInfo, [*c]IRecordInfo) callconv(.C) BOOL,
        RecordCreate: ?fn ([*c]IRecordInfo) callconv(.C) PVOID,
        RecordCreateCopy: ?fn ([*c]IRecordInfo, PVOID, [*c]PVOID) callconv(.C) HRESULT,
        RecordDestroy: ?fn ([*c]IRecordInfo, PVOID) callconv(.C) HRESULT,
    }
};

pub const ITypeComp = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]ITypeComp, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]ITypeComp) callconv(.C) ULONG,
        Release: ?fn ([*c]ITypeComp) callconv(.C) ULONG,
        Bind: ?fn ([*c]ITypeComp, LPOLESTR, ULONG, WORD, [*c][*c]ITypeInfo, [*c]DESCKIND, [*c]BINDPTR) callconv(.C) HRESULT,
        BindType: ?fn ([*c]ITypeComp, LPOLESTR, ULONG, [*c][*c]ITypeInfo, [*c][*c]ITypeComp) callconv(.C) HRESULT,
    }
};

pub const ITypeLib = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]ITypeLib, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]ITypeLib) callconv(.C) ULONG,
        Release: ?fn ([*c]ITypeLib) callconv(.C) ULONG,
        GetTypeInfoCount: ?fn ([*c]ITypeLib) callconv(.C) UINT,
        GetTypeInfo: ?fn ([*c]ITypeLib, UINT, [*c][*c]ITypeInfo) callconv(.C) HRESULT,
        GetTypeInfoType: ?fn ([*c]ITypeLib, UINT, [*c]TYPEKIND) callconv(.C) HRESULT,
        GetTypeInfoOfGuid: ?fn ([*c]ITypeLib, [*c]const GUID, [*c][*c]ITypeInfo) callconv(.C) HRESULT,
        GetLibAttr: ?fn ([*c]ITypeLib, [*c][*c]TLIBATTR) callconv(.C) HRESULT,
        GetTypeComp: ?fn ([*c]ITypeLib, [*c][*c]ITypeComp) callconv(.C) HRESULT,
        GetDocumentation: ?fn ([*c]ITypeLib, INT, [*c]BSTR, [*c]BSTR, [*c]DWORD, [*c]BSTR) callconv(.C) HRESULT,
        IsName: ?fn ([*c]ITypeLib, LPOLESTR, ULONG, [*c]BOOL) callconv(.C) HRESULT,
        FindName: ?fn ([*c]ITypeLib, LPOLESTR, ULONG, [*c][*c]ITypeInfo, [*c]MEMBERID, [*c]USHORT) callconv(.C) HRESULT,
        ReleaseTLibAttr: ?fn ([*c]ITypeLib, [*c]TLIBATTR) callconv(.C) void,
    }
};

pub const ITypeInfo = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]ITypeInfo, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]ITypeInfo) callconv(.C) ULONG,
        Release: ?fn ([*c]ITypeInfo) callconv(.C) ULONG,
        GetTypeAttr: ?fn ([*c]ITypeInfo, [*c][*c]TYPEATTR) callconv(.C) HRESULT,
        GetTypeComp: ?fn ([*c]ITypeInfo, [*c][*c]ITypeComp) callconv(.C) HRESULT,
        GetFuncDesc: ?fn ([*c]ITypeInfo, UINT, [*c][*c]FUNCDESC) callconv(.C) HRESULT,
        GetVarDesc: ?fn ([*c]ITypeInfo, UINT, [*c][*c]VARDESC) callconv(.C) HRESULT,
        GetNames: ?fn ([*c]ITypeInfo, MEMBERID, [*c]BSTR, UINT, [*c]UINT) callconv(.C) HRESULT,
        GetRefTypeOfImplType: ?fn ([*c]ITypeInfo, UINT, [*c]HREFTYPE) callconv(.C) HRESULT,
        GetImplTypeFlags: ?fn ([*c]ITypeInfo, UINT, [*c]INT) callconv(.C) HRESULT,
        GetIDsOfNames: ?fn ([*c]ITypeInfo, [*c]LPOLESTR, UINT, [*c]MEMBERID) callconv(.C) HRESULT,
        Invoke: ?fn ([*c]ITypeInfo, PVOID, MEMBERID, WORD, [*c]DISPPARAMS, [*c]VARIANT, [*c]EXCEPINFO, [*c]UINT) callconv(.C) HRESULT,
        GetDocumentation: ?fn ([*c]ITypeInfo, MEMBERID, [*c]BSTR, [*c]BSTR, [*c]DWORD, [*c]BSTR) callconv(.C) HRESULT,
        GetDllEntry: ?fn ([*c]ITypeInfo, MEMBERID, INVOKEKIND, [*c]BSTR, [*c]BSTR, [*c]WORD) callconv(.C) HRESULT,
        GetRefTypeInfo: ?fn ([*c]ITypeInfo, HREFTYPE, [*c][*c]ITypeInfo) callconv(.C) HRESULT,
        AddressOfMember: ?fn ([*c]ITypeInfo, MEMBERID, INVOKEKIND, [*c]PVOID) callconv(.C) HRESULT,
        CreateInstance: ?fn ([*c]ITypeInfo, [*c]IUnknown, [*c]const IID, [*c]PVOID) callconv(.C) HRESULT,
        GetMops: ?fn ([*c]ITypeInfo, MEMBERID, [*c]BSTR) callconv(.C) HRESULT,
        GetContainingTypeLib: ?fn ([*c]ITypeInfo, [*c][*c]ITypeLib, [*c]UINT) callconv(.C) HRESULT,
        ReleaseTypeAttr: ?fn ([*c]ITypeInfo, [*c]TYPEATTR) callconv(.C) void,
        ReleaseFuncDesc: ?fn ([*c]ITypeInfo, [*c]FUNCDESC) callconv(.C) void,
        ReleaseVarDesc: ?fn ([*c]ITypeInfo, [*c]VARDESC) callconv(.C) void,
    }
};

pub const STATSTG = extern struct {
    pwcsName: LPOLESTR,
    type: DWORD,
    cbSize: ULARGE_INTEGER,
    mtime: FILETIME,
    ctime: FILETIME,
    atime: FILETIME,
    grfMode: DWORD,
    grfLocksSupported: DWORD,
    clsid: CLSID,
    grfStateBits: DWORD,
    reserved: DWORD,
};

pub const IEnumSTATSTG = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IEnumSTATSTG, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IEnumSTATSTG) callconv(.C) ULONG,
        Release: ?fn ([*c]IEnumSTATSTG) callconv(.C) ULONG,
        Next: ?fn ([*c]IEnumSTATSTG, ULONG, [*c]STATSTG, [*c]ULONG) callconv(.C) HRESULT,
        Skip: ?fn ([*c]IEnumSTATSTG, ULONG) callconv(.C) HRESULT,
        Reset: ?fn ([*c]IEnumSTATSTG) callconv(.C) HRESULT,
        Clone: ?fn ([*c]IEnumSTATSTG, [*c][*c]IEnumSTATSTG) callconv(.C) HRESULT,
    }
};

pub const SNB = [*c]LPOLESTR;
pub const IStorage = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IStorage, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IStorage) callconv(.C) ULONG,
        Release: ?fn ([*c]IStorage) callconv(.C) ULONG,
        CreateStream: ?fn ([*c]IStorage, [*c]const OLECHAR, DWORD, DWORD, DWORD, [*c][*c]IStream) callconv(.C) HRESULT,
        OpenStream: ?fn ([*c]IStorage, [*c]const OLECHAR, ?*c_void, DWORD, DWORD, [*c][*c]IStream) callconv(.C) HRESULT,
        CreateStorage: ?fn ([*c]IStorage, [*c]const OLECHAR, DWORD, DWORD, DWORD, [*c][*c]IStorage) callconv(.C) HRESULT,
        OpenStorage: ?fn ([*c]IStorage, [*c]const OLECHAR, [*c]IStorage, DWORD, SNB, DWORD, [*c][*c]IStorage) callconv(.C) HRESULT,
        CopyTo: ?fn ([*c]IStorage, DWORD, [*c]const IID, SNB, [*c]IStorage) callconv(.C) HRESULT,
        MoveElementTo: ?fn ([*c]IStorage, [*c]const OLECHAR, [*c]IStorage, [*c]const OLECHAR, DWORD) callconv(.C) HRESULT,
        Commit: ?fn ([*c]IStorage, DWORD) callconv(.C) HRESULT,
        Revert: ?fn ([*c]IStorage) callconv(.C) HRESULT,
        EnumElements: ?fn ([*c]IStorage, DWORD, ?*c_void, DWORD, [*c][*c]IEnumSTATSTG) callconv(.C) HRESULT,
        DestroyElement: ?fn ([*c]IStorage, [*c]const OLECHAR) callconv(.C) HRESULT,
        RenameElement: ?fn ([*c]IStorage, [*c]const OLECHAR, [*c]const OLECHAR) callconv(.C) HRESULT,
        SetElementTimes: ?fn ([*c]IStorage, [*c]const OLECHAR, [*c]const FILETIME, [*c]const FILETIME, [*c]const FILETIME) callconv(.C) HRESULT,
        SetClass: ?fn ([*c]IStorage, [*c]const IID) callconv(.C) HRESULT,
        SetStateBits: ?fn ([*c]IStorage, DWORD, DWORD) callconv(.C) HRESULT,
        Stat: ?fn ([*c]IStorage, [*c]STATSTG, DWORD) callconv(.C) HRESULT,
    }
};

pub const IStream = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IStream, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IStream) callconv(.C) ULONG,
        Release: ?fn ([*c]IStream) callconv(.C) ULONG,
        Read: ?fn ([*c]IStream, ?*c_void, ULONG, [*c]ULONG) callconv(.C) HRESULT,
        Write: ?fn ([*c]IStream, ?*const c_void, ULONG, [*c]ULONG) callconv(.C) HRESULT,
        Seek: ?fn ([*c]IStream, LARGE_INTEGER, DWORD, [*c]ULARGE_INTEGER) callconv(.C) HRESULT,
        SetSize: ?fn ([*c]IStream, ULARGE_INTEGER) callconv(.C) HRESULT,
        CopyTo: ?fn ([*c]IStream, [*c]IStream, ULARGE_INTEGER, [*c]ULARGE_INTEGER, [*c]ULARGE_INTEGER) callconv(.C) HRESULT,
        Commit: ?fn ([*c]IStream, DWORD) callconv(.C) HRESULT,
        Revert: ?fn ([*c]IStream) callconv(.C) HRESULT,
        LockRegion: ?fn ([*c]IStream, ULARGE_INTEGER, ULARGE_INTEGER, DWORD) callconv(.C) HRESULT,
        UnlockRegion: ?fn ([*c]IStream, ULARGE_INTEGER, ULARGE_INTEGER, DWORD) callconv(.C) HRESULT,
        Stat: ?fn ([*c]IStream, [*c]STATSTG, DWORD) callconv(.C) HRESULT,
        Clone: ?fn ([*c]IStream, [*c][*c]IStream) callconv(.C) HRESULT,
    }
};

pub const IUnknown = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IUnknown, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IUnknown) callconv(.C) ULONG,
        Release: ?fn ([*c]IUnknown) callconv(.C) ULONG,
    }
};

pub const IPropertyStore = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IPropertyStore, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IPropertyStore) callconv(.C) ULONG,
        Release: ?fn ([*c]IPropertyStore) callconv(.C) ULONG,
        GetCount: ?fn ([*c]IPropertyStore, [*c]DWORD) callconv(.C) HRESULT,
        GetAt: ?fn ([*c]IPropertyStore, DWORD, [*c]PROPERTYKEY) callconv(.C) HRESULT,
        GetValue: ?fn ([*c]IPropertyStore, [*c]const PROPERTYKEY, [*c]PROPVARIANT) callconv(.C) HRESULT,
        SetValue: ?fn ([*c]IPropertyStore, [*c]const PROPERTYKEY, [*c]const PROPVARIANT) callconv(.C) HRESULT,
        Commit: ?fn ([*c]IPropertyStore) callconv(.C) HRESULT,
    }
};

pub const IMMDevice = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IMMDevice, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IMMDevice) callconv(.C) c_ulong,
        Release: ?fn ([*c]IMMDevice) callconv(.C) c_ulong,
        Activate: ?fn ([*c]IMMDevice, [*c]const IID, DWORD, [*c]PROPVARIANT, [*c]?*c_void) callconv(.C) HRESULT,
        OpenPropertyStore: ?fn ([*c]IMMDevice, DWORD, [*c][*c]IPropertyStore) callconv(.C) HRESULT,
        GetId: ?fn ([*c]IMMDevice, [*c]LPWSTR) callconv(.C) HRESULT,
        GetState: ?fn ([*c]IMMDevice, [*c]DWORD) callconv(.C) HRESULT,
    }
};

pub const IMMDeviceCollection = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IMMDeviceCollection, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IMMDeviceCollection) callconv(.C) c_ulong,
        Release: ?fn ([*c]IMMDeviceCollection) callconv(.C) c_ulong,
        GetCount: ?fn ([*c]IMMDeviceCollection, [*c]c_uint) callconv(.C) HRESULT,
        Item: ?fn ([*c]IMMDeviceCollection, c_uint, [*c][*c]IMMDevice) callconv(.C) HRESULT,
    }
};

pub const IMMDeviceEnumerator = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IMMDeviceEnumerator, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IMMDeviceEnumerator) callconv(.C) c_ulong,
        Release: ?fn ([*c]IMMDeviceEnumerator) callconv(.C) c_ulong,
        EnumAudioEndpoints: ?fn ([*c]IMMDeviceEnumerator, EDataFlow, DWORD, [*c][*c]IMMDeviceCollection) callconv(.C) HRESULT,
        GetDefaultAudioEndpoint: ?fn ([*c]IMMDeviceEnumerator, EDataFlow, ERole, [*c][*c]IMMDevice) callconv(.C) HRESULT,
        GetDevice: ?fn ([*c]IMMDeviceEnumerator, LPCWSTR, [*c][*c]IMMDevice) callconv(.C) HRESULT,
        RegisterEndpointNotificationCallback: ?fn ([*c]IMMDeviceEnumerator, [*c]IMMNotificationClient) callconv(.C) HRESULT,
        UnregisterEndpointNotificationCallback: ?fn ([*c]IMMDeviceEnumerator, [*c]IMMNotificationClient) callconv(.C) HRESULT,
    }
};

pub const IMMNotificationClient = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IMMNotificationClient, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IMMNotificationClient) callconv(.C) ULONG,
        Release: ?fn ([*c]IMMNotificationClient) callconv(.C) ULONG,
        OnDeviceStateChanged: ?fn ([*c]IMMNotificationClient, LPCWSTR, DWORD) callconv(.C) HRESULT,
        OnDeviceAdded: ?fn ([*c]IMMNotificationClient, LPCWSTR) callconv(.C) HRESULT,
        OnDeviceRemoved: ?fn ([*c]IMMNotificationClient, LPCWSTR) callconv(.C) HRESULT,
        OnDefaultDeviceChanged: ?fn ([*c]IMMNotificationClient, EDataFlow, ERole, LPCWSTR) callconv(.C) HRESULT,
        OnPropertyValueChanged: ?fn ([*c]IMMNotificationClient, LPCWSTR, PROPERTYKEY) callconv(.C) HRESULT,
    }
};

pub const IDispatch = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IDispatch, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IDispatch) callconv(.C) ULONG,
        Release: ?fn ([*c]IDispatch) callconv(.C) ULONG,
        GetTypeInfoCount: ?fn ([*c]IDispatch, [*c]UINT) callconv(.C) HRESULT,
        GetTypeInfo: ?fn ([*c]IDispatch, UINT, LCID, [*c][*c]ITypeInfo) callconv(.C) HRESULT,
        GetIDsOfNames: ?fn ([*c]IDispatch, [*c]const IID, [*c]LPOLESTR, UINT, LCID, [*c]DISPID) callconv(.C) HRESULT,
        Invoke: ?fn ([*c]IDispatch, DISPID, [*c]const IID, LCID, WORD, [*c]DISPPARAMS, [*c]VARIANT, [*c]EXCEPINFO, [*c]UINT) callconv(.C) HRESULT,
    }
};

pub const IAudioRenderClient = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IAudioRenderClient, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IAudioRenderClient) callconv(.C) ULONG,
        Release: ?fn ([*c]IAudioRenderClient) callconv(.C) ULONG,
        GetBuffer: ?fn ([*c]IAudioRenderClient, c_uint, [*c][*c]BYTE) callconv(.C) HRESULT,
        ReleaseBuffer: ?fn ([*c]IAudioRenderClient, c_uint, DWORD) callconv(.C) HRESULT,
    }
};

pub const IAudioClient = extern struct {
    lpVtbl: [*c]extern struct {
        QueryInterface: ?fn ([*c]IAudioClient, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
        AddRef: ?fn ([*c]IAudioClient) callconv(.C) ULONG,
        Release: ?fn ([*c]IAudioClient) callconv(.C) ULONG,
        Initialize: ?fn ([*c]IAudioClient, AUDCLNT_SHAREMODE, DWORD, REFERENCE_TIME, REFERENCE_TIME, [*c]const WAVEFORMATEX, [*c]const GUID) callconv(.C) HRESULT,
        GetBufferSize: ?fn ([*c]IAudioClient, [*c]c_uint) callconv(.C) HRESULT,
        GetStreamLatency: ?fn ([*c]IAudioClient, [*c]REFERENCE_TIME) callconv(.C) HRESULT,
        GetCurrentPadding: ?fn ([*c]IAudioClient, [*c]c_uint) callconv(.C) HRESULT,
        IsFormatSupported: ?fn ([*c]IAudioClient, AUDCLNT_SHAREMODE, [*c]const WAVEFORMATEX, [*c][*c]WAVEFORMATEX) callconv(.C) HRESULT,
        GetMixFormat: ?fn ([*c]IAudioClient, [*c][*c]WAVEFORMATEX) callconv(.C) HRESULT,
        GetDevicePeriod: ?fn ([*c]IAudioClient, [*c]REFERENCE_TIME, [*c]REFERENCE_TIME) callconv(.C) HRESULT,
        Start: ?fn ([*c]IAudioClient) callconv(.C) HRESULT,
        Stop: ?fn ([*c]IAudioClient) callconv(.C) HRESULT,
        Reset: ?fn ([*c]IAudioClient) callconv(.C) HRESULT,
        SetEventHandle: ?fn ([*c]IAudioClient, HANDLE) callconv(.C) HRESULT,
        GetService: ?fn ([*c]IAudioClient, [*c]const IID, [*c]?*c_void) callconv(.C) HRESULT,
    }
};
