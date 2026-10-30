const std = @import("std");

const riscv = @import("../riscv.zig");

pub const raw = @import("raw.zig");

const endian: std.lang.Endian = .little;
const page = 0x1000;

text: []const riscv.Instruction,
segments: []const Segment,

pub fn write(self: @This(), w: *std.Io.Writer) !void {
    std.debug.assert(self.text.len > 0);
    for (self.segments) |seg|
        std.debug.assert(seg.zeros == 0 or
            seg.flags.write);

    const ph_len = self.segments.len + 1;
    const head = @sizeOf(raw.Elf64) +
        ph_len * @sizeOf(raw.Program64);
    try w.writeStruct(raw.Elf64{
        .data = .from(endian),
        .type = .dynamic,
        .machine = .riscv,
        .entry = head,
        .ph_len = @intCast(ph_len),
    }, endian);

    const len = self.text.len * 4;
    try w.writeStruct(raw.Program64{
        .type = .load,
        .flags = .{ .execute = true },
        .file_off = head,
        .virt_addr = head,
        .file_size = len,
        .virt_size = len,
    }, endian);

    {
        var off: u64 = head + len;
        var addr = off;

        for (self.segments) |seg| {
            addr = std.mem.alignForward(u64, addr, page) +
                off % page;

            try w.writeStruct(raw.Program64{
                .type = .load,
                .flags = seg.flags,
                .file_off = off,
                .virt_addr = addr,
                .file_size = seg.data.len,
                .virt_size = seg.data.len + seg.zeros,
            }, endian);

            off += seg.data.len;
            addr += seg.data.len + seg.zeros;
        }
    }

    try w.writeSliceEndian(riscv.Instruction, self.text, endian);
    for (self.segments) |seg| try w.writeAll(seg.data);
}

pub const Segment = struct {
    flags: raw.Program64.Flags,
    data: []const u8,
    zeros: u64 = 0,
};
