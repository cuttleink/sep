const std = @import("std");

pub const Register = enum(u5) {
    zero,
    ra,
    sp,
    gp,
    tp,
    t0,
    t1,
    t2,
    s0,
    s1,
    a0,
    a1,
    a2,
    a3,
    a4,
    a5,
    a6,
    a7,
    s2,
    s3,
    s4,
    s5,
    s6,
    s7,
    s8,
    s9,
    s10,
    s11,
    t3,
    t4,
    t5,
    t6,
};

pub const Instruction = enum(u32) {
    _,

    pub const auipc = U(.auipc);
    pub const addi = I(.op_imm, 0b000);
    pub const ecall = fixed(I(.system, 0b000)(.zero, .zero, 0));

    const Op = enum(u7) {
        op_imm = 0b0010011,
        auipc = 0b0010111,
        system = 0b1110011,
    };

    fn I(op: Op, func: u3) fn (Register, Register, i12) Instruction {
        return struct {
            fn a(dest: Register, source: Register, imm: i12) Instruction {
                return @bitCast(pack(.{ op, dest, func, source, imm }));
            }
        }.a;
    }

    fn U(op: Op) fn (Register, i20) Instruction {
        return struct {
            fn a(dest: Register, imm: i20) Instruction {
                return @bitCast(pack(.{ op, dest, imm }));
            }
        }.a;
    }

    fn fixed(inst: Instruction) fn () Instruction {
        return struct {
            fn a() Instruction {
                return inst;
            }
        }.a;
    }
};

fn pack(value: anytype) Pack(@TypeOf(value)) {
    const Value = @TypeOf(value);
    var new: Pack(Value) = undefined;
    inline for (@typeInfo(Value).@"struct".field_names) |name|
        @field(new, name) = @field(value, name);
    return new;
}

fn Pack(T: type) type {
    const info = @typeInfo(T).@"struct";
    const attrs: [info.field_names.len]std.lang.Type
        .Struct.FieldAttributes = @splat(.{});

    return @Struct(
        .@"packed",
        null,
        info.field_names,
        info.field_types,
        &attrs,
    );
}
