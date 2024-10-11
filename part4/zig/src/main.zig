const std = @import("std");
const generator = @import("json-generator.zig");
const perf = @import("perf-metrics.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 3) {
        std.debug.print("Usage: {s} generate|parse|run <file|listing> [generate:count] [generate:seed]", .{args[0]});
        std.process.exit(1);
    }

    if (std.mem.eql(u8, args[1], "generate")) {
        var seed: u64 = undefined;

        var count: usize = 100;
        if (args.len > 3) {
            count = try std.fmt.parseInt(usize, args[3], 10);
        }

        if (args.len > 4) {
            seed = try std.fmt.parseInt(u64, args[4], 10);
        } else {
            try std.posix.getrandom(std.mem.asBytes(&seed));
        }

        try generator.generateJson(allocator, count, seed, args[2]);
    } else if (std.mem.eql(u8, args[1], "parse")) {
        std.debug.print(">>> {d} ---- {d}", .{ perf.highResolutionClock(), perf.highResolutionClock() });
    } else {
        std.debug.print("Usage: {s} generate|parse|run <file|listing>", .{args[0]});
        std.process.exit(1);
    }
}
