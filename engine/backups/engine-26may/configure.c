/* Copyright (C) 1996,1997,1998, 1999, 2000, 2001, 2002  UPM-CLIP */

/* First, if we are a BSD system, a line is printed:
 *      #define ENG_BSD 1
 * Then, we test for endian-ness and print a line
 *      #define BIGENDIAN <bool>
 * Then, we test whether the top 4 bits matter in memory accesses.
 * We also test what part of the address space that malloc() places
 * its objects in: if the top 4 bits matter, then a line
 *	#define MallocBase <base>
 * is printed, <base> being the top 4 bits for malloc() pointers.
 * CIAO assumes that those 4 bits are always the same.
 * (MCL) A line is the printed to store the minimum amount of memory which 
 * should be allocated to make the previous true:
 *      #define MIN_MEM_ALLOC <minimum>
 * Then, two lines
 *      #define ENG_FLT_SIGNIF <int>
 *      #define ENG_FLT_ROUND <float>
 * denoting respectively #significant digits in a float and a number to
 * be used for rounding purposes when floats are printed.
 * Then, a line is printed telling whether the system is being built with
 * native code support.
 */

#if defined(__STDC__)
#define VOLATILE volatile
#define PROTO(argl) argl
#else
#define VOLATILE
#define PROTO(ignore) ()
#endif


#include <stdio.h>
#include <unistd.h>
#include <setjmp.h>
#include <signal.h>
#include <string.h>
#include <math.h>

#include "compat.h"
#include "termdefs.h"                          /* because of TAGGED (MCL) */
#include "own_malloc_defs.h"

#if defined(__svr4__) || defined(DARWIN)              /* Solaris or Darwin */
# include <unistd.h>                                            /* sbrk () */
# if !defined(MALLOC_DEBUG)
#  include <stdlib.h>                                         /* malloc() */
# endif
#else                                                            /* SunOS */
# include <sys/types.h>
# if !defined(MALLOC_DEBUG)
#  include <malloc.h>
# endif
#endif

#if defined(MALLOC_DEBUG)
#include "dmalloc.h"
#endif

#define LOTS 16384
#define MIN_MEM_BLOCK_CHARS 16384

#define TAG_MASK 0xf0000000
#define ALIGN sizeof(TAGGED)                        /* Minimum block size */
#define ROUND_CHARS(Chars) Chars%ALIGN == 0 ? Chars/ALIGN : Chars/ALIGN + 1
#define MIN_MEM_BLOCK (unsigned int)(ROUND_CHARS(MIN_MEM_BLOCK_CHARS))

/* Computing the accuracy of floats - Changed so that display(5.347) = 5.347 */

static ENG_INT base = 2; 

/*
  safe_addition is intended to force A and B to be stored prior to doing the
  addition of A and B , for use in situations where optimizers might hold
  one of these in a register.

  There is a problem with gcc (3.1, at least): when using -O3, which turns
  inlining on, the number of digits in the (decimal) mantissa returned is
  20, due to the inlining of the safe_addition function, and the further
  optimization this brings about.  In order to avoid this in general, I have
  put the volatile keyword which tells the optimizer not to throw away
  references to the ret_val variable (since it may be read/written to by
  other threads :-), even if safe_addition is inlined.
*/

ENG_FLT safe_addition(volatile ENG_FLT *a, volatile ENG_FLT *b)
{
  volatile ENG_FLT ret_val;
  ret_val = *a + *b;
  return ret_val;
} 

void find_fp_bits(ENG_INT *t)
{
  volatile static ENG_FLT one = 1.0;

  /* 'base' was originally found out from the implementation of the FPU/FP
     routines; it is tipically 2 in mos FP implementations.  I suppose,
     then, that we can choose whatever base is appropriate for us and use
     the loop below to determine the number of significant digits in
     (pseudo-) base 10. */
    
  volatile ENG_FLT a, c, tmp1;
  volatile ENG_INT lt;

  lt = 0;
  a = c = one;
  while (c == one) {
    ++lt;
    a *= base;
    c = safe_addition(&a, &one);
    tmp1 = -a;
    c = safe_addition(&c, &tmp1);
  }
  *t = lt;
} 


int turn_point(TAGGED *base);

jmp_buf buf;

void handler(rc)
     int rc;
{
  longjmp(buf,rc);
}


void generate_defines(char *);

