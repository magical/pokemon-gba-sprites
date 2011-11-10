#!/usr/bin/env python3

import sys
import yaml
import gzip
import itertools
import array
from struct import pack, unpack

import lzss3

MAX_READ = 0x800

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

def read_sprite(f, pointer):
    offset = pointer - 0x08000000
    f.seek(offset)
    data = f.read(MAX_READ)
    data = lzss3.decompress(data)
    data = untile(data, 64)
    return data

def read_palette(f, pointer):
    offset = pointer - 0x08000000
    f.seek(offset)
    data = f.read(64)
    print(data, file=sys.stderr)
    data = lzss3.decompress(data)
    return unpack_colors(data)

def untile(data, width):
    tiles = (data[i:i+32] for i in range(0, len(data), 32))
    xy = ((x, y*8) for y in itertools.count() for x in range(0, width, 8))
    out = bytearray(len(data) * 2)
    for tile, (tx, ty) in zip(tiles, xy):
        for y in range(8):
            for x in range(4):
                i = (ty + y) * width + tx + x*2
                c = tile[y*4 + x]
                out[i] = c & 0xf  # low nybble
                out[i+1] = c >> 4 # high nybble
    return out

def unpack_colors(data):
    colors = []
    palette = array.array("H", data)
    for x in palette:
        rgb = (x & 0x1f,
               (x >> 5) & 0x1f,
               (x >> 10) & 0x1f)
        colors.append(rgb)
    return colors

def write_pgm(data):
    print("P5")
    print("64 64")
    print("15")
    sys.stdout.flush()
    sys.stdout.buffer.write(data)

def write_ppm(pixels, palette):
    print("P6")
    print("64 64")
    print("31")
    sys.stdout.flush()
    for x in pixels:
        try:
            color = palette[x]
        except IndexError:
            raise IndexError(x, palette)
        sys.stdout.buffer.write(bytes(color))

def read_pointers(f, offset, count):
    # struct {void *pointer, int n} pointers[count]
    f.seek(offset)
    data = f.read(count * 8)
    pointers = array.array("L", data)
    return [pointers[i] for i in range(0, len(pointers), 2)]

def main(args):
    n = 150
    with gzopen(args[0]) as f:
        info = get_rom_info(f)

        sprite_count = info['MonsterPicCount']

        sprite_pointers = read_pointers(f, info['MonsterPics'], sprite_count)
        palette_pointers = read_pointers(f, info['MonsterPals'], sprite_count)

        sprite_pointer = sprite_pointers[n]
        palette_pointer = palette_pointers[n]

        #print(hex(sprite_pointer), hex(palette_pointer), file=sys.stderr)
        pixels = read_sprite(f, sprite_pointer)
        palette = read_palette(f, palette_pointer)

    #write_pgm(pixels)
    write_ppm(pixels, palette)

    return 0

if __name__ == '__main__':
    import sys
    sys.exit(main(sys.argv[1:]))
