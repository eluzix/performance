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
    while (true) {
        readCount = try file.read(readBuffer);
        if (readCount == 0) {
            break;
        }

        for (0..readCount) |i| {
            if (!arrayFound) {
                if (readBuffer[i] == '[') {
                    std.debug.print("Found array start at {d}\n", .{totalBytes + i});
                    arrayFound = true;
                }
                continue;
            }
        }

        totalBytes += readCount;
    }

    std.debug.print("Read total of {d} bytes\n", .{totalBytes});
}
