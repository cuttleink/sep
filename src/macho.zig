pub const Header = extern struct {
    magic: Magic,
    cpu: Cpu,
    type: Type,
    cmds_len: u32,
    cmds_size: u32,
    flags: Flags,

    pub const Magic = enum(u32) {
        @"32" = 0xfeedface,
        @"64" = 0xfeedfacf,
    };

    pub const Cpu = extern struct {
        arch: Arch,
        type: extern union {
            arm64: Arm64,
        },

        pub fn arm64(kind: Arm64) Cpu {
            return .{
                .arch = .{ .family = .arm, .size = .@"64" },
                .type = .{ .arm64 = kind },
            };
        }

        pub const Arch = packed struct(u32) {
            family: Family,
            size: Size,

            pub const Family = enum(u24) { arm = 12 };

            pub const Size = enum(u8) {
                @"32" = 0,
                @"64" = 1,
            };
        };

        pub const Arm64 = enum(u32) { all = 0 };
    };

    pub const Type = enum(u32) { execute = 2 };

    pub const Flags = packed struct(u32) {
        _0: u2 = 0,
        dyld: bool = false,
        _1: u18 = 0,
        pie: bool = false,
        _2: u10 = 0,
    };
};

pub const Header64 = extern struct {
    inner: Header,
    _: u32 = 0,
};
