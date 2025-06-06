const std = @import("std");
const mymath = @import("my-math.zig");

pub const EARTH_RADIUS: f64 = 6372.8;

pub fn degreeToRadian(degree: f64) f64 {
    return degree * 0.01745329251994329577;
}

pub fn referenceHaversine(lon1: f64, lat1: f64, lon2: f64, lat2: f64) f64 {
    const dlat = degreeToRadian(lat2 - lat1);
    const dlon = degreeToRadian(lon2 - lon1);
    const llat1 = degreeToRadian(lat1);
    const llat2 = degreeToRadian(lat2);

    const a: f64 = std.math.pow(f64, (std.math.sin(dlat / 2.0)), 2.0) + std.math.cos(llat1) * std.math.cos(llat2) * std.math.pow(f64, (std.math.sin(dlon / 2.0)), 2.0);

    const c: f64 = 2.0 * std.math.asin(std.math.sqrt(a));

    return c * EARTH_RADIUS;
}

pub fn haversineReplacment(lon1: f64, lat1: f64, lon2: f64, lat2: f64) f64 {
    const dlat = degreeToRadian(lat2 - lat1);
    const dlon = degreeToRadian(lon2 - lon1);
    const llat1 = degreeToRadian(lat1);
    const llat2 = degreeToRadian(lat2);

    const a: f64 = std.math.pow(f64, (mymath.sin(dlat / 2.0)), 2.0) + mymath.cos(llat1) * mymath.cos(llat2) * std.math.pow(f64, (mymath.sin(dlon / 2.0)), 2.0);

    const c: f64 = 2.0 * std.math.asin(mymath.sqrt(a));

    return c * EARTH_RADIUS;
}
