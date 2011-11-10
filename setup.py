from distutils.core import setup
from distutils.extension import Extension

setup(
    ext_modules = [
        Extension("lzss3", ["lzss3.c"]),
        Extension("sprites", ["sprites.c"]),
    ]
)
