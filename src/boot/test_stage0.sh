#!/bin/bash

nasm -f bin -o stage0.bin stage0.asm
dd if=/dev/zero of=disk.img bs=1024 count=1440
dd if=stage0.bin of=disk.img conv=notrunc
qemu-system-i386 -fda disk.img -boot a

