const MachO = @import("mod.zig");

pub const Header = extern struct {
    magic: Magic,
    cpu: MachO.Cpu,
    type: MachO.Type,
    cmds_len: u32,
    cmds_size: u32,
    flags: Flags,

    pub const Magic = enum(u32) {
        @"32" = 0xfeedface,
        @"64" = 0xfeedfacf,

        pub fn from(cpu: MachO.Cpu) Magic {
            return switch (cpu.arch.abi) {
                .@"32" => .@"32",
                .@"64" => .@"64",
            };
        }
    };

    pub const Flags = packed struct(u32) {
        _0: u2 = 0,
        dyld: bool = false,
        _1: u18 = 0,
        pie: bool = false,
        _2: u10 = 0,
    };
};
