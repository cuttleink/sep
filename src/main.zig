const std = @import("std");

const elf = @import("elf.zig");
const riscv = @import("riscv.zig");

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

    try write(alloc, &writer.interface);
    try writer.flush();
}

fn write(alloc: std.mem.Allocator, w: *std.Io.Writer) !void {
    _ = alloc;

    const pre = @sizeOf(elf.Elf64) + @sizeOf(elf.Program64);
    const total = pre + blob.len;

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
        .file_size = total,
        .virt_size = total,
    }, endian);

    try w.writeAll(&blob);
}

const text = "Hello, world!\n";
const blob = concat(&.{
    .auipc(.a1, 0),
    .addi(.a1, .a1, 0x24),

    .addi(.a0, .zero, 1),
    .addi(.a2, .zero, text.len),
    .addi(.a7, .zero, 64),
    .ecall(),

    .addi(.a0, .zero, 0),
    .addi(.a7, .zero, 93),
    .ecall(),
}, text);

fn concat(
    code: []const riscv.Instruction,
    data: []const u8,
) [code.len * 4 + data.len]u8 {
    var out: [code.len * 4 + data.len]u8 = undefined;

    for (code, 0..) |word, i|
        std.mem.writeInt(u32, out[i * 4 ..][0..4], @backingInt(word), endian);
    @memcpy(out[code.len * 4 ..][0..data.len], data);

    return out;
}
