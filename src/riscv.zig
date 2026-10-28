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

pub const I = packed struct {
    opcode: Opcode,
    dest: Register,
    func: u3,
    source: Register,
    imm: u12,

    pub const Opcode = enum(u7) {
        imm = 0b0010011,
        system = 0b1110011,
    };
};

pub const U = packed struct {
    opcode: Opcode,
    dest: Register,
    imm: u20,

    pub const Opcode = enum(u7) { auipc = 0b0010111 };
};

pub fn addi(dest: Register, source: Register, imm: i12) u32 {
    return @bitCast(I{
        .opcode = .imm,
        .dest = dest,
        .func = 0,
        .source = source,
        .imm = @bitCast(imm),
    });
}

pub fn ecall() u32 {
    return @bitCast(I{
        .opcode = .system,
        .dest = .zero,
        .func = 0,
        .source = .zero,
        .imm = 0,
    });
}

pub fn auipc(dest: Register, imm: i20) u32 {
    return @bitCast(U{
        .opcode = .auipc,
        .dest = dest,
        .imm = @bitCast(imm),
    });
}
