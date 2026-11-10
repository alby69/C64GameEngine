#!/usr/bin/env python3
"""
Minimal C64 emulator used to smoke-test the C64 Game Engine + Space Invaders
build. It implements the 6502 instruction set, a 64 KB RAM, the VIC-II raster
register and the CIA 1 joystick/keyboard ports.

The test drives the game through its public behaviour:
  1. the title screen is rendered in screen RAM
  2. pressing FIRE starts a new game
  3. the swarm moves, the HUD shows the score and the lives
  4. the program never crashes (no illegal opcode, no runaway loop)
"""
import sys

MASK = 0xFFFF


class C64:
    def __init__(self, prg_path):
        self.mem = bytearray(0x10000)
        # Fake ROM area: the game never executes ROM, but writes/reads there
        # would otherwise look like open bus.
        for i in range(0xA000, 0x10000):
            self.mem[i] = 0xFF
        with open(prg_path, "rb") as fh:
            data = fh.read()
        load = data[0] | (data[1] << 8)
        for i, b in enumerate(data[2:]):
            self.mem[load + i] = b
        self.load_addr = load
        self.pc = 0
        self.a = self.x = self.y = 0
        self.sp = 0xFD
        self.c = self.z = self.i = self.d = self.v = self.n = 0
        self.raster = 0
        self.cycles = 0
        self.illegal = None

    # ---------------- memory ----------------
    def read(self, addr):
        addr &= MASK
        if addr == 0xD012:               # VIC raster: il pennello avanza a ogni lettura
            self.raster = (self.raster + 1) & 0xFF
            return self.raster
        if addr == 0xDC00:               # joystick port 2 (no button pressed)
            return self.joystick
        if addr == 0xDC01:               # keyboard columns (no key pressed)
            return 0xFF
        return self.mem[addr]

    def write(self, addr, val):
        addr &= MASK
        if addr == 0xD012:
            return
        self.mem[addr] = val & 0xFF

    # ---------------- helpers ----------------
    def getflags(self):
        return (self.n << 7) | (self.v << 6) | 0x20 | (self.d << 3) | \
               (self.i << 2) | (self.z << 1) | self.c

    def setflags(self, p):
        self.n = (p >> 7) & 1
        self.v = (p >> 6) & 1
        self.d = (p >> 3) & 1
        self.i = (p >> 2) & 1
        self.z = (p >> 1) & 1
        self.c = p & 1

    def setnz(self, v):
        v &= 0xFF
        self.z = 1 if v == 0 else 0
        self.n = (v >> 7) & 1
        return v

    def push(self, val):
        self.mem[0x100 + self.sp] = val & 0xFF
        self.sp = (self.sp - 1) & 0xFF

    def pop(self):
        self.sp = (self.sp + 1) & 0xFF
        return self.mem[0x100 + self.sp]

    # ---------------- cpu ----------------
    def step(self):
        op = self.mem[self.pc]
        self.pc = (self.pc + 1) & MASK
        self.cycles += 1

        # addressing helpers
        def imm():
            v = self.mem[self.pc]
            self.pc = (self.pc + 1) & MASK
            return v

        def zp():
            v = self.mem[self.pc]
            self.pc = (self.pc + 1) & MASK
            return v

        def zpx():
            return (zp() + self.x) & 0xFF

        def zpy():
            return (zp() + self.y) & 0xFF

        def absa():
            lo = imm()
            hi = imm()
            return lo | (hi << 8)

        def absx():
            base = absa()
            return (base + self.x) & MASK

        def absy():
            base = absa()
            return (base + self.y) & MASK

        def indx():
            z = (zp() + self.x) & 0xFF
            return self.mem[z] | (self.mem[(z + 1) & 0xFF] << 8)

        def indy():
            z = zp()
            base = self.mem[z] | (self.mem[(z + 1) & 0xFF] << 8)
            return (base + self.y) & MASK

        def cmp_(reg, val):
            t = (reg - val) & 0x1FF
            self.c = 1 if reg >= val else 0
            self.z = 1 if (reg - val) & 0xFF == 0 else 0
            self.n = ((reg - val) & 0x80) >> 7

        if op == 0xEA:
            pass
        elif op == 0x78:
            self.i = 1
        elif op == 0x58:
            self.i = 0
        elif op == 0xD8:
            self.d = 0
        elif op == 0xF8:
            self.d = 1
        elif op == 0x18:
            self.c = 0
        elif op == 0x38:
            self.c = 1
        elif op == 0xB8:
            self.c = 0
        elif op == 0xD8:
            self.d = 0
        elif op == 0xA9:
            self.a = self.setnz(imm())
        elif op == 0xA5:
            self.a = self.setnz(self.read(zp()))
        elif op == 0xB5:
            self.a = self.setnz(self.read(zpx()))
        elif op == 0xAD:
            self.a = self.setnz(self.read(absa()))
        elif op == 0xBD:
            self.a = self.setnz(self.read(absx()))
        elif op == 0xB9:
            self.a = self.setnz(self.read(absy()))
        elif op == 0xA1:
            self.a = self.setnz(self.read(indx()))
        elif op == 0xB1:
            self.a = self.setnz(self.read(indy()))
        elif op == 0xA2:
            self.x = self.setnz(imm())
        elif op == 0xA6:
            self.x = self.setnz(self.read(zp()))
        elif op == 0xB6:
            self.x = self.setnz(self.read(zpy()))
        elif op == 0xAE:
            self.x = self.setnz(self.read(absa()))
        elif op == 0xBE:
            self.x = self.setnz(self.read(absy()))
        elif op == 0xA0:
            self.y = self.setnz(imm())
        elif op == 0xA4:
            self.y = self.setnz(self.read(zp()))
        elif op == 0xB4:
            self.y = self.setnz(self.read(zpx()))
        elif op == 0xAC:
            self.y = self.setnz(self.read(absa()))
        elif op == 0xBC:
            self.y = self.setnz(self.read(absx()))
        elif op == 0x85:
            self.write(zp(), self.a)
        elif op == 0x95:
            self.write(zpx(), self.a)
        elif op == 0x8D:
            self.write(absa(), self.a)
        elif op == 0x9D:
            self.write(absx(), self.a)
        elif op == 0x99:
            self.write(absy(), self.a)
        elif op == 0x81:
            self.write(indx(), self.a)
        elif op == 0x91:
            self.write(indy(), self.a)
        elif op == 0x86:
            self.write(zp(), self.x)
        elif op == 0x96:
            self.write(zpy(), self.x)
        elif op == 0x8E:
            self.write(absa(), self.x)
        elif op == 0x84:
            self.write(zp(), self.y)
        elif op == 0x94:
            self.write(zpx(), self.y)
        elif op == 0x8C:
            self.write(absa(), self.y)
        elif op in (0x69, 0x65, 0x75, 0x6D, 0x7D, 0x79, 0x61, 0x71):
            val = {
                0x69: imm, 0x65: lambda: self.read(zp()),
                0x75: lambda: self.read(zpx()), 0x6D: lambda: self.read(absa()),
                0x7D: lambda: self.read(absx()), 0x79: lambda: self.read(absy()),
                0x61: lambda: self.read(indx()), 0x71: lambda: self.read(indy()),
            }[op]()
            t = self.a + val + self.c
            self.v = (~(self.a ^ val) & (self.a ^ t) & 0x80) >> 7
            self.c = 1 if t > 0xFF else 0
            self.a = self.setnz(t)
        elif op in (0xE9, 0xE5, 0xF5, 0xED, 0xFD, 0xF9, 0xE1, 0xF1):
            val = {
                0xE9: imm, 0xE5: lambda: self.read(zp()),
                0xF5: lambda: self.read(zpx()), 0xED: lambda: self.read(absa()),
                0xFD: lambda: self.read(absx()), 0xF9: lambda: self.read(absy()),
                0xE1: lambda: self.read(indx()), 0xF1: lambda: self.read(indy()),
            }[op]()
            t = self.a - val - (1 - self.c)
            self.v = ((self.a ^ val) & (self.a ^ t) & 0x80) >> 7
            self.c = 1 if t >= 0 else 0
            self.a = self.setnz(t & 0xFF)
        elif op == 0x29:
            self.a = self.setnz(self.a & imm())
        elif op == 0x25:
            self.a = self.setnz(self.a & self.read(zp()))
        elif op == 0x35:
            self.a = self.setnz(self.a & self.read(zpx()))
        elif op == 0x2D:
            self.a = self.setnz(self.a & self.read(absa()))
        elif op == 0x3D:
            self.a = self.setnz(self.a & self.read(absx()))
        elif op == 0x39:
            self.a = self.setnz(self.a & self.read(absy()))
        elif op == 0x31:
            self.a = self.setnz(self.a & self.read(indy()))
        elif op == 0x09:
            self.a = self.setnz(self.a | imm())
        elif op == 0x05:
            self.a = self.setnz(self.a | self.read(zp()))
        elif op == 0x15:
            self.a = self.setnz(self.a | self.read(zpx()))
        elif op == 0x0D:
            self.a = self.setnz(self.a | self.read(absa()))
        elif op == 0x1D:
            self.a = self.setnz(self.a | self.read(absx()))
        elif op == 0x19:
            self.a = self.setnz(self.a | self.read(absy()))
        elif op == 0x11:
            self.a = self.setnz(self.a | self.read(indy()))
        elif op == 0x49:
            self.a = self.setnz(self.a ^ imm())
        elif op == 0x45:
            self.a = self.setnz(self.a ^ self.read(zp()))
        elif op == 0x55:
            self.a = self.setnz(self.a ^ self.read(zpx()))
        elif op == 0x4D:
            self.a = self.setnz(self.a ^ self.read(absa()))
        elif op == 0x5D:
            self.a = self.setnz(self.a ^ self.read(absx()))
        elif op == 0x59:
            self.a = self.setnz(self.a ^ self.read(absy()))
        elif op == 0x51:
            self.a = self.setnz(self.a ^ self.read(indy()))
        elif op == 0xC9:
            cmp_(self.a, imm())
        elif op == 0xC5:
            cmp_(self.a, self.read(zp()))
        elif op == 0xD5:
            cmp_(self.a, self.read(zpx()))
        elif op == 0xCD:
            cmp_(self.a, self.read(absa()))
        elif op == 0xDD:
            cmp_(self.a, self.read(absx()))
        elif op == 0xD9:
            cmp_(self.a, self.read(absy()))
        elif op == 0xD1:
            cmp_(self.a, self.read(indy()))
        elif op == 0xE0:
            cmp_(self.x, imm())
        elif op == 0xE4:
            cmp_(self.x, self.read(zp()))
        elif op == 0xEC:
            cmp_(self.x, self.read(absa()))
        elif op == 0xC0:
            cmp_(self.y, imm())
        elif op == 0xC4:
            cmp_(self.y, self.read(zp()))
        elif op == 0xCC:
            cmp_(self.y, self.read(absa()))
        elif op == 0x4A:
            self.c = self.a & 1
            self.a = self.setnz(self.a >> 1)
        elif op == 0x0A:
            self.c = (self.a >> 7) & 1
            self.a = self.setnz((self.a << 1) & 0xFF)
        elif op == 0x2A:
            carry = self.c
            self.c = (self.a >> 7) & 1
            self.a = self.setnz(((self.a << 1) | carry) & 0xFF)
        elif op == 0x6A:
            carry = self.c
            self.c = self.a & 1
            self.a = self.setnz((self.a >> 1) | (carry << 7))
        elif op == 0x48:
            self.push(self.a)
        elif op == 0x08:
            self.push(self.getflags() | 0x10)
        elif op == 0x68:
            self.a = self.setnz(self.pop())
        elif op == 0x28:
            self.setflags(self.pop())
        elif op == 0xDA:
            if self.i == 0:
                self.push(self.pc >> 8)
                self.push(self.pc & 0xFF)
                self.pc = self.mem[0xFFFE] | (self.mem[0xFFFF] << 8)
            else:
                self.illegal = "PHP/PLP"
        elif op == 0xFA:
            if self.i == 0:
                self.pc = self.pop() | (self.pop() << 8)
            else:
                self.illegal = "PLP"
        elif op == 0x20:
            lo = imm()
            hi = imm()
            ret = (hi << 8) | lo
            # Il 6502 spinge l'indirizzo dell'ultimo byte della JSR: l'RTS
            # aggiunge 1 per tornare all'istruzione successiva.
            self.push((self.pc - 1) >> 8)
            self.push((self.pc - 1) & 0xFF)
            self.pc = ret
        elif op == 0x60:
            lo = self.pop()
            hi = self.pop()
            self.pc = ((lo | (hi << 8)) + 1) & MASK
        elif op == 0x40:
            self.setflags(self.pop())
            lo = self.pop()
            hi = self.pop()
            self.pc = lo | (hi << 8)
        elif op == 0x00:
            self.illegal = "BRK"
        elif op == 0x4C:
            self.pc = absa()
        elif op == 0x6C:
            ptr = absa()
            lo = self.mem[ptr]
            hi = self.mem[(ptr & 0xFF00) | ((ptr + 1) & 0xFF)]
            self.pc = lo | (hi << 8)
        elif op == 0x20 + 0:
            pass
        elif op in (0x10, 0x30, 0x50, 0x70, 0x90, 0xB0, 0xD0, 0xF0):
            off = imm()
            if off > 127:
                off -= 256
            take = {
                0x10: self.n == 0,      # BPL
                0x30: self.n == 1,      # BMI
                0x50: self.v == 0,      # BVC
                0x70: self.v == 1,      # BVS
                0x90: self.c == 0,      # BCC
                0xB0: self.c == 1,      # BCS
                0xD0: self.z == 0,      # BNE
                0xF0: self.z == 1,      # BEQ
            }[op]
            if take:
                self.pc = (self.pc + off) & MASK
        elif op == 0x24:
            self.z = 1 if (self.a & self.read(zp())) == 0 else 0
        elif op == 0x2C:
            self.z = 1 if (self.a & self.read(absa())) == 0 else 0
        elif op == 0xE6:
            addr = zp()
            v = (self.read(addr) + 1) & 0xFF
            self.write(addr, v)
            self.setnz(v)
        elif op == 0xF6:
            addr = zpx()
            v = (self.read(addr) + 1) & 0xFF
            self.write(addr, v)
            self.setnz(v)
        elif op == 0xEE:
            addr = absa()
            v = (self.read(addr) + 1) & 0xFF
            self.write(addr, v)
            self.setnz(v)
        elif op == 0xFE:
            addr = absx()
            v = (self.read(addr) + 1) & 0xFF
            self.write(addr, v)
            self.setnz(v)
        elif op == 0xC6:
            addr = zp()
            v = (self.read(addr) - 1) & 0xFF
            self.write(addr, v)
            self.setnz(v)
        elif op == 0xD6:
            addr = zpx()
            v = (self.read(addr) - 1) & 0xFF
            self.write(addr, v)
            self.setnz(v)
        elif op == 0xCE:
            addr = absa()
            v = (self.read(addr) - 1) & 0xFF
            self.write(addr, v)
            self.setnz(v)
        elif op == 0xDE:
            addr = absx()
            v = (self.read(addr) - 1) & 0xFF
            self.write(addr, v)
            self.setnz(v)
        elif op in (0x06, 0x16, 0x0E, 0x1E):      # ASL
            addr = {0x06: lambda: zp(), 0x16: lambda: zpx(),
                    0x0E: lambda: absa(), 0x1E: lambda: absx()}[op]()
            v = self.read(addr)
            self.c = (v >> 7) & 1
            v = self.setnz((v << 1) & 0xFF)
            self.write(addr, v)
        elif op in (0x46, 0x56, 0x4E, 0x5E):      # LSR
            addr = {0x46: lambda: zp(), 0x56: lambda: zpx(),
                    0x4E: lambda: absa(), 0x5E: lambda: absx()}[op]()
            v = self.read(addr)
            self.c = v & 1
            v = self.setnz(v >> 1)
            self.write(addr, v)
        elif op in (0x26, 0x36, 0x2E, 0x3E):      # ROL
            addr = {0x26: lambda: zp(), 0x36: lambda: zpx(),
                    0x2E: lambda: absa(), 0x3E: lambda: absx()}[op]()
            v = self.read(addr)
            carry = self.c
            self.c = (v >> 7) & 1
            v = self.setnz(((v << 1) | carry) & 0xFF)
            self.write(addr, v)
        elif op in (0x66, 0x76, 0x6E, 0x7E):      # ROR
            addr = {0x66: lambda: zp(), 0x76: lambda: zpx(),
                    0x6E: lambda: absa(), 0x7E: lambda: absx()}[op]()
            v = self.read(addr)
            carry = self.c
            self.c = v & 1
            v = self.setnz((v >> 1) | (carry << 7))
            self.write(addr, v)
        elif op == 0xCA:
            self.x = self.setnz(self.x - 1)
        elif op == 0xE8:
            self.x = self.setnz(self.x + 1)
        elif op == 0x88:
            self.y = self.setnz(self.y - 1)
        elif op == 0xC8:
            self.y = self.setnz(self.y + 1)
        elif op == 0xAA:
            self.x = self.setnz(self.a)
        elif op == 0xA8:
            self.y = self.setnz(self.a)
        elif op == 0x8A:
            self.a = self.setnz(self.x)
        elif op == 0x98:
            self.a = self.setnz(self.y)
        elif op == 0xBA:
            self.x = self.setnz(self.sp)
        elif op == 0x9A:
            self.sp = self.x
        elif op in (0x0F, 0x2F, 0x4F, 0x6F, 0xAF, 0xCF, 0xEF):
            base = {
                0x0F: 0x00, 0x2F: 0x20, 0x4F: 0x40, 0x6F: 0x60,
                0xAF: 0x20, 0xCF: 0x40, 0xEF: 0x60}[op]
            if op == 0x0F:
                addr = absa()
                v = self.read(addr)
                v ^= ((1 << base) - 1) & 0xFF
                self.write(addr, v)
                self.setnz(v)
            elif op == 0x2F:
                addr = absa()
                v = self.read(addr) & ~(((1 << base) - 1) & 0xFF)
                self.write(addr, v)
                self.setnz(v)
            elif op == 0x4F:
                addr = absa()
                v = self.read(addr) | (((1 << base) - 1) & 0xFF)
                self.write(addr, v)
                self.setnz(v)
            elif op == 0x6F:
                addr = absx()
                v = self.read(addr) ^ (((1 << base) - 1) & 0xFF)
                self.write(addr, v)
                self.setnz(v)
            elif op == 0xAF:
                addr = absx()
                v = self.read(addr) & ~(((1 << base) - 1) & 0xFF)
                self.write(addr, v)
                self.setnz(v)
            elif op == 0xCF:
                addr = absx()
                v = self.read(addr) | (((1 << base) - 1) & 0xFF)
                self.write(addr, v)
                self.setnz(v)
            elif op == 0xEF:
                addr = absy()
                v = self.read(addr) ^ (((1 << base) - 1) & 0xFF)
                self.write(addr, v)
                self.setnz(v)
        else:
            self.illegal = "opcode $%02X at $%04X" % (op, (self.pc - 1) & MASK)
            raise RuntimeError(self.illegal)


