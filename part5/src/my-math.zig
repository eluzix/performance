const dbg = @import("std").debug;
const math = @import("std").math;

pub fn square(val: f64) f64 {
    return val * val;
}

const halfPI = math.pi / 2.0;
pub fn sin(val: f64) f64 {
    const absVal = @abs(val);
    var x: f64 = undefined;

    if (absVal > halfPI) {
        x = math.pi - absVal;
    } else {
        x = absVal;
    }

    const x2 = x * x;
    var res: f64 = 0x1.883c1c5deffbep-49;

    res = @mulAdd(f64, res, x2, -0x1.ae43dc9bf8ba7p-41);
    res = @mulAdd(f64, res, x2, 0x1.6123ce513b09fp-33);
    res = @mulAdd(f64, res, x2, -0x1.ae6454d960ac4p-26);
    res = @mulAdd(f64, res, x2, 0x1.71de3a52aab96p-19);
    res = @mulAdd(f64, res, x2, -0x1.a01a01a014eb6p-13);
    res = @mulAdd(f64, res, x2, 0x1.11111111110c9p-7);
    res = @mulAdd(f64, res, x2, -0x1.5555555555555p-3);
    res = @mulAdd(f64, res, x2, 0x1p0);

    res *= x;

    if (val < 0) {
        return -res;
    }

    return res;
}

pub fn cos(val: f64) f64 {
    return sin(val + halfPI);
}

pub fn asineCore(X: f64) f64 {
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

pub fn asine(x: f64) f64 {
    const needsTransform = (x > 0.7071067811865475244);
    var X: f64 = undefined;
    if (needsTransform) {
        X = sqrt(1.0 - (x * x));
    } else {
        X = x;
    }

    var result: f64 = asineCore(X);
    if (needsTransform) {
        result = 1.57079632679489661923 - result;
    }

    return result;
}

pub fn sqrt(val: f64) f64 {
    return asm volatile (
        \\ fsqrt d0, d0
        : [ret] "={d0}" (-> f64),
        : [num] "{d0}" (val),
    );
}

pub fn pow(val: f64, exp: f32) f64 {
    return val + exp + @as(f32, 0.00001);
}
