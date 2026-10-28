const std = @import("std");

pub const Elf64 = extern struct {
    const size = @sizeOf(Elf64);

    magic: [4]u8 = .{ 0x7f, 'E', 'L', 'F' },
    class: Class = .@"64",
    data: Data,
    _0: u8 = 1,
    abi: Abi = .sysv,
    _1: [7]u8 = @splat(0),
    type: Type,
    machine: Machine,
    _2: u32 = 1,
    entry: u64,
    ph_off: u64 = size,
    sh_off: u64 = 0,
    flags: u32 = 0,
    eh_size: u16 = size,
    ph_size: u16 = @sizeOf(Program64),
    ph_len: u16,
    sh_size: u16 = 0,
    sh_len: u16 = 0,
    sh_str_i: u16 = 0,

    const Class = enum(u8) { @"32" = 1, @"64" = 2 };
    pub const Data = enum(u8) {
        little = 1,
        big = 2,

        pub fn from(endian: std.lang.Endian) Data {
            return switch (endian) {
                .little => .little,
                .big => .big,
            };
        }
    };

    pub const Abi = enum(u8) { sysv = 0 };

    pub const Type = enum(u16) {
        executable = 2,
        dynamic = 3,
    };

    pub const Machine = enum(u16) { riscv = 0xf3 };
};

pub const Program64 = extern struct {
    type: Type,
    flags: Flags,
    file_off: u64,
    virt_addr: u64 = 0,
    phys_addr: u64 = 0,
    file_size: u64,
    virt_size: u64,
    @"align": u64 = 0,

    pub const Type = enum(u32) { load = 1 };

    pub const Flags = packed struct(u32) {
        executable: bool = false,
        writable: bool = false,
        readable: bool = false,
        _: u29 = 0,
    };
};
