const std = @import("std");
const math = std.math;
const dbg = std.debug;
const mymath = @import("my-math.zig");
const rt = @import("range-tester.zig");

inline fn factorial(x: u32) f64 {
    var res: f64 = @floatFromInt(x);
    var xx = res;
    while (xx > 1) {
        xx -= 1;
        res *= xx;
    }
    return res;
}

inline fn taylorSineCoefficient(power: u32) f64 {
    const sign: f64 = if (@mod((power - 1) / 2, 2) != 0) -1.0 else 1.0;
    return sign / factorial(power);
}

fn taylorSine(power: u32, x: f64) f64 {
    var res: f64 = 0;
    const x2 = x * x;
    var xPow = x;

    var p = @as(u32, 1);
    while (p <= power) : (p += 2) {
        res += xPow * taylorSineCoefficient(p);
        xPow *= x2;
    }

    return res;
}

fn taylorSineHoner(power: u32, x: f64) f64 {
    var res: f64 = 0;
    const x2 = x * x;

    var p = @as(u32, 1);
    while (p <= power) : (p += 2) {
        const pwr = power - (p - 1);
        res = res * x2 + taylorSineCoefficient(pwr);
    }
    res *= x;

    return res;
}

fn taylorSineHonerFused(power: u32, x: f64) f64 {
    var res: f64 = 0;
    const x2 = x * x;

    var p = @as(u32, 1);
    while (p <= power) : (p += 2) {
        const pwr = power - (p - 1);
        res = @mulAdd(f64, res, x2, taylorSineCoefficient(pwr));
    }
    res *= x;

    return res;
}

fn taylorSineHonerFusedAsm(power: u32, x: f64) f64 {
    var res: f64 = 0;
    const x2 = x * x;

    var p = @as(u32, 1);
    while (p <= power) : (p += 2) {
        const pwr = power - (p - 1);
        res = asm volatile (
            \\ FMADD D0,D1,D2,D3
            : [ret] "={D0}" (-> f64),
            : [a] "{D1}" (res),
              [b] "{D2}" (x2),
              [c] "{D3}" (taylorSineCoefficient(pwr)),
        );
    }
    res *= x;

    return res;
}

pub fn main() !void {
    // const v: f64 = math.pi / @as(f64, 2.0);
    // const r = taylorSine(11, v);
    // std.debug.print(">>>>value: {d}, r: {d}, sine: {d}\n", .{ v, r, math.sin(v) });

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const alloc = gpa.allocator();
    const alloc = std.heap.page_allocator;
    var tester = rt.PrecisionTester.init(alloc);
    // var tester = rt.PrecisionTester{};

    var p = @as(u32, 1);
    while (p <= 31) : (p += 2) {
        while (rt.rangePrecisionTest(&tester, 0, math.pi / @as(f64, 2))) {
            // rt.checkPrecisionTest(&tester, math.sin(tester.inputValue), taylorSineHoner(p, tester.inputValue));

            var label: [32]u8 = undefined;
            rt.checkPrecisionTest(&tester, math.sin(tester.inputValue), taylorSine(p, tester.inputValue), try std.fmt.bufPrint(&label, "tylorSine{d}", .{p}));
            rt.checkPrecisionTest(&tester, math.sin(tester.inputValue), taylorSineHoner(p, tester.inputValue), try std.fmt.bufPrint(&label, "tylorSineHoner{d}", .{p}));
            rt.checkPrecisionTest(&tester, math.sin(tester.inputValue), taylorSineHonerFused(p, tester.inputValue), try std.fmt.bufPrint(&label, "tylorSineHonerFused{d}", .{p}));
            rt.checkPrecisionTest(&tester, math.sin(tester.inputValue), taylorSineHonerFusedAsm(p, tester.inputValue), try std.fmt.bufPrint(&label, "tylorSineHonerFusedAsm{d}", .{p}));
        }
    }

    rt.printResults(&tester);
}
