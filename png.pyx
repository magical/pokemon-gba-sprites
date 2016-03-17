
cdef extern from "stdlib.h":
    void *malloc(int)
    void free(void *)

cdef extern from "stdio.h":
    ctypedef struct FILE
    FILE *fopen(char*, char*)
    void fclose(FILE *)

cdef extern from "png.h":
    ctypedef struct png_struct
    ctypedef struct png_info
    ctypedef char png_byte

    ctypedef struct png_color

    ctypedef struct png_color_8:
        int red
        int green
        int blue
        int gray
        int alpha

    ctypedef struct png_color_16:
        char index
        int red
        int green
        int blue
        int gray

    ctypedef struct jmp_buf
    jmp_buf png_jmpbuf(png_struct*)
    int setjmp(jmp_buf env)

    void png_destroy_write_struct(png_struct**, png_info**)
    png_struct* png_create_write_struct(char*, void*, void*, void*)
    png_info* png_create_info_struct(png_struct*)
    void png_init_io(png_struct*, FILE*)
    void png_set_compression_level(png_struct*, int)
    void png_set_IHDR(png_struct*, png_info*, int width, int height,
                      int bit_depth, int color,
                      int interlace, int compression, int filter)
    void png_set_PLTE(png_struct*, png_info*, png_color *palette, int count)
    void png_set_tRNS(png_struct*, png_info*, char *alpha, int size, png_color_16*)
    void png_set_sBIT(png_struct*, png_info*, png_color_8*)
    void png_set_rows(png_struct*, png_info*, png_byte**)
    void png_write_png(png_struct*, png_info*, int transforms, void*)

    char *PNG_LIBPNG_VER_STRING
    int PNG_COLOR_TYPE_PALETTE
    int PNG_INTERLACE_NONE
    int PNG_COMPRESSION_TYPE_DEFAULT
    int PNG_FILTER_TYPE_DEFAULT
    int PNG_TRANSFORM_PACKING

cdef extern from "zlib.h":
    int Z_BEST_SPEED

class PNGError(Exception):
    """Some error in libpng"""

cdef bytes color16to256(bytes color):
    return bytes([
        int(round(color[0] * 255.0 / 31.0)),
        int(round(color[1] * 255.0 / 31.0)),
        int(round(color[2] * 255.0 / 31.0)),
    ])

cpdef write_png(bytes pixels, palette, unicode filename):
    cdef int width = 64
    cdef int height = len(pixels) // width

    cdef char *cpixels = pixels
    cdef png_byte **rows = <png_byte**>malloc(height * sizeof(png_byte*))
    for i in range(height):
        rows[i] = &cpixels[i * width]

    palette_count = len(palette)
    palette = b''.join([color16to256(x) for x in palette])
    cdef char *cpalette = palette

    cdef png_byte trans[1]
    trans[0] = 0

    cdef png_color_8 sig_bit
    sig_bit.red = 5
    sig_bit.green = 5
    sig_bit.blue = 5
    sig_bit.alpha = 1

    cdef bytes bfilename = filename.encode()
    cdef FILE *fp = fopen(bfilename, "wb")
    if fp == NULL:
        raise IOError("failed to open \"%s\" for writing" % filename)

    cdef png_struct* png = png_create_write_struct(
        PNG_LIBPNG_VER_STRING, NULL, NULL, NULL)
    if png == NULL:
        free(rows)
        fclose(fp)
        raise MemoryError

    cdef png_info* info = png_create_info_struct(png)
    if info == NULL:
        png_destroy_write_struct(&png, NULL)
        free(rows)
        fclose(fp)
        raise MemoryError

    if setjmp(png_jmpbuf(png)):
        png_destroy_write_struct(&png, &info)
        free(rows)
        fclose(fp)
        raise PNGError

    png_init_io(png, fp)

    png_set_compression_level(png, Z_BEST_SPEED);

    png_set_IHDR(png, info, width, height, 4,
        PNG_COLOR_TYPE_PALETTE,
        PNG_INTERLACE_NONE,
        PNG_COMPRESSION_TYPE_DEFAULT,
        PNG_FILTER_TYPE_DEFAULT)

    png_set_PLTE(png, info, <png_color *>cpalette, palette_count)
    png_set_tRNS(png, info, trans, 1, NULL)
    png_set_sBIT(png, info, &sig_bit)

    png_set_rows(png, info, rows)

    png_write_png(png, info, PNG_TRANSFORM_PACKING, NULL)

    png_destroy_write_struct(&png, &info)

    free(rows)
    fclose(fp)
