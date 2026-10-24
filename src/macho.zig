pub const Header64 = extern struct {
    magic: u32 = 0xfeedfacf,
    cpu: Cpu,
    type: Type,
    cmds_len: u32,
    cmds_size: u32,
    flags: Flags = .{},
};

pub const Cpu = extern struct {
    arch: Arch,
    type: extern union {
        arm64: Arm64,
    },

    pub fn arm64(kind: Arm64) Cpu {
        return .{
            .arch = .arm64,
            .type = .{ .arm64 = kind },
        };
    }

    pub const Arch = enum(u32) {
        const arm = 12;
        const @"64" = 0x01000000;

        arm64 = arm | @"64",
    };

    pub const Arm64 = enum(u32) { all = 0 };
};

pub const Type = enum(u32) { execute = 2 };

pub const Flags = packed struct(u32) { _: u32 = 0 };
