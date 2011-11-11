#!/usr/bin/env python3

import sys
import os
import errno
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

def mkdir(path):
    """Make a directory if it does not already exist."""
    try:
        os.mkdir(path)
    except (IOError, OSError) as e:
        if e.errno == errno.EEXIST:
            pass
        else:
            raise

read_sprite = memoize(read_sprite)
read_palette = memoize(read_palette)

def main(args):
    romfile = args[0]
    outdir = args[1]
    mkdir(outdir)
    mkdir(os.path.join(outdir, "shiny"))
    mkdir(os.path.join(outdir, "back"))
    mkdir(os.path.join(outdir, "back", "shiny"))

    with gzopen(romfile) as f:
        info = get_rom_info(f)

        sprite_count = info['MonsterPicCount']

        front_pointers = read_pointers(f, info['MonsterPics'], sprite_count)
        back_pointers = read_pointers(f, info['MonsterBackPics'], sprite_count)
        palette_pointers = read_pointers(f, info['MonsterPals'], sprite_count)
        shiny_pointers = read_pointers(f, info['MonsterShinyPals'], sprite_count)

        for i in range(0, sprite_count):
            outname = "%s.png" % i

            pixels = read_sprite(f, front_pointers[i])
            if back_pointers[i] < palette_pointers[i]:
                back_pixels = read_sprite(f, back_pointers[i])
                palette = read_palette(f, palette_pointers[i])
            else:
                palette = read_palette(f, palette_pointers[i])
                back_pixels = read_sprite(f, back_pointers[i])
            shiny_palette = read_palette(f, shiny_pointers[i])

            # XXX Castform and Deoxys have multiple forms. The sprites (and
            # palettes, in Castform's case) are all lumped together. They
            # should be split into separate images.
            write_png(pixels, palette, os.path.join(outdir, outname))
            write_png(pixels, shiny_palette, os.path.join(outdir, "shiny", outname))

            write_png(back_pixels, palette, os.path.join(outdir, "back", outname))
            write_png(back_pixels, shiny_palette, os.path.join(outdir, "back", "shiny", outname))

    return 0

if __name__ == '__main__':
    import sys
    sys.exit(main(sys.argv[1:]))
