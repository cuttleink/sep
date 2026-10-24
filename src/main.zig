const std = @import("std");

const macho = @import("macho.zig");

const exe = struct {
    const header: macho.Header64 = .{
        .cpu = .arm64(.all),
        .type = .execute,
        .cmds_len = 0,
        .cmds_size = 0,
    };
};

pub fn main(init: std.process.Init) !void {
    var buf: [4096]u8 = undefined;
    const file = std.Io.File.stdout();
    var writer = file.writer(init.io, &buf);

    const w = &writer.interface;
    try w.writeStruct(exe.header, .little);

    try writer.flush();
}
