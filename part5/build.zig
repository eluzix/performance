const std = @import("std");

pub fn build(b: *std.Build) void {
    const io = b.graph.io;

    const target = b.graph.host;
    const optimize = b.standardOptimizeOption(.{});

    // Existing executables — only added if their source files exist.
    const static_entries = .{
        .{ .name = "haversine", .src = "src/main.zig" },
        // .{ .name = "json_generator", .src = "src/json-generator.zig" },
    };

    inline for (static_entries) |entry| {
        if (b.build_root.handle.statFile(io, entry.src, .{})) |_| {
            const exe = b.addExecutable(.{
                .name = entry.name,
                .root_module = b.createModule(.{
                    .root_source_file = b.path(entry.src),
                    .target = target,
                    .optimize = optimize,
                    .link_libc = true,
                }),
            });
            b.installArtifact(exe);

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }
            const run_step = b.step("run-" ++ entry.name, "Run " ++ entry.name);
            run_step.dependOn(&run_cmd.step);
        } else |_| {}
    }

    // Discover all listing-* source files and create an executable for each.
    var src_dir = b.build_root.handle.openDir(io, "src", .{ .iterate = true }) catch return;
    defer src_dir.close(io);

    var iter = src_dir.iterate();
    while (iter.next(io) catch null) |entry| {
        if (entry.kind != .file) continue;

        const name = entry.name;
        if (!std.mem.startsWith(u8, name, "listing-")) continue;
        if (!std.mem.endsWith(u8, name, ".zig")) continue;

        // Strip the .zig extension to get the executable name.
        const exe_name = b.dupe(name[0 .. name.len - 4]);

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.fmt("src/{s}", .{name})),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step(exe_name, b.fmt("Run {s}", .{exe_name}));
        run_step.dependOn(&run_cmd.step);
    }

    // Tests
    if (b.build_root.handle.statFile(io, "src/json-generator.zig", .{})) |_| {
        const exe_unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/json-generator.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    } else |_| {}
}
