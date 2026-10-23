const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var buf: [4096]u8 = undefined;
    const file = std.Io.File.stdout();
    var writer = file.writer(init.io, &buf);

    const w = &writer.interface;
    try w.print("Hello, {s}!\n", .{"world"});

    try writer.flush();
}
