// Options:   --no-arrays --no-pointers --no-structs --no-unions --argc --no-bitfields --checksum --comma-operators --compound-assignment --concise --consts --divs --embedded-assigns --pre-incr-operator --pre-decr-operator --post-incr-operator --post-decr-operator --unary-plus-operator --jumps --longlong --int8 --uint8 --no-float --main --math64 --muls --safe-math --no-packed-struct --no-paranoid --no-volatiles --no-volatile-pointers --const-pointers --no-builtins --max-array-dim 1 --max-array-len-per-dim 4 --max-block-depth 1 --max-block-size 4 --max-expr-complexity 1 --max-funcs 1 --max-pointer-depth 2 --max-struct-fields 2 --max-union-fields 2 -o csmith_484.c
#include "csmith.h"


static long __undefined;



static int32_t g_2 = (-4L);



static uint32_t  func_1(void);




static uint32_t  func_1(void)
{ 
    int32_t l_5 = 0x1C1EC2DBL;
lbl_6:
    for (g_2 = 0; (g_2 != (-21)); g_2 = safe_sub_func_uint64_t_u_u(g_2, 4))
    { 
        return l_5;
    }
    g_2 = l_5;
    if (g_2)
        goto lbl_6;
    g_2 |= 0xD080C170L;
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
    platform_main_end(crc32_context ^ 0xFFFFFFFFUL, print_hash_value);
    return 0;
}
