cc_library(
    name = "Emscripten",
    srcs = glob(["Lib/Emscripten/*.cpp"]),
    hdrs = glob(["Lib/Emscripten/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "IR",
    srcs = glob(["Lib/IR/*.cpp"]),
    hdrs = glob(["Lib/IR/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "LLVMJIT",
    srcs = glob(["Lib/LLVMJIT/*.cpp"]),
    hdrs = glob(["Lib/LLVMJIT/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
          '-DLLVMJIT_API=""',
          '-DLLVM_TARGET_ATTRIBUTES=""',
          '-I/usr/include/llvm-6.0/include',
          '-L/usr/lib/llvm-6.0/lib',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "Logging",
    srcs = glob(["Lib/Logging/*.cpp"]),
    hdrs = glob(["Lib/Logging/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "NFA",
    srcs = glob(["Lib/NFA/*.cpp"]),
    hdrs = glob(["Lib/NFA/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "Platform",
    srcs = glob(["Lib/Platform/*.cpp"]),
    hdrs = glob(["Lib/Platform/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "RegExp",
    srcs = glob(["Lib/RegExp/*.cpp"]),
    hdrs = glob(["Lib/RegExp/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
          '-DREGEXP_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "Runtime",
    srcs = glob(["Lib/Runtime/*.cpp"]),
    hdrs = glob(["Lib/Runtime/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
          '-DLLVMJIT_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "ThreadTest",
    srcs = glob(["Lib/ThreadTest/*.cpp"]),
    hdrs = glob(["Lib/ThreadTest/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
          '-DTHREADTEST_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "WASM",
    srcs = glob(["Lib/WASM/*.cpp"]),
    hdrs = glob(["Lib/WASM/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "WASTParse",
    srcs = glob(["Lib/WASTParse/*.cpp"]),
    hdrs = glob(["Lib/WASTParse/*.h"]) + ["ThirdParty/dtoa/dtoa.c"],
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
          '-DREGEXP_API=""',
          '-DWASTPARSE_API=""',
          '-DWASM_API=""',
          '-I.',
          '-IThirdParty/',
          '-IThirdParty/dtoa',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "WASTPrint",
    srcs = glob(["Lib/WASTPrint/*.cpp"]),
    hdrs = glob(["Lib/WASTPrint/*.h"]),
    copts = [
          '-DPLATFORM_API=""',
          '-DRUNTIME_API=""',
          '-DIR_API=""',
          '-DEMSCRIPTEN_API=""',
          '-DLOGGING_API=""',
          '-DNFA_API=""',
          '-DREGEX_API=""',
          '-DLLVM_API=""',
          '-DWASTPRINT_API=""',
    ],
    includes = glob(["include/WAVM/*/*.h"]),
    visibility = ["//visibility:public"],
)
