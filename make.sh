set -e

redo-ifchange lzss3.c sprites.c
python3 setup.py build_ext --inplace
