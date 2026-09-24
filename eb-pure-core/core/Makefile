CC = cc
CFLAGS = -O3 -static

all: kernel

kernel: kernel.c
	$(CC) $(CFLAGS) kernel.c -o eb_kernel

clean:
	rm -f eb_kernel
