const std = @import("std");
const mem = std.mem;

const ParseState = enum {
    reading,
    start,
    end,
    key,
    value,
};

pub fn parseJson(allocator: mem.Allocator, inputFilename: []u8) !void {
    const readBufferSize: usize = 1024 * 1024 * 4;
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

    while (true) {
        readCount = try file.read(readBuffer);
        if (readCount == 0) {
            break;
        }

        for (0..readCount) |i| {
            const chr = readBuffer[i];

            if (!arrayFound) {
                if (chr == '[') {
                    std.debug.print("Found array start at {d}\n", .{totalBytes + i});
                    arrayFound = true;
                }
                continue;
            }

            switch (chr) {
                '[', ']', ',', ':' => {},
                ' ', '\n', '\t' => {},
                '{' => {
                    // std.debug.print("start\n", .{});
                    parser.state = ParseState.start;
                },
                '}' => {
                    // std.debug.print("close\n", .{});
                    parser.state = ParseState.end;
                    std.debug.print("{d} = {d}\n", .{ parser.keyLen, parser.valLen });

                    parser.keyLen = 0;
                    parser.valLen = 0;
                    parser.idx = 0;
                },
                '"' => {
                    // handle token start/stop
                    std.debug.print("!!!!!state: {any} :: keyLen: {any}\n", .{ parser.state, parser.keyLen });
                    if (parser.idx == 0) {
                        parser.state = ParseState.key;
                        parser.idx = 0;
                    } else if (parser.state == ParseState.key) {
                        std.debug.print("ending key with size: {d}", .{parser.idx});
                        parser.state = ParseState.value;
                        parser.keyLen = parser.idx;
                        parser.idx = 0;
                    } else if (parser.state == ParseState.value) {
                        std.debug.print("ending value with size: {d}", .{parser.idx});
                        parser.state = ParseState.key;
                        parser.valLen = parser.idx;
                        parser.idx = 0;
                    }
                },
                else => {
                    std.debug.print("At else with {c} state: {any}, idx: {d}\n", .{ chr, parser.state, parser.idx });
                    // copy char to a buffer
                    if (parser.state == ParseState.key) {
                        parser.key[parser.idx] = chr;
                        parser.idx += 1;
                    } else if (parser.state == ParseState.value) {
                        parser.value[parser.idx] = chr;
                        parser.idx += 1;
                    }
                },
            }
        }

        totalBytes += readCount;
    }

    std.debug.print("Read total of {d} bytes\n", .{totalBytes});
}
