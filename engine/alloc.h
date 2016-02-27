/* Copyright (C) 1996,1997,1998, UPM-CLIP */




#define kB       1024
#define kCells   1024

#define MAXATOM  512

#define CONTPAD 128		/* min. amount of heap at proceed */
#define CALLPAD (2*MAXATOM + CONTPAD) /* min. amount of heap at call */

#define STACKPAD (2*ARITYLIMIT + 16) /* min. amount of stack at allocate */

				/* min. amount of trail/choice at try */
#define CHOICEPAD (2*ARITYLIMIT)


#define ATMTABSIZE  (4*kCells)	/* size of global atom table  */
#define QLOADSIZE   (2*kCells)	/* plenty at present */

#define GLOBALSTKSIZE  (16*kCells-1) /* Was 6*kCells-1 (DCG) */
#define LOCALSTKSIZE    (4*kCells-1)
#define CHOICESTKSIZE   (4*kCells-1)
#define TRAILSTKSIZE    (4*kCells-1)
#define XREGBANKSIZE    ARITYLIMIT

/* The ...STKSIZE constants may be overridden by env. variables.
   This macro first looks for one, and if not found, uses the default. */
#define GETENV(VALUE,WORK,STRING,VAR) \
  if ((WORK = getenv(STRING))) \
    VALUE = atoi(WORK); \
  else \
    VALUE = VAR;


#if defined(DEBUG)

#define INC_MEM_PROG(size) \
    if (debug_mem) printf("Program memory increased by %ld bytes\n", size);\
    mem_prog_count = mem_prog_count + (size) 

#define DEC_MEM_PROG(size) \
    if (debug_mem) printf("Program memory decreased by %ld bytes\n", size);\
    mem_prog_count = mem_prog_count - (size)

#else

#define INC_MEM_PROG(size) mem_prog_count = mem_prog_count + (size);

#define DEC_MEM_PROG(size) mem_prog_count = mem_prog_count - (size);

#endif
