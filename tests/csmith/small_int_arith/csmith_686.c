// Options:   --no-arrays --no-pointers --no-structs --no-unions --argc --no-bitfields --checksum --comma-operators --compound-assignment --concise --consts --divs --embedded-assigns --pre-incr-operator --pre-decr-operator --post-incr-operator --post-decr-operator --unary-plus-operator --jumps --longlong --int8 --uint8 --no-float --main --math64 --muls --safe-math --no-packed-struct --no-paranoid --no-volatiles --no-volatile-pointers --const-pointers --no-builtins --max-array-dim 1 --max-array-len-per-dim 4 --max-block-depth 1 --max-block-size 4 --max-expr-complexity 1 --max-funcs 1 --max-pointer-depth 2 --max-struct-fields 2 --max-union-fields 2 -o csmith_686.c
#include "csmith.h"


static long __undefined;



static const uint16_t g_2 = 0x0890L;
static int16_t g_7 = 0x58A0L;



static int32_t  func_1(void);




static int32_t  func_1(void)
{ 
    int8_t l_5 = (-5L);
    if (g_2)
    { 
        int16_t l_3 = 0x19C5L;
        int32_t l_4 = 0xDDD3F467L;
        l_4 = l_3;
        l_5 = g_2;
    }
    else
    { 
        uint32_t l_6 = 0x800FA72CL;
        g_7 &= l_6;
    }
    return g_2;
}





int main (int argc, char* argv[])
{
    int print_hash_value = 0;
    if (argc == 2 && strcmp(argv[1], "1") == 0) print_hash_value = 1;
    platform_main_begin();
    crc32_gentab();
    func_1();
    transparent_crc(g_2, "g_2", print_hash_value);
    transparent_crc(g_7, "g_7", print_hash_value);
    platform_main_end(crc32_context ^ 0xFFFFFFFFUL, print_hash_value);
    return 0;
}
