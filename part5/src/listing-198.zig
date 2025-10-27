const std = @import("std");
const repetitionTester = @import("repetition-tester.zig");

const TestFunction = struct {
    name: []const u8,
    func: *const fn (usize) void,
};

inline fn asineCore(X: f64) f64 {
    const x2 = X * X;

    var r: f64 = 0x1.dfc53682725cap-1;
    r = @mulAdd(f64, r, x2, -0x1.bec6daf74ed61p1);
    r = @mulAdd(f64, r, x2, 0x1.8bf4dadaf548cp2);
    r = @mulAdd(f64, r, x2, -0x1.b06f523e74f33p2);
    r = @mulAdd(f64, r, x2, 0x1.4537ddde2d76dp2);
    r = @mulAdd(f64, r, x2, -0x1.6067d334b4792p1);
    r = @mulAdd(f64, r, x2, 0x1.1fb54da575b22p0);
    r = @mulAdd(f64, r, x2, -0x1.57380bcd2890ep-2);
    r = @mulAdd(f64, r, x2, 0x1.69b370aad086ep-4);
    r = @mulAdd(f64, r, x2, -0x1.21438ccc95d62p-8);
    r = @mulAdd(f64, r, x2, 0x1.b8a33b8e380efp-7);
    r = @mulAdd(f64, r, x2, 0x1.c37061f4e5f55p-7);
    r = @mulAdd(f64, r, x2, 0x1.1c875d6c5323dp-6);
    r = @mulAdd(f64, r, x2, 0x1.6e88ce94d1149p-6);
    r = @mulAdd(f64, r, x2, 0x1.f1c73443a02f5p-6);
    r = @mulAdd(f64, r, x2, 0x1.6db6db3184756p-5);
    r = @mulAdd(f64, r, x2, 0x1.3333333380df2p-4);
    r = @mulAdd(f64, r, x2, 0x1.555555555531ep-3);
    r = @mulAdd(f64, r, x2, 0x1p0);
    r *= X;

    return r;
}

fn internetWay(repCount: usize) void {
    for (0..repCount) |_| {
        const v: f64 = 0.5;
        _ = asm volatile (""
            : [ret] "={d0}" (-> f64),
            : [num] "{d0}" (v),
        );
        const res = asineCore(v);

        _ = asm volatile (""
            : [ret] "={d0}" (-> f64),
            : [num] "{d0}" (res),
        );
    }
}

fn internetWay2(repCount: usize) void {
    for (0..repCount) |_| {
        const v: f64 = 0.5;
        _ = asm volatile (""
            :
            : [ptr] "{memory}" (&v),
            : .{ .memory = true });
        const res = asineCore(v);

        _ = asm volatile (""
            :
            : [ptr] "{memory}" (&res),
            : .{ .memory = true });
    }
}

fn ourWay(repCount: usize) void {
    for (0..repCount) |_| {
        var v: f64 = 0.5;
        _ = asm volatile (""
            : [ret] "={d3}" (v),
        );
        const res = asineCore(v);
        _ = asm volatile (""
            :
            : [in] "{d3}" (res),
        );
    }
}

fn ourWay3(repCount: usize) void {
    for (0..repCount) |_| {
        const v: f64 = 0.5;
        asm volatile (""
            :
            : [_] "r" (v),
        );
        const res = asineCore(v);
        asm volatile (""
            :
            : [_] "r" (res),
        );
    }
}

fn ourWay2(repCount: usize) void {
    for (0..repCount) |_| {
        const v: f64 = 0.5;
        std.mem.doNotOptimizeAway(v);
        // const res = @call(.always_inline, asineCore, .{v});
        const res = asineCore(v);
        std.mem.doNotOptimizeAway(res);
    }
}

fn fuckedupWay(repCount: usize) void {
    for (0..repCount) |_| {
        const v: f64 = 0.5;
        _ = asineCore(v);
    }
}

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();

    const repCount = 1000000;
    const testFunctions = [_]TestFunction{
        TestFunction{
            .name = "internetWay2",
            .func = internetWay2,
        },
        TestFunction{
            .name = "ourWay",
            .func = ourWay,
        },
        TestFunction{
            .name = "ourWay2",
            .func = ourWay2,
        },
        TestFunction{
            .name = "ourWay3",
            .func = ourWay3,
        },
    };

    var testSeries = repetitionTester.ReptitionTestSeries(1, 2).new();
    testSeries.setRowLabel(""[0..]);

    while (true) {
        for (testFunctions) |tf| {
            testSeries.setColumnLabel(tf.name);
            var tester = repetitionTester.Tester.new();

            testSeries.newTestWave(&tester, 8, repCount);
            while (testSeries.isTesting(&tester)) {
                tester.beginTime();
                tf.func(repCount);
                tester.endTime();
                tester.countBytes(repCount);
            }
        }
    }
}
