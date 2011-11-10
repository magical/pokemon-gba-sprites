
import sys
from sys import stdin, stdout, stderr, exit
from os import SEEK_SET, SEEK_CUR, SEEK_END
from errno import EPIPE
from struct import pack, unpack

__all__ = ('decompress', 'decompress_file', 'decompress_overlay', 'DecompressionError')

cdef extern from "Python.h":
    PyBytes_FromStringAndSize(char *v, int size)

cdef extern from "stdlib.h":
    void *malloc(int size)
    void free(void *m)

class DecompressionError(ValueError):
    pass

cdef int readbyte(f):
    return f.read(1)[0]

cdef int readshort(f):
    # big-endian
    a, b = f.read(2)
    return (a << 8) | b

cdef writebyte(char *data, int *pos, int size, int b):
    if size <= pos[0]:
        raise DecompressionError("decompressed data is larger than expected")
    data[pos[0]] = b
    pos[0] += 1

cdef copybyte(f, char *data, int *pos, int size):
    writebyte(data, pos, size, readbyte(f))

cdef decompress_raw_lzss10(f, int size):
    """Decompress LZSS-compressed bytes. Returns a bytearray."""
    cdef char *data = <char *>malloc(size)
    cdef int pos = 0

    cdef int flag, b, sh, count, disp
    cdef object ret

    while pos < size:
        b = readbyte(f)
        for i in range(8):
            flag = b & 0x80
            if flag == 0:
                copybyte(f, data, &pos, size)
            else:
                sh = readshort(f)
                count = (sh >> 0xc) + 3
                disp = (sh & 0xfff) + 1

                for _ in range(count):
                    if pos < disp:
                        raise DecompressionError("disp out of range", pos, disp)
                    writebyte(data, &pos, size, data[pos-disp])

            b <<= 1

            if size <= pos:
                break

    if pos != size:
        raise DecompressionError("decompressed size does not match the expected size")

    ret = PyBytes_FromStringAndSize(data, pos)
    free(data)

    return ret

#cdef decompress_raw_lzss11(f, decompressed_size):
#    """Decompress LZSS-compressed bytes. Returns a bytearray."""
#    data = bytearray()
#
#    def writebyte(b):
#        data.append(b)
#    def readbyte():
#        return f.read(1)[0]
#    def copybyte():
#        data.append(readbyte())
#
#    while len(data) < decompressed_size:
#        b = readbyte()
#        if b == 0:
#            # dumb optimization
#            for _ in range(8):
#                copybyte()
#            continue
#        flags = bits(b)
#        for flag in flags:
#            if flag == 0:
#                copybyte()
#            elif flag == 1:
#                b = readbyte()
#                indicator = b >> 4
#
#                if indicator == 0:
#                    # 8 bit count, 12 bit disp
#                    # indicator is 0, don't need to mask b
#                    count = (b << 4)
#                    b = readbyte()
#                    count += b >> 4
#                    count += 0x11
#                elif indicator == 1:
#                    # 16 bit count, 12 bit disp
#                    count = ((b & 0xf) << 12) + (readbyte() << 4)
#                    b = readbyte()
#                    count += b >> 4
#                    count += 0x111
#                else:
#                    # indicator is count (4 bits), 12 bit disp
#                    count = indicator
#                    count += 1
#
#                disp = ((b & 0xf) << 8) + readbyte()
#                disp += 1
#
#                try:
#                    for _ in range(count):
#                        writebyte(data[-disp])
#                except IndexError:
#                    raise Exception(count, disp, len(data))
#            else:
#                raise ValueError(flag)
#
#            if decompressed_size <= len(data):
#                break
#
#    if len(data) != decompressed_size:
#        raise DecompressionError("decompressed size does not match the expected size")
#
#    return data


def decompress(obj):
    """Decompress a file-like object.

    Returns a bytearray."""
    if hasattr(obj, 'read'):
        return decompress_file(obj)
    else:
        raise TypeError(obj)

cdef decompress_file(f):
    """Decompress an LZSS-compressed file. Returns a bytearray.
    """
    header = f.read(4)
    if header[0] == 0x10:
        decompress_raw = decompress_raw_lzss10
    #elif header[0] == 0x11:
    #    decompress_raw = decompress_raw_lzss11
    else:
        raise DecompressionError("not an lzss-compressed file")

    decompressed_size, = unpack("<L", header[1:] + b'\x00')

    return decompress_raw(f, decompressed_size)
