const std = @import("std");

const elf = @import("elf/mod.zig");

const text = "Hello, world!\n";
const segs: []const elf.Segment = &.{
    .{
        .flags = .{ .execute = true, .read = true },
        .content = .{ .code = &.{
            .auipc(.a1, 1),
            .addi(.a1, .a1, -176),

            .addi(.a0, .zero, 1),
            .addi(.a2, .zero, text.len),
            .addi(.a7, .zero, 64),
            .ecall(),

            .addi(.a0, .zero, 0),
            .addi(.a7, .zero, 93),
            .ecall(),
        } },
    },
    .{
        .flags = .{ .read = true },
        .content = .{ .data = text },
    },
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.gpa;

    var args = try init.minimal.args
        .iterateAllocator(alloc);
    defer args.deinit();

    const name = args.next().?;
    const out = args.next() orelse {
        std.debug.print("Usage: {s} <output>\n", .{name});
        std.process.exit(1);
    };

    const file = try std.Io.Dir.cwd()
        .createFile(io, out, .{});
    defer file.close(io);

    var buf: [4096]u8 = undefined;
    var writer = file.writer(io, &buf);

    try write(alloc, &writer.interface);
    try writer.flush();
}

fn write(alloc: std.mem.Allocator, w: *std.Io.Writer) !void {
    _ = alloc;

    try elf.write(w, segs);
}
