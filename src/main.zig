const std = @import("std");

const macho = @import("macho.zig");

const endian: std.lang.Endian = .little;

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
    const w = &writer.interface;

    try w.writeStruct(mach.header, endian);
    try w.writeAll(&exe.text);

    try writer.flush();
}

const mach = struct {
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

const exe = struct {
    const code = [_]u32{
        0xd2800020, // mov x0,   #1   ; fd = stdout
        0x100000e1, // adr x1,   msg  ; addr = pc + 28
        0xd28001c2, // mov x2,   #14  ; length = 24
        0xd2800090, // mov x16,  #4   ; SYS_write
        0xd4001001, // svc #0x80      ; syscall
        0xd2800000, // mov x0,   #0   ; status = 0
        0xd2800030, // mov x16,  #1   ; SYS_exit
        0xd4001001, // svc #0x80      ; syscall
    };

    const msg = "Hello, world!\n";

    const text = blk: {
        const msg_start = code.len * 4;
        const length = msg_start + msg.len;
        var out: [length]u8 = undefined;

        for (code, 0..) |word, i|
            std.mem.writeInt(u32, out[i * 4 ..][0..4], word, endian);
        @memcpy(out[msg_start..], msg);

        break :blk out;
    };
};

fn size(value: anytype) comptime_int {
    return @sizeOf(@TypeOf(value));
}

fn len(value: anytype) comptime_int {
    return @typeInfo(@TypeOf(value)).@"struct".field_names.len;
}
