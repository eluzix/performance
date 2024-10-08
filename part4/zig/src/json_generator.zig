const std = @import("std");
const haversine = @import("haversine.zig");

fn randomFloatInRange(rng: *std.rand.DefaultPrng, min: f64, max: f64) f64 {
    const random_value = rng.random().float(f64);
    return min + random_value * (max - min);
}

// fn randomInRane(x0: *[2]f64, y0: *[2]f64, x1: *[2]f64, y1: *[2]f64) (f64, f64, f64, f64) {
fn randomInRane(rng: *std.rand.DefaultPrng, x0: *[2]f64, y0: *[2]f64, x1: *[2]f64, y1: *[2]f64, rnd: *[4]f64) void {
    rnd[0] = randomFloatInRange(rng, x0[0], x0[1]);
    rnd[1] = randomFloatInRange(rng, y0[0], y0[1]);
    rnd[2] = randomFloatInRange(rng, x1[0], x1[1]);
    rnd[3] = randomFloatInRange(rng, y0[0], y1[1]);
}

fn generateJson(count: usize) !void {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    var ranges = [_][2]f64{
        [_]f64{ -180.0, 180.0 },
        [_]f64{ -90.0, 90.0 },
        [_]f64{ -180.0, 180.0 },
        [_]f64{ -90.0, 90.0 },
    };
    var rnd = [_]f64{ 0.0, 0.0, 0.0, 0.0 };

    const cwd = std.fs.cwd();
    var file = try cwd.createFile("haversine.json", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.writeAll("{\"pairs\": [\n");

    for (0..count) |_| {
        randomInRane(&prng, &ranges[0], &ranges[1], &ranges[2], &ranges[3], &rnd);
        try std.fmt.format(writer, "{{\"x0\":{},\"y0\":{},\"x1\":{},\"y1\":{}}}\n", .{ rnd[0], rnd[1], rnd[2], rnd[3] });
    }
    try writer.writeAll("]}\n");

    const min: f64 = 1.0;
    const max: f64 = 90.0;
    const random_float = randomFloatInRange(&prng, min, max);
    std.debug.print("Random float: {d:.5}\n", .{random_float});
}

pub fn main() !void {
    const c = haversine.referenceHaversine(0, 0, 90, -90);
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {} are belong to us.\n", .{c});

    try generateJson(100.0);

    // // stdout is for the actual output of your application, for example if you
    // // are implementing gzip, then only the compressed bytes should be sent to
    // // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();
    // try stdout.print("Run `zig build test` to run the tests.\n", .{});
    //
    // try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
