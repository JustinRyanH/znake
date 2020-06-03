const std = @import("std");
usingnamespace std.os.windows;

/// Basic Window Components
const IID = GUID;
const VARTYPE = c_ushort;
const VARIANT_BOOL = c_short;
const SCODE = LONG;
const CLSID = GUID;
const LCID = DWORD;
const DATE = f64;
pub const OLECHAR = WCHAR;
pub const LPOLESTR = [*c]OLECHAR;
pub const LPCOLESTR = [*c]const OLECHAR;
pub const BSTR = [*c]OLECHAR;
pub const DISPID = LONG;
pub const MEMBERID = DISPID;
pub const HREFTYPE = DWORD;
pub const MEMBERID_NIL = -1;

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
