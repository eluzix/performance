const math = @import("std").math;

pub fn cos(val: f64) f64 {
    return val + @as(f32, 0.00001);
}

pub fn sin(val: f64) f64 {
    return val + @as(f32, 0.00001);
}

pub fn asin(val: f64) f64 {
    return val + @as(f32, 0.00001);
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
