
import lzss3

__all__ = ['read_sprite', 'read_palette', 'read_pointers', 'write_ppm']

cdef extern from "stdint.h":
    ctypedef int u32 "uint32_t"
    ctypedef int u16 "uint16_t"

cdef extern from "stdlib.h":
    void *malloc(int)
    void free(void *)

cdef extern from "Python.h":
    PyBytes_FromStringAndSize(char *v, int size)

def read_sprite(f, pointer):
    offset = pointer - 0x08000000
    f.seek(offset)
    data = lzss3.decompress(f)
    data = untile(data, 64)
    return data

def read_palette(f, pointer):
    offset = pointer - 0x08000000
    f.seek(offset)
    data = lzss3.decompress(f)
    return unpack_colors(data)

cdef bytes untile(bytes data, int width):
    cdef char *cout = <char *>malloc(len(data) * 2)
    if cout == NULL:
        raise MemoryError
    cdef char *cdata = data

    # tx, ty: upper right corner of the tile destination
    # x, y: position within the tile
    cdef int tx, ty, x, y, cx, cy, si, di, b

    ty = 0
    si = 0
    while si < len(data): # ty in range(0, ..., 8)
      for tx in range(0, width, 8):
        for y in range(0, 8):
          for x in range(0, 4):
            cy = ty + y
            cx = tx + x*2
            di = cy * width + cx

            b = cdata[si]
            cout[di] = b & 0xf
            cout[di+1] = (b >> 4) & 0xf

            si += 1
      ty += 8

    try:
        out = PyBytes_FromStringAndSize(cout, len(data) * 2)
    finally:
        free(cout)

    return out

cdef unpack_colors(bytes data):
    cdef char *cdata = data
    cdef u16 *palette = <u16 *>cdata
    cdef u16 x
    cdef int i

    colors = []
    for i in range(len(data) // sizeof(palette[0])):
        x = palette[i]
        rgb = bytes([
            x & 0x1f,
            (x >> 5) & 0x1f,
            (x >> 10) & 0x1f
        ])
        colors.append(rgb)
    return colors

def write_ppm(f, pixels, palette):
    f.write("P6\n64 64\n31\n".encode('ascii'))
    for x in pixels:
        f.write(palette[x])

cdef struct item:
    u32 pointer
    u32 x

def read_pointers(f, offset, count):
    # struct {void *pointer, int n} pointers[count]

    f.seek(offset)
    data = f.read(count * sizeof(item))

    cdef char *cdata = data
    cdef item *pointers = <item *>cdata

    return [pointers[i].pointer for i in range(count)]