int main(argc, argv)
     int argc;
     char **argv;
{
  TAGGED mbase = 1;
  int lots;

  if (argc > 0) generate_defines(argv[1]);

  SIGNAL(SIGSEGV, handler);

#if !defined(crossWin32i86)
  SIGNAL(SIGBUS, handler);
#endif

  if
#if defined(multimax) || defined(AIX)
    (1)
#else
#if defined(hpux) || defined(m88k) || defined(_SEQUENT_) || defined(__svr4__)
    (0)
#else
    (!access("/usr/include/sys/time.h",0) &&
     !access("/usr/include/sys/resource.h",0))
#endif
#endif
      
      printf("#define ENG_BSD 1\n");
      printf("#define BIGENDIAN %d\n", ((unsigned short *)(&mbase))[1]);


  if ((lots = turn_point(&mbase))) {
    int tagged_lots = ROUND_CHARS(lots);  /* Use tagged words from now on */
    printf("#define MallocBase 0x%lx\n", mbase);
    printf("#define MIN_MEM_ALLOC %d\n", 
           tagged_lots > MIN_MEM_BLOCK ? tagged_lots : MIN_MEM_BLOCK);
  } else {
    printf("#define MallocBase 0x0\n");
    printf("#define MIN_MEM_ALLOC %d\n", MIN_MEM_BLOCK);
  }


  /*           
#if defined(sun)
  mbase = 0x0;
#else
  if ((lots = turn_point()) < LOTS) 
    lots = LOTS;
  ptr = malloc(lots*TAG_W_SIZE);
  mbase = (unsigned long)ptr & 0xf0000000;
  for (j=lots-1; j; --j)
    ((unsigned long *)ptr)[j] = 0x12345678;
  if (setjmp(buf))
#endif
    {
      printf("#define MallocBase 0x%lx\n", mbase);
      printf("#define MIN_MEM_ALLOC 0x%lx\n", lots);
      goto out;
    }
  for (i=0; i<16; i++)
    {
      ptr += 0x10000000;
      for (j=lots-1; j; --j)
	{

	  if (((unsigned long *)ptr)[j] != 0x12345678)
	    longjmp(buf,1);

	  ((unsigned long *)ptr)[j] = 0x12345678;
	}
    }
    */
  /* out:*/
  {
    ENG_INT bits;
    double f;    
    int i, j;

    find_fp_bits(&bits);

    i = (bits*0.301029995663981); /* #significant digits, bits*log_10(2) */

    f = 0.5e-9;			/* rounding factor if above 18 */
    for (j=18; j>i; j--)
      f*=10.0;

    printf("#define ENG_FLT_SIGNIF %d\n#define ENG_FLT_ROUND %.*g\n", i, i, f);
  }
  
  printf("/*kernel=def*/\n");

  exit(0);
}

 /* Some systems (namely, LINUX) allocate memory in different parts of the
    memory depending on how much we ask.  The result is that blocks can be
    scattered so that the "unmutable four top bits" assumption is broken
    (i.e., the mapped memory can't be fit into the pointer part of a tagged
    word) and MallocBase is not useful at all.  We try to find out
    dynamically if this ever happens, and at which point.  This will serve
    to calculate the minimum amount of memory to be requested at a time from
    the system, and a (hopefully) correct MallocBase.  
    
    If we, anyway, choose to build a system without snooping for a good
    MallocBase, just use the first pointer the system returns.

    (MCL) 
  */


int turn_point(base)
  TAGGED *base;
{

  int *this_pointer;
  int size = 1;

#if defined(USE_OWN_MALLOC)
  while(1)
    if ((this_pointer = (int *)malloc(size*ALIGN))) {
      if ((TAGGED)this_pointer & TAG_MASK){
        *base = (TAGGED)this_pointer & TAG_MASK;
        free(this_pointer);
        break;
      } else {
        size *= 2;
        free(this_pointer);
      }
    }
    else {
      size = 0;
      break;
    }
#else
  this_pointer = (int *)malloc(size*ALIGN);
  *base =  (TAGGED)this_pointer & TAG_MASK;
  free(this_pointer);
#endif

  return (size * ALIGN);
}

#if defined(SunOS4) || defined(Solaris) || defined(IRIX)
char *strsep(char **strchar, const char *delim);
#endif

void generate_defines(cflags)
     char *cflags;
{
  char *Dpointer;
  char *definition;
  char *macroname = NULL;
  char *definition_value;

  Dpointer = cflags;
  while(Dpointer && (Dpointer = strstr(Dpointer, "-D"))) {
    Dpointer += 2;
    if ((definition = strsep(&Dpointer, " "))) {
      definition_value = definition;
      macroname = strsep(&definition_value, "=");
    }
    if (definition_value)
      printf("#if !defined(%s)\n#define %s %s\n#endif\n\n", 
             macroname, macroname, definition_value);
    else
      printf("#if !defined(%s)\n#define %s\n#endif\n\n", 
             macroname, macroname);
  }
}


/* SunOs does not include strsep  */
#if defined(SunOS4) || defined(Solaris) || defined(IRIX)
/*      $NetBSD: strsep.c,v 1.8 1998/10/13 20:32:09 kleink Exp $        */
/*-
 * Copyright (c) 1990, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *      This product includes software developed by the University of
 *      California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * Get next token from string *stringp, where tokens are possibly-empty
 * strings separated by characters from delim.  
 *
 * Writes NULs into the string at *stringp to end tokens.
 * delim need not remain constant from call to call.
 * On return, *stringp points past the last NUL written (if there might
 * be further tokens), or is NULL (if there are definitely no more tokens).
 *
 * If *stringp is NULL, strsep returns NULL.
 */
char *strsep(stringp, delim)
     char **stringp;
     const char *delim;
{
  char *s;
  const char *spanp;
  int c, sc;
  char *tok;
  
  if ((s = *stringp) == NULL) return (NULL);
  for (tok = s;;) {
    c = *s++;
    spanp = delim;
    do {
      if ((sc = *spanp++) == c) {
        if (c == 0) s = NULL;
        else s[-1] = 0;
        *stringp = s;
        return (tok);
      }
    } while (sc != 0);
  }
}
#endif