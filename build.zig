// NOTE: unfortunately switching to the 'prefix-less' functions in
// zimgui.h isn't that easy because some Dear ImGui functions collide
// with Win32 function (Set/GetCursorPos and Set/GetWindowPos).
const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_cimgui = b.addStaticLibrary(.{
        .name = "cimgui_clib",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_cimgui.linkLibCpp();
    lib_cimgui.addCSourceFiles(.{
        .files = &.{
            "cimgui.cpp",
            "imgui/imgui_demo.cpp",
            "imgui/imgui_draw.cpp",
            "imgui/imgui_tables.cpp",
            "imgui/imgui_widgets.cpp",
            "imgui/imgui.cpp",
            "imgui/backends/imgui_impl_sdl3.cpp",
        },
        .flags = &.{"-std=c++11"}, // "-DIMGUI_IMPL_API=\"extern \"C\"\"" },
        .language = .cpp,
    });
    lib_cimgui.root_module.addCMacro("IMGUI_IMPL_API", "extern \"C\"");
    lib_cimgui.addIncludePath(b.path("imgui"));

    // make cimgui available as artifact, this allows to inject
    // the Emscripten sysroot include path in another build.zig
    b.installArtifact(lib_cimgui);

    // translate-c the cimgui.h file
    // NOTE: running this step with the host target is intended to avoid
    // any Emscripten header search path shenanigans
    const translateC = b.addTranslateC(.{
        .root_source_file = b.path("c.h"),
        .target = b.graph.host,
        .optimize = optimize,
    });
    translateC.defineCMacro("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", null);
    // translateCh.defineCMacro("IMGUI_IMPL_API", "extern \"C\"");
    translateC.defineCMacro("CIMGUI_USE_SDL3", null);
    translateC.addIncludePath(b.path("../SDL/include/"));

    // build cimgui as module
    const mod_cimgui = b.addModule("cimgui", .{
        .root_source_file = translateC.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    mod_cimgui.linkLibrary(lib_cimgui);

    // const translateC2 = b.addTranslateC(.{
    //     .root_source_file = b.path("c.h"),
    //     .target = b.graph.host,
    //     .optimize = optimize,
    // });
    // translateC2.addIncludePath(b.path("imgui"));
    // translateC2.defineCMacro("CIMGUI_USE_SDL3", null);
    // translateC2.defineCMacro("CIMGUI_API", ""); // "extern \"C\"");
    //
    // const mod_cimgui_sdl = b.addModule("cimgui_sdl", .{
    //     .root_source_file = translateC2.getOutput(),
    //     .target = target,
    //     .optimize = optimize,
    //     .link_libc = true,
    //     .link_libcpp = true,
    // });
    // _ = mod_cimgui_sdl;
}
