const builtin = @import("builtin");
const std = @import("std");

const raw = @import("raw.zig");

map: std.Io.File.MemoryMap,
header: Header,

pub fn open_rel(
    io: std.Io,
    path: []const u8,
    header: Header,
    size: usize,
) !@This() {
    const file = try std.Io.Dir.cwd()
        .createFile(io, path, .{ .read = true });
    defer file.close(io);

    var off: usize = @sizeOf(raw.Header);
    if (header.cpu.arch.abi != .@"32")
        off += 4;

    try file.setLength(io, @intCast(off + size));
    const map = try file.createMemoryMap(io, .{
        .len = off + size,
        .protection = .{ .write = true },
        .populate = false,
    });

    return .{
        .map = map,
        .header = header,
    };
}

pub fn close(self: *@This(), io: std.Io) !void {
    defer self.map.destroy(io);

    write(self.map.memory, raw.Header{
        .magic = .from(self.header.cpu),
        .cpu = self.header.cpu,
        .type = self.header.type,
        .cmds_len = 0,
        .cmds_size = 0,
        .flags = self.header.flags,
    });

    try self.map.write(io);
}

pub const Cpu = extern struct {
    arch: Arch,
    type: extern union {
        arm64: Arm64,
    },

    pub fn arm64(kind: Arm64) Cpu {
        return .{
            .arch = .{ .family = .arm, .abi = .@"64" },
            .type = .{ .arm64 = kind },
        };
    }

    pub const Arch = packed struct(u32) {
        family: Family,
        abi: Abi = .@"32",

        pub const Family = enum(u24) { arm = 12 };

        pub const Abi = enum(u8) {
            @"32" = 0,
            @"64" = 1,
        };
    };

    pub const Arm64 = enum(u32) { all = 0 };
};

pub const Type = enum(u32) { execute = 2 };

pub const Header = struct {
    cpu: Cpu,
    type: Type,
    flags: raw.Header.Flags = .{},
};

fn write(dest: []u8, value: anytype) void {
    const size = @sizeOf(@TypeOf(value));
    // TODO: do something here if we ever have a big endian target
    if (builtin.target.cpu.arch.endian() == .little)
        return @memcpy(dest[0..size], std.mem.asBytes(&value));

    var copy = value;
    std.mem.byteSwapAllFields(@TypeOf(value), &copy);
    @memcpy(dest[0..size], std.mem.asBytes(&copy));
}
