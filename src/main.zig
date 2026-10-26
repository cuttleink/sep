const builtin = @import("builtin");
const std = @import("std");

const MachO = @import("MachO/mod.zig");

const exe = .{};

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;
    const io = init.io;

    var args = try init.minimal.args
        .iterateAllocator(alloc);
    defer args.deinit();

    const name = args.next().?;
    const output = args.next() orelse {
        std.debug.print("Usage: {s} <output>\n", .{name});
        std.process.exit(1);
    };

    var macho: MachO = try .open_rel(
        io,
        output,
        .{
            .cpu = .arm64(.all),
            .type = .execute,
        },
        0,
    );

    try macho.close(io);
}
