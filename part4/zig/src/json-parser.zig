const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const haversine = @import("haversine.zig");
const profiler = @import("profiler.zig");

const ParseState = enum {
    reading,
    start,
    end,
    key,
    value,
};

const Point = struct {
    X0: f64,
    Y0: f64,
    X1: f64,
    Y1: f64,

    pub fn updateField(self: *Point, key: []u8, value: []u8) !void {
        if (key.len != 2) return;
        const v = try std.fmt.parseFloat(f64, value);

        switch (key[0]) {
            'x' => {
                switch (key[1]) {
                    '0' => self.X0 = v,
                    '1' => self.X1 = v,
                    else => unreachable,
                }
            },
            'y' => {
                switch (key[1]) {
                    '0' => self.Y0 = v,
                    '1' => self.Y1 = v,
                    else => unreachable,
                }
            },
            else => unreachable,
        }
    }
};

fn bytesToFloat(bytes: []u8) f64 {
    return @bitCast(mem.readInt(u64, &[_]u8{
        bytes[0],
        bytes[1],
        bytes[2],
        bytes[3],
        bytes[4],
        bytes[5],
        bytes[6],
        bytes[7],
    }, .little));
}

// pub const HaversineSetup = struct { pointsCount: u64, points: std.ArrayList(Point), answers: std.ArrayList(f64), answersSum: f64, valid: bool };
pub const HaversineSetup = struct { pointsCount: u64, points: []Point, answers: []f64, answersSum: f64, valid: bool, totalBytes: u64 };

pub fn setupHaversine(allocator: mem.Allocator, inputFilename: []u8) !HaversineSetup {
    // var pr = try profiler.Profiler.new(allocator);
    // pr.startProfile();

    // var span = try pr.startSpan("init");
    const readBufferSize: usize = 1024 * 1024 * 16;
    const readBuffer: []u8 = try allocator.alloc(u8, readBufferSize);
    defer allocator.free(readBuffer);

    const fileName = try std.fmt.allocPrint(allocator, "{s}.json", .{inputFilename});

    const cwd = std.fs.cwd();
    const file = try cwd.openFile(fileName, .{});
    defer file.close();

    var arrayFound = false;
    var totalBytes: u64 = 0;
    var readCount: u64 = 0;

    const parser = struct {
        var state: ParseState = ParseState.reading;
        var idx: u64 = 0;
        var keyLen: u64 = 0;
        var valLen: u64 = 0;
        var key: [1024]u8 = std.mem.zeroes([1024]u8);
        var value: [1024]u8 = std.mem.zeroes([1024]u8);
    };
    var point: Point = Point{
        .X0 = 0.0,
        .Y0 = 0.0,
        .X1 = 0.0,
        .Y1 = 0.0,
    };
    var points = try std.ArrayList(Point).initCapacity(allocator, 10000);
    // var allPoints = try std.ArrayList(Point).initCapacity(allocator, 10000);
    // defer allPoints.deinit();

    // pr.stopSpan(span, readBufferSize);

    // var innerSpan: usize = undefined;
    while (true) {
        // span = try pr.startSpan("read");
        readCount = try file.read(readBuffer);
        if (readCount == 0) {
            // pr.stopSpan(span, 0);
            break;
        }
        // pr.stopSpan(span, readCount);

        // span = try pr.startSpan("parse");
        for (0..readCount) |i| {
            const chr = readBuffer[i];

            if (!arrayFound) {
                if (chr == '[') {
                    arrayFound = true;
                }
                continue;
            }

            switch (chr) {
                '{' => {
                    // std.debug.print("start\n", .{});
                    parser.state = ParseState.start;
                },
                '}' => {
                    // std.debug.print("close\n", .{});
                    parser.state = ParseState.end;

                    const k = parser.key[0..parser.keyLen];
                    const v = parser.value[0..parser.valLen];
                    // innerSpan = try pr.startSpan("updateField");
                    try point.updateField(k, v);
                    // pr.stopSpan(innerSpan, 0);
                    try points.append(point);

                    parser.keyLen = 0;
                    parser.valLen = 0;
                    parser.idx = 0;
                },
                '"' => {
                    // handle token start/stop
                    // std.debug.print("!!!!!state: {any} :: keyLen: {any}\n", .{ parser.state, parser.keyLen });
                    if (parser.idx == 0) {
                        parser.state = ParseState.key;
                        parser.idx = 0;
                    } else if (parser.state == ParseState.key) {
                        // std.debug.print("ending key with size: {d}", .{parser.idx});
                        parser.state = ParseState.value;
                        parser.keyLen = parser.idx;
                        parser.idx = 0;
                    } else if (parser.state == ParseState.value) {
                        // std.debug.print("ending value with size: {d}", .{parser.idx});
                        parser.state = ParseState.key;
                        parser.valLen = parser.idx;
                        parser.idx = 0;

                        const k = parser.key[0..parser.keyLen];
                        const v = parser.value[0..parser.valLen];
                        // innerSpan = try pr.startSpan("updateField");
                        try point.updateField(k, v);
                        // pr.stopSpan(innerSpan, 0);
                    }
                },
                '[', ']', ',', ':' => {},
                ' ', '\n', '\t' => {},
                else => {
                    // std.debug.print("At else with {c} state: {any}, idx: {d}\n", .{ chr, parser.state, parser.idx });
                    // copy char to a buffer
                    if (parser.state == ParseState.key) {
                        parser.key[parser.idx] = chr;
                    } else if (parser.state == ParseState.value) {
                        parser.value[parser.idx] = chr;
                    } else {
                        continue;
                    }

                    parser.idx += 1;
                },
            }
        }

        totalBytes += readCount;
        // pr.stopSpan(span, readCount);
    }
    _ = points.pop();

    const pointsCount = points.items.len;
    // setup.pointsCount = points.items.len;
    std.debug.print("Read total of {d} bytes\n", .{totalBytes});
    std.debug.print("found total of {d} points\n", .{pointsCount});

    const totalBuf: []u8 = try allocator.alloc(u8, 8);
    defer allocator.free(totalBuf);

    const binFileName = try std.fmt.allocPrint(allocator, "{s}.json.bin", .{inputFilename});
    const binFile = try std.fs.cwd().openFile(binFileName, .{});
    defer binFile.close();

    var answers = try std.ArrayList(f64).initCapacity(allocator, pointsCount);
    for (points.items) |_| {
        const rb = try binFile.read(totalBuf);
        assert(rb == 8);
        const binValue: f64 = bytesToFloat(totalBuf);
        try answers.append(binValue);
    }

    _ = try binFile.read(totalBuf);
    const binValue: f64 = bytesToFloat(totalBuf);

    // pr.endProfile();
    // _ = try pr.report();
    return HaversineSetup{
        .points = try points.toOwnedSlice(),
        .valid = true,
        .answersSum = binValue,
        .pointsCount = pointsCount,
        .totalBytes = totalBytes,
        .answers = try answers.toOwnedSlice(),
    };
}
