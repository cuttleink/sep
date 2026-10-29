const std = @import("std");

const riscv = @import("../riscv.zig");

pub const raw = @import("raw.zig");

const endian: std.lang.Endian = .little;
// TODO: i am trusting very brief research on this value. i really am not sure
//       whether it is consistently this or if the uses are actually necessary
const page = 0x1000;

pub fn write(w: *std.Io.Writer, segments: []const Segment) !void {
    std.debug.assert(segments[0].content == .code);

    const head = @sizeOf(raw.Elf64) +
        segments.len * @sizeOf(raw.Program64);
    try w.writeStruct(raw.Elf64{
        .data = .from(endian),
        .type = .dynamic,
        .machine = .riscv,
        .entry = head,
        .ph_len = @intCast(segments.len),
    }, endian);

    var off: u64 = head;
    for (segments, 0..) |seg, i| {
        off = place(off, i);

        const size = seg.content.size();
        try w.writeStruct(raw.Program64{
            .type = .load,
            .flags = seg.flags,
            .file_off = off,
            .virt_addr = off,
            .file_size = size,
            .virt_size = size,
            .@"align" = page,
        }, endian);

        off += size;
    }

    off = head;
    for (segments, 0..) |seg, i| {
        const at = place(off, i);
        try w.splatByteAll(0, at - off);

        switch (seg.content) {
            .data => |x| try w.writeAll(x),
            .code => |x| try w.writeSliceEndian(
                riscv.Instruction,
                x,
                endian,
            ),
        }

        off = at + seg.content.size();
    }
}

pub const Segment = struct {
    flags: raw.Program64.Flags,
    content: Content,
};

pub const Content = union(enum) {
    code: []const riscv.Instruction,
    data: []const u8,

    pub fn size(self: Content) u64 {
        return switch (self) {
            .code => |x| x.len * 4,
            .data => |x| x.len,
        };
    }
};

fn place(off: u64, i: usize) u64 {
    return if (i == 0) off else std.mem.alignForward(u64, off, page);
}
