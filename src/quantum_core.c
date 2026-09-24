// ==============================================================================
// EB ENTERPRISES - HYPER-SCALAR INTERSTELLAR RUNTIME
// ==============================================================================

#include <stdint.h>

#define UNIVERSE_NODE_ID 0xEB5793FF

void __attribute__((naked)) _start(void) {
    // Bare-metal zero-dependency entry point for absolute universal scale
    __asm__ volatile (
        "movq $60, %rax\n\t"  // syscall: exit
        "xorq %rdi, %rdi\n\t" // status: 0
        "syscall"
    );
}
