import subprocess

REG_MAP = {
    0: {
        0: 'al',
        1: 'cl',
        2: 'dl',
        3: 'bl',
        4: 'ah',
        5: 'ch',
        6: 'dh',
        7: 'bh',
    },
    1: {
        0: 'ax',
        1: 'cx',
        2: 'dx',
        3: 'bx',
        4: 'sp',
        5: 'bp',
        6: 'si',
        7: 'di',
    }
}

CMD_MAP = {
    0b100010: 'mov',
    0b1100011: 'mov',
    0b1011: 'mov',
    0b1010000: 'mov',
    0b10001110: 'mov',
    0b10001100: 'mov',
}

EFFECTIVE_ADDRESS = {
    0b00: 'bx+si',
    0b01: 'bx+di',
    0b10: 'bp+si',
    0b11: 'bp+di',
    0b100: 'si',
    0b101: 'di',
    0b110: 'bp',
    0b111: 'bx',
}


class Instruction:
    op = 0
    real_op = None
    d = 0
    w = 0
    mod = 0
    reg = 0
    rm = 0
    low_displacement = 0
    high_displacement = 0

    def __init__(self, instruction: bytes | int):
        if isinstance(instruction, int):
            self.op = instruction
        else:
            self.op = instruction[0]

    @property
    def displacement_size(self):
        return 0

    def add_displacement(self, displacement: bytes):
        if self.displacement_size == 1:
            self.low_displacement = displacement[0]
        elif self.displacement_size == 2:
            self.low_displacement = displacement[0]
            self.high_displacement = displacement[1]

    def combine_displacement(self):
        return self.low_displacement + (self.high_displacement << 8)
        # bit_size = self.high_displacement.bit_length()
        # return self.high_displacement << (8 - bit_size) | self.low_displacement


class MovInstruction(Instruction):

    def __init__(self, instruction: bytes):
        self.op = instruction[0] >> 2
        self.d = instruction[0] & 0b10
        self.w = instruction[0] & 0b1
        self.mod = instruction[1] >> 6
        self.reg = (instruction[1] >> 3) & 0b111
        self.rm = instruction[1] & 0b111
        # if self.d == 0:
        #     self.reg = instruction[1] & 0b111
        #     self.rm = (instruction[1] >> 3) & 0b111
        # else:
        #     self.reg = (instruction[1] >> 3) & 0b111
        #     self.rm = instruction[1] & 0b111

    @property
    def displacement_size(self):
        if self.mod == 0b01:
            return 1
        elif self.mod == 0b10 or self.mod == 0 and self.rm == 0b110:
            return 2
        # elif self.rm == 0b110:
        #     return 2
        else:
            return 0

    def debug(self):
        return f'op: {self.op:b}, d: {self.d:b}, w: {self.w:b}, mod: {self.mod:b}, reg: {self.reg:b}, rm: {self.rm:b}'

    def __str__(self):
        left_op = REG_MAP[self.w][self.reg]
        right_op = None
        if self.mod == 0 and self.rm != 0b110:
            right_op = f'[{EFFECTIVE_ADDRESS[self.rm]}]'
        elif self.mod == 0b11:
            right_op = REG_MAP[self.w][self.rm]
        elif self.mod == 0b01 and self.low_displacement == 0:
            right_op = f'[{EFFECTIVE_ADDRESS[self.rm]}]'
        elif self.mod == 0b01:
            right_op = f'[{EFFECTIVE_ADDRESS[self.rm]} + {self.low_displacement}]'
        elif self.mod == 0b10:
            right_op = f'[{EFFECTIVE_ADDRESS[self.rm]}+{self.combine_displacement()}]'
        else:
            raise ValueError(f'Unknown mod: {self.mod:b}')

        if self.d == 0:
            left_op, right_op = right_op, left_op

        return f'{CMD_MAP[self.op]} {left_op}, {right_op}'


class MovImmediate2RegisterInstruction(MovInstruction):

    def __init__(self, instruction: bytes | int):
        self.op = instruction[0] >> 4
        self.w = instruction[0] >> 3 & 0b1
        self.reg = instruction[0] & 0b111
        self.low_displacement = instruction[1]

    @property
    def displacement_size(self):
        return 0 if self.w == 0 else 1

    def add_displacement(self, displacement: bytes):
        self.high_displacement = displacement[0]

    def __str__(self):
        reg_size = 0 if self.w == 0 else 1
        value = self.low_displacement
        # if self.w == 0 and self.mod != 0:
        if self.w == 1:
            # if self.mod not in [0, 0b11]:
            value = self.combine_displacement()

        return f'{CMD_MAP[self.op]} {REG_MAP[reg_size][self.reg]}, {value}'


class ArithmeticInstruction(Instruction):

    def __init__(self, instruction: bytes):
        self.op = instruction[0] >> 2
        self.d = instruction[0] & 0b10
        self.w = instruction[0] & 0b1

        self.mod = instruction[1] >> 6
        self.reg = (instruction[1] >> 3) & 0b111
        self.rm = instruction[1] & 0b111

        real_op = instruction[0] >> 3 & 0b111
        if real_op == 0b101:
            self.real_op = 'sub'
        elif real_op == 0b111:
            self.real_op = 'cmp'
        elif self.reg == 0b000:
            self.real_op = 'add'
        elif self.reg == 0b101:
            self.real_op = 'sub'
        elif self.reg == 0b111:
            self.real_op = 'cmp'
        elif self.reg == 0b11:
            self.real_op = 'sbb'
        else:
            raise ValueError(f'Unknown op: {real_op:b}')

    @property
    def displacement_size(self):
        if self.mod == 0b01:
            return 1
        elif self.mod == 0b10 or self.mod == 0 and self.rm == 0b110:
            return 2
        else:
            return 0

    def __str__(self):
        return f'{self.real_op} {REG_MAP[self.w][self.reg]}, {REG_MAP[self.w][self.rm]}'


def parse_instruction(instruction: bytes):
    if instruction[0] >> 4 == 0b1011:
        # immediate to register
        return MovImmediate2RegisterInstruction(instruction)
    elif instruction[0] >> 1 == 0b1100011:
        # immediate to register
        return MovImmediate2RegisterInstruction(instruction)
    elif instruction[0] >> 2 == 0b100010:
        # register to register
        return MovInstruction(instruction)
    elif instruction[0] >> 1 == 0b1010000:
        # memory to accumulator
        return MovInstruction(instruction)
    elif instruction[0] >> 1 == 0b1010001:
        # accumulator to memory
        return MovInstruction(instruction)
    elif instruction[0] >> 2 in [0b0, 0x001010, 0x001110, 0b100000]:
        return ArithmeticInstruction(instruction)
    elif instruction[0] >> 1 in [0b10, 0x0010110, 0x0011110]:
        return ArithmeticInstruction(instruction)


if __name__ == '__main__':
    count = 0
    filename = 'listing add sub cmp jnz'
    with open(f'{filename}-result.asm', 'w') as fout:
        fout.write("bits 16\n\n")
        with open(filename, 'rb') as fin:
            instruction = fin.read(2)
            while instruction:
                count += 1
                cmd = parse_instruction(instruction)
                if cmd.displacement_size > 0:
                    displacement = fin.read(cmd.displacement_size)
                    cmd.add_displacement(displacement)

                fout.write(str(cmd))
                fout.write('\n')
                instruction = fin.read(2)

    subprocess.run(['/opt/homebrew/bin/nasm', f'{filename}-result.asm'])
    subprocess.run(['diff', filename, f'{filename}-result.asm'])
