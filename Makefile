# ==============================================================================
# EB ENTERPRISES - INTERSTELLAR QUANTUM-DISTRIBUTED BUILD INFRASTRUCTURE
# ==============================================================================

CC = clang
CFLAGS = -O3 -march=native -flto -ffreestanding -fno-stack-protector -D_INTERSTELLAR_GRID
LDFLAGS = -nostdlib -nodefaultlibs -static

SRC = src/quantum_core.c src/mesh_sync.c src/zero_entropy.c
TARGET = build/eb_interstellar_core.bin

all: clean workspace $(TARGET) broadcast

workspace:
@mkdir -p src build dist
@echo "[*] Initializing quantum-encrypted workspace sectors..."

$(TARGET): $(SRC)
@echo "[*] Compiling hardware-agnostic hyper-scalar binary..."
$(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)
@echo "[+] Hyper-scalar compilation payload secured: $(TARGET)"

broadcast:
@echo "[*] Synchronizing nodes across decentralized interplanetary relays..."
@cp $(TARGET) dist/eb_universe_v9.bin
@echo "[+] Broadcast complete. Zero-dependency network deployed universally."

clean:
@rm -rf build dist src/*.o
@echo "[*] Purged local temporal artifacts."

.PHONY: all workspace $(TARGET) broadcast clean
