const std = @import("std");

typedef struct {
    const char* ActivateTrace;
    const char* TraceLevel;
    const char* Domains;
} AppConfig;

typedef struct {
    const char* Id;
    const char* ActivateDefaultTransport;
    const char* DirectDispacthToSubs;
    const char* KeyFile;
    const char* Transports;
    const char* CrossConnector;
} DomainCfg;

typedef struct {
    const char* TransportName;
    const char* DllImport;
    const char* TransportClass;
    const char* ReceiveOwnMsgs;
    const char* MCastParams;
    const char* BCastParams;
    const char* UDPStarParams;
} TransportDef;

typedef struct {
    const char* LocalAddress;
    const char* MCastAddress;
    const char* Port;
    const char* TTL;
    const char* ReceiveBuffer;
    const char* SendBuffer;
} MCastDefConfig;

typedef struct {
    const char* LocalAddress;
    const char* BCastAddress;
    const char* Port;
    const char* ReceiveBuffer;
    const char* SendBuffer;
} BCastDefConfig;

typedef struct {
    const char* LocalAddress;
    const char* Port;
    const char* EndPoint;
    const char* ReceiveBuffer;
    const char* SendBuffer;
} UDPStarDefConfig;

typedef struct {
    const char* Host;
    const char* Port;
} EndPointDef;

typedef struct {
    const char* Transports;
} CrossConnectorDef;

pub extern "c" fn AppConfigArray_toC(arr: []AppConfig) AppConfigArray {
    return AppConfigArray{ .len = arr.len, .items = arr.ptr };
}

pub extern "c" fn DomainCfgArray_toC(arr: []DomainCfg) DomainCfgArray {
    return DomainCfgArray{ .len = arr.len, .items = arr.ptr };
}

pub extern "c" fn TransportDefArray_toC(arr: []TransportDef) TransportDefArray {
    return TransportDefArray{ .len = arr.len, .items = arr.ptr };
}

pub extern "c" fn MCastDefConfigArray_toC(arr: []MCastDefConfig) MCastDefConfigArray {
    return MCastDefConfigArray{ .len = arr.len, .items = arr.ptr };
}

pub extern "c" fn BCastDefConfigArray_toC(arr: []BCastDefConfig) BCastDefConfigArray {
    return BCastDefConfigArray{ .len = arr.len, .items = arr.ptr };
}

pub extern "c" fn UDPStarDefConfigArray_toC(arr: []UDPStarDefConfig) UDPStarDefConfigArray {
    return UDPStarDefConfigArray{ .len = arr.len, .items = arr.ptr };
}

pub extern "c" fn EndPointDefArray_toC(arr: []EndPointDef) EndPointDefArray {
    return EndPointDefArray{ .len = arr.len, .items = arr.ptr };
}

pub extern "c" fn CrossConnectorDefArray_toC(arr: []CrossConnectorDef) CrossConnectorDefArray {
    return CrossConnectorDefArray{ .len = arr.len, .items = arr.ptr };
}

