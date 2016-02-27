/* Copyright (C) 1996,1997,1998, 1997, UPM-CLIP */

/* Debugging flags */

#if !defined(_DEBUG_H_)
#define _DEBUG_H_
#endif

#if defined(DEBUG)
extern int debug_c;                                             /* Shared */
extern BOOL debug_gc, debug_threads, debug_mem, debug_conc;
#endif

extern BOOL stop_on_pred_calls, predtrace, profile, prof_include_time;