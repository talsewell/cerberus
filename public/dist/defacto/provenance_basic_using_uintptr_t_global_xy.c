#include <stdio.h>
#include <string.h> 
#include <stdint.h>
#include <inttypes.h>
int  x=1, y = 2;
int main() {
  uintptr_t ux = (uintptr_t)&x;
  uintptr_t uy = (uintptr_t)&y;
  uintptr_t offset = 4;
  int *p = (int *)(ux + offset); // does this have undefined behaviour?
  int *q = &y;
  printf("Addresses: &x=%"PRIxPTR" p=%p &y=%"PRIxPTR\
         "\n",ux,(void*)p,uy);
  if (memcmp(&p, &q, sizeof(p)) == 0) {
    *p = 11; // does this have undefined behaviour?
    printf("x=%d  y=%d  *p=%d  *q=%d\n",x,y,*p,*q); 
  }
}