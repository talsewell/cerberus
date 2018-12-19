#ifndef	_STDLIB_H_
#define	_STDLIB_H_

// TODO: restrict is empty
#define restrict

typedef __cerbty_size_t size_t;
typedef __cerbty_wchar_t wchar_t;

#define NULL __cerbvar_NULL

//TODO ldiv_t lldiv_t div_t


#define EXIT_FAILURE __cerbvar_EXIT_FAILURE
#define MB_CUR_MAX   __cerbvar_MB_CUR_MAX
#define EXIT_SUCCESS __cerbvar_EXIT_SUCCESS
#define RAND_MAX     __cerbvar_RAND_MAX


// double atof(const char *nptr); // TODO: floating
int atoi(const char *nptr);
long int atol(const char *nptr);
long long int atoll(const char *nptr);
// double strtod(const char * restrict nptr, char ** restrict endptr); // TODO: floating
// float strtof(const char * restrict nptr, char ** restrict endptr); // TODO: floating
// long double strtold(const char * restrict nptr, char ** restrict endptr); // TODO: floating
long int strtol(const char * restrict nptr, char ** restrict endptr, int base);
long long int strtoll(const char * restrict nptr, char ** restrict endptr, int base);
unsigned long int strtoul(const char * restrict nptr, char ** restrict endptr, int base);
unsigned long long int strtoull(const char * restrict nptr, char ** restrict endptr, int base);
int rand(void);
void srand(unsigned int seed);
void *aligned_alloc(size_t alignment, size_t size);
void *calloc(size_t nmemb, size_t size);
void free(void *ptr);
void *malloc(size_t size);
void *realloc(void *ptr, size_t size);
_Noreturn void abort(void);
int atexit(void (*func)(void));
int at_quick_exit(void (*func)(void));
_Noreturn void exit(int status);
_Noreturn void _Exit(int status);
char *getenv(const char *name);
_Noreturn void quick_exit(int status);
int system(const char *string);
void *bsearch(const void *key, const void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *));
void qsort(void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *));
int abs(int j);
long int labs(long int j);
long long int llabs(long long int j);
// div_t div(int numer, int denom);
// ldiv_t ldiv(long int numer, long int denom);
// lldiv_t lldiv(long long int numer, long long int denom);
int mblen(const char *s, size_t n);
int mbtowc(wchar_t * restrict pwc, const char * restrict s, size_t n);
int wctomb(char *s, wchar_t wchar);
size_t mbstowcs(wchar_t * restrict pwcs, const char * restrict s, size_t n);
size_t wcstombs(char * restrict s, const wchar_t * restrict pwcs, size_t n);

/*
_ _STDC_WANT_LIB_EXT1_ _ errno_t
rsize_t constraint_handler_t
     constraint_handler_t set_constraint_handler_s(
          constraint_handler_t handler);
     void abort_handler_s(
          const char * restrict msg,
          void * restrict ptr,
          errno_t error);
     void ignore_handler_s(
          const char * restrict msg,
          void * restrict ptr,
          errno_t error);
     errno_t getenv_s(size_t * restrict len,
               char * restrict value, rsize_t maxsize,
               const char * restrict name);
void *bsearch_s(const void *key, const void *base,
          rsize_t nmemb, rsize_t size,
          int (*compar)(const void *k, const void *y,
                         void *context),
          void *context);
     errno_t qsort_s(void *base, rsize_t nmemb, rsize_t size,
          int (*compar)(const void *x, const void *y,
                         void *context),
          void *context);
     errno_t wctomb_s(int * restrict status,
          char * restrict s,
          rsize_t smax,
          wchar_t wc);
     errno_t mbstowcs_s(size_t * restrict retval,
          wchar_t * restrict dst, rsize_t dstmax,
          const char * restrict src, rsize_t len);
     errno_t wcstombs_s(size_t * restrict retval,
          char * restrict dst, rsize_t dstmax,
          const wchar_t * restrict src, rsize_t len);
*/

#endif