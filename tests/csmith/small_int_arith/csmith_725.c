// Options:   --no-arrays --no-pointers --no-structs --no-unions --argc --no-bitfields --checksum --comma-operators --compound-assignment --concise --consts --divs --embedded-assigns --pre-incr-operator --pre-decr-operator --post-incr-operator --post-decr-operator --unary-plus-operator --jumps --longlong --int8 --uint8 --no-float --main --math64 --muls --safe-math --no-packed-struct --no-paranoid --no-volatiles --no-volatile-pointers --const-pointers --no-builtins --max-array-dim 1 --max-array-len-per-dim 4 --max-block-depth 1 --max-block-size 4 --max-expr-complexity 1 --max-funcs 1 --max-pointer-depth 2 --max-struct-fields 2 --max-union-fields 2 -o csmith_725.c
#include "csmith.h"


static long __undefined;



static uint8_t g_3 = 1UL;
static uint64_t g_7 = 0UL;
static uint32_t g_9 = 9UL;
static uint16_t g_10 = 8UL;



static int32_t  func_1(void);




static int32_t  func_1(void)
{ 
    int32_t l_2 = 0L;
    int32_t l_6 = 2L;
    g_3--;
    if (g_3)
    { 
        l_6 = g_3;
        return g_3;
    }
    else
    { 
        uint8_t l_8 = 0UL;
        g_7 |= (-1L);
        l_8 = l_6;
        g_9 = l_8;
        g_10++;
    }
    return g_10;
}





int main (int argc, char* argv[])
{
    int print_hash_value = 0;
    if (argc == 2 && strcmp(argv[1], "1") == 0) print_hash_value = 1;
    platform_main_begin();
    crc32_gentab();
    func_1();
    transparent_crc(g_3, "g_3", print_hash_value);
    transparent_crc(g_7, "g_7", print_hash_value);
    transparent_crc(g_9, "g_9", print_hash_value);
    transparent_crc(g_10, "g_10", print_hash_value);
    platform_main_end(crc32_context ^ 0xFFFFFFFFUL, print_hash_value);
    return 0;
}
