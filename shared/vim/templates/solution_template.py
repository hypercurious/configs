#!/usr/bin/env python3
from sys import argv

try:
    input_text = argv[1] if len(argv)>1 else open('input.txt', 'r').read()
except Exception:
    input_text = argv[-1]