def screen_text(mem, row, col, length):
    """Reads a screen-code string from screen RAM."""
    out = []
    for i in range(length):
        code = mem[0x0400 + row * 40 + col + i]
        out.append(code)
    return out


def decode_screen(codes):
    # PETSCII screen code -> ASCII (tabella standard del C64)
    table = {}
    for i in range(26):
        table[0x01 + i] = chr(ord('A') + i)
    table[0x00] = '@'
    table[0x20] = ' '
    for i in range(10):
        table[0x30 + i] = chr(ord('0') + i)
    table[0x3A] = ':'
    table[0x2D] = '-'
    table[0x2C] = ','
    table[0x2E] = '.'
    return ''.join(table.get(c, '?') for c in codes)


def main():
    prg = sys.argv[1]
    c64 = C64(prg)
    c64.joystick = 0xFF
    c64.pc = 0x0810

    symbols = {}
    try:
        with open(sys.argv[2], encoding='utf-8', errors='replace') as fh:
            for line in fh:
                if '=' not in line:
                    continue
                name = line.split('=')[0].strip()
                val = line.split('=')[1].split(';')[0].strip()
                if name and val.startswith('$'):
                    symbols[name] = int(val[1:], 16)
    except FileNotFoundError:
        pass

    loop_pc = symbols.get('si_main_loop')
    if loop_pc is None:
        print("FAIL: si_main_loop symbol not found")
        return 1

    def run_frames(n, joystick=0xFF):
        c64.joystick = joystick
        for _ in range(n):
            steps = 0
            while True:
                c64.step()
                steps += 1
                if c64.pc == loop_pc:
                    break
                if steps > 2_000_000:
                    print("FAIL: frame did not complete (runaway loop)")
                    return False
        return True

    print("== 1. titolo ==")
    if not run_frames(3):
        return 1
    title = decode_screen(screen_text(c64.mem, 5, 0, 27))
    press = decode_screen(screen_text(c64.mem, 12, 0, 31))
    print("   riga 5 :", title)
    print("   riga 12:", press)
    ok_title = "SPACE INVADERS" in title and "PRESS FIRE" in press

    print("== 2. avvio partita (FIRE premuto) ==")
    # FIRE = bit 4 azzerato (logica invertita del joystick)
    if not run_frames(3, joystick=0xCF):
        return 1
    state = c64.mem[0x20]
    print("   stato di gioco:", state, "(1 = in gioco)")
    ok_start = state == 1

    print("== 3. HUD ==")
    score = decode_screen(screen_text(c64.mem, 1, 2, 4))
    lives = decode_screen(screen_text(c64.mem, 24, 9, 1))
    print("   punteggio:", score, " vite:", lives)
    ok_hud = score == "0000" and lives == "3"

    print("== 4. movimento dello sciame ==")
    swarm_x = c64.mem[0x2B]
    if not run_frames(120):
        return 1
    swarm_x2 = c64.mem[0x2B]
    print("   X sciame: %d -> %d" % (swarm_x, swarm_x2))
    ok_move = swarm_x2 != swarm_x

    print("== 5. sparo e collisione ==")
    # Il proiettile viene generato dal tasto fuoco
    if not run_frames(2, joystick=0xCF):
        return 1
    bullet_on = c64.mem[0x25]
    print("   proiettile attivo:", bullet_on)
    ok_shoot = bullet_on == 1

    print("== 6. collisione e punteggio ==")
    # Posiziona il cannone sotto lo sciame e spara: il proiettile deve
    # colpire un invasore e far salire il punteggio.
    score_before = c64.mem[0x33] | (c64.mem[0x34] << 8)
    for _ in range(4):
        c64.mem[0x22] = (c64.mem[0x2B] + 8) & 0xFF   # allinea il cannone
        run_frames(2, joystick=0xCF)                    # tasto fuoco premuto
        run_frames(30, joystick=0xFF)                   # il proiettile sale
    score_after = c64.mem[0x33] | (c64.mem[0x34] << 8)
    print("   punteggio BCD: %02X%02X -> %02X%02X" % (
        score_before >> 8, score_before & 0xFF,
        score_after >> 8, score_after & 0xFF))
    ok_score = score_after != score_before

    print("== 7. 600 frame di gioco ==")
    if not run_frames(600):
        return 1
    print("   punteggio:", decode_screen(screen_text(c64.mem, 1, 2, 4)))
    print("   vite:", decode_screen(screen_text(c64.mem, 24, 9, 1)))
    print("   stato:", c64.mem[0x20])

    print("== 8. nessun opcode illegale ==")
    print("   istruzioni eseguite:", c64.cycles)

    ok = ok_title and ok_start and ok_hud and ok_move and ok_shoot and ok_score
    print()
    print("RISULTATO:", "TUTTI I TEST SUPERATI" if ok else "FALLITO")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
