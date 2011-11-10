#!/usr/bin/env python3

import sys
import os.path
import yaml
import gzip

from sprites import read_pointers, read_sprite, read_palette, write_ppm
from png import write_png

def gzopen(filename):
    f = open(filename, "rb")
    magic = f.read(2)
    if magic == b"\x1f\x8b":
        f.close()
        return gzip.open(filename, "rb")
    else:
        f.seek(0)
        return f

def get_rom_info(rom):
    with open("pokeroms.yml") as f:
        pokeroms = yaml.safe_load(f)

    rom.seek(0xAC)
    code = rom.read(4)
    try:
        code = code.decode('ascii')
    except UnicodeDecodeError:
        pass
    else:
        for info in pokeroms:
            if info.get('Code') == code:
                return info

    raise ValueError(code)

class memoize(object):
    def __init__(self, func):
        self.func = func
        self.memo = {}

    def __call__(self, file, pointer):
        if pointer in self.memo:
            return self.memo[pointer]
        else:
            x = self.func(file, pointer)
            self.memo[pointer] = x
            return x

read_sprite = memoize(read_sprite)
read_palette = memoize(read_palette)

def main(args):
    romfile = args[0]
    outdir = args[1]

    with gzopen(romfile) as f:
        info = get_rom_info(f)

        sprite_count = info['MonsterPicCount']

        sprite_pointers = read_pointers(f, info['MonsterPics'], sprite_count)
        palette_pointers = read_pointers(f, info['MonsterPals'], sprite_count)

        for i in range(0, sprite_count):
            outfile = os.path.join(outdir, "%s.png" % i)

            pixels = read_sprite(f, sprite_pointers[i])
            palette = read_palette(f, palette_pointers[i])

            write_png(pixels, palette, outfile)

    return 0

if __name__ == '__main__':
    import sys
    sys.exit(main(sys.argv[1:]))
