# CUDA architecture setting
# Adjust CUDA_ARCH based on your GPU:
# - RTX 3060, 3070, 3080, 3090: sm_86
# - RTX 2060, 2070, 2080: sm_75
# - GTX 1660, 1660 Ti, GTX 1650: sm_75
# - GTX 1050, 1060, 1070, 1080: sm_61
CUDA_ARCH = sm_75

# Compiler flags
NVCC = nvcc
NVCC_FLAGS = --compiler-options -Wall -arch=$(CUDA_ARCH) -O3
CC = gcc
CFLAGS = -O3 -Wall

# Targets
all: akira-bruteforce decrypt

akira-bruteforce: akira-bruteforce.cu chacha8.c
	$(NVCC) $(NVCC_FLAGS) -o $@ $^

decrypt: decrypt.c chacha8.c kcipher2.c
	$(CC) $(CFLAGS) -static -o $@ $^ -lnettle -lhogweed

clean:
	rm -f akira-bruteforce decrypt *.o
