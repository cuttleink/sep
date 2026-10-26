const std = @import("std");

const macho = @import("macho.zig");

const exe = struct {
    const header = macho.Header64{ .inner = .{
        .magic = .@"64",
        .cpu = .arm64(.all),
        .type = .execute,
        .cmds_len = 0,
        .cmds_size = 0,
        .flags = .{
            .dyld = true,
            .pie = true,
        },
    } };
};

pub fn main() void {}

fn size(value: anytype) comptime_int {
    return @sizeOf(@TypeOf(value));
}
