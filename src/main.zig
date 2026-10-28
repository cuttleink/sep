const std = @import("std");

const elf = @import("elf.zig");
const riscv = @import("riscv.zig");

const endian: std.lang.Endian = .little;

const pre = @sizeOf(elf.Elf64) + @sizeOf(elf.Program64);
const blob = concat(&text.code, text.data);
const size = pre + blob.len;

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

    try w.writeStruct(elf.Elf64{
        .data = .from(endian),
        .type = .dynamic,
        .machine = .riscv,
        .entry = pre,
        .ph_len = 1,
    }, endian);

    try w.writeStruct(elf.Program64{
        .type = .load,
        .flags = .{
            .executable = true,
            .readable = true,
        },
        .file_off = 0,
        .file_size = size,
        .virt_size = size,
    }, endian);

    try w.writeAll(&blob);

    try writer.flush();
}

const text = struct {
    const code = [_]u32{
        riscv.auipc(.a1, 0),
        riscv.addi(.a1, .a1, 0x24),

        riscv.addi(.a0, .zero, 1),
        riscv.addi(.a2, .zero, data.len),
        riscv.addi(.a7, .zero, 64),
        riscv.ecall(),

        riscv.addi(.a0, .zero, 0),
        riscv.addi(.a7, .zero, 93),
        riscv.ecall(),
    };

    const data = "Hello, world!\n";
};

fn concat(code: []const u32, data: []const u8) [code.len * 4 + data.len]u8 {
    var out: [code.len * 4 + data.len]u8 = undefined;

    for (code, 0..) |word, i|
        std.mem.writeInt(u32, out[i * 4 ..][0..4], word, endian);
    @memcpy(out[code.len * 4 ..][0..data.len], data);

    return out;
}
