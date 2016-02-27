/* Copyright (C) 1996,1997,1998, UPM-CLIP */

#include "datadefs.h"
#include "support.h"

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#if !defined(crossWin32i86)
# include <sys/param.h>
# include <sys/errno.h>
#endif

#if !defined(MAXPATHLEN)
# if defined(PATH_MAX)
#  define MAXPATHLEN PATH_MAX
# else
#  define MAXPATHLEN 1024
# endif
#endif

#define ENG_NOFILES 20

/* declarations for global functions accessed here */

#include "alloc_defs.h"
#include "support_defs.h"
#include "initial_defs.h"

/* local declarations */

/* void ENG_perror(); */


/*   --------------------------------------------------------------  */
/*    BUILTIN C PREDICATES                                           */
/*   --------------------------------------------------------------  */


BOOL prolog_bootversion(Arg)
     Argdecl;
{
  print_string(Output_Stream_Ptr, emulator_version);
  print_string(Output_Stream_Ptr, "\n");
  return TRUE;
}



/*
BOOL prolog_sourcepath(Arg)
     Argdecl;
{
  char cbuf[MAXPATHLEN];

  DEREF(X(0),X(0));
  strcpy(cbuf,source_path);
  strcat(cbuf,"/");
  strcat(cbuf,GetString(X(0)));
  Unify_constant(MakeString(cbuf),X(1));
  return TRUE;
}
*/

/*   --------------------------------------------------------------  */
/*  USAGE:  open(+,+,-) only  */


BOOL prolog_open(Arg)
     Argdecl;
{
  struct stat statbuf;
  FILE *fileptr;
  char modespec[2];
  extern int errno;

  DEREF(X(0),X(0));
  DEREF(X(1),X(1));
  modespec[0] = GetString(X(1))[0];
  modespec[1] = 0;
  fileptr = (TagIsATM(X(0)) ? fopen(GetString(X(0)),modespec) :
	     TagIsSmall(X(0)) ? fdopen(GetSmall(X(0)),modespec) :
	     NULL);
  if (fileptr==NULL)
    goto bomb1;
  else if ( fstat(fileno(fileptr), &statbuf)
           || (statbuf.st_mode & S_IFMT) == S_IFDIR )
    goto bomb2;
  else
    return
    cunify(Arg, ptr_to_stream(Arg,new_stream(X(0),modespec,fileptr)),X(2));

 bomb2:
  fclose(fileptr);
  errno = EINVAL;
 bomb1:
  if (current_ferror_flag==atom_on)
    {
      if (errno == ENOENT || errno == EBADF )
        BUILTIN_ERROR(NO_SUCH_FILE,X(0),1)
      else
        BUILTIN_ERROR(NO_OPEN_PERMISSION,X(0),1)
    }
  else
    return FALSE;
}



/*   --------------------------------------------------------------  */

/* as Quintus closing a stream object referring to user_input,user_output */
/*   or user_error will succeed but cause no changes */

extern LOCK stream_list_l;

BOOL prolog_close(Arg)
     Argdecl;
{
  struct stream_node *stream;

  stream = stream_to_ptr(X(0), 'x');
  if (stream==NULL)
    BUILTIN_ERROR(TYPE_ERROR(STREAM_OR_ALIAS),X(0),1)

  else if (stream==Input_Stream_Ptr)
    Input_Stream_Ptr = stream_user_input;
  else if (stream==Output_Stream_Ptr)
    Output_Stream_Ptr = stream_user_output;
  else if (stream==Error_Stream_Ptr)
    Error_Stream_Ptr = stream_user_error;

  if ((stream!=stream_user_input) &&
      (stream!=stream_user_output) &&
      (stream!=stream_user_error))
    {
      if (stream->streammode != 's')        /* Not a socket -- has FILE * */
        fclose(stream->streamfile);
      else
        close(GetInteger(stream->label));            /* Needs a lock here */


 /* We are twiggling with a shared structure: lock the access to it */

      Wait_Acquire_lock(stream_list_l);

      stream->label = ERRORTAG;
      stream->backward->forward = stream->forward;
      stream->forward->backward = stream->backward;

      /* now ensure that no choicepoints point at the stream */
      {
	REGISTER struct node *B;
	TAGGED t1, t2;

	t1 = PointerToTerm(stream);
	t2 = PointerToTerm(stream->forward);
	
	for (B = w->node;
	     ChoiceYounger(B,Choice_Start);
	     B = ChoiceCharOffset(B,-B->next_alt->node_offset))
	  if (B->next_alt==address_nd_current_stream && B->term[3]==t1)
	    B->term[3] = t2;
      }

      checkdealloc((TAGGED *)stream,sizeof(struct stream_node));
      Release_lock(stream_list_l);
    }
  return TRUE;
}

/* '$unix_popen'(+Command, +Mode, -Stream) */
BOOL prolog_unix_popen(Arg)
     Argdecl;
{
  FILE *f;
  char *streammode;

  DEREF(X(0),X(0));
  DEREF(X(1),X(1));

  streammode = (X(1) == atom_read ? "r" : "w");

  if (!(f = popen(GetString(X(0)),streammode)))
	return FALSE;

  return cunify(Arg,ptr_to_stream(Arg,
                                  new_stream((TAGGED)0, streammode, f)), X(2));

}


/*   --------------------------------------------------------------  */

void ENG_perror(s)
     char *s;
{

#if defined(Win32)
#  define sys_errlist _sys_errlist
#endif

#if !defined(LINUX) && !defined(Win32) && !defined(DARWIN)
  extern char *sys_errlist[];
  extern int errno;
#endif

#if !defined(crossWin32i86)
  ENG_PRINTF2(stream_user_error, "%s: %s\n", s, sys_errlist[errno]);
#endif
}


/*   --------------------------------------------------------------  */


BOOL prolog_current_input(Arg)
     Argdecl;
{
  return cunify(Arg,ptr_to_stream(Arg,Input_Stream_Ptr),X(0));
}


BOOL prolog_set_input(Arg)
     Argdecl;
{
  int errcode;
  struct stream_node *stream;

  DEREF(X(0),X(0));
  stream = stream_to_ptr_check(X(0), 'r', &errcode);
  if (stream==NULL)
    BUILTIN_ERROR(errcode,X(0),1);

  Input_Stream_Ptr = stream;
  return TRUE;
}

/*   --------------------------------------------------------------  */


BOOL prolog_current_output(Arg)
     Argdecl;
{
  return cunify(Arg,ptr_to_stream(Arg,Output_Stream_Ptr),X(0));
}


BOOL prolog_set_output(Arg)
     Argdecl;
{
  int errcode;
  struct stream_node *stream;

  DEREF(X(0),X(0));
  stream = stream_to_ptr_check(X(0), 'w', &errcode);
  if (stream==NULL)
    BUILTIN_ERROR(errcode,X(0),1);

  Output_Stream_Ptr = stream;
  return TRUE;
}

/*   --------------------------------------------------------------  */

/* Replacing the stream aliases pointer */

/* replace_stream(StreamAlias, NewStream) */

BOOL prolog_replace_stream(Arg)
     Argdecl;
{
  TAGGED which_stream;
  TAGGED which_atom;
  struct stream_node *node;
  int errcode;

  DEREF(which_atom, X(0));
  DEREF(which_stream, X(1));

  if ((which_atom == atom_user_error) ||
      (which_atom == atom_user_output))
    node = stream_to_ptr_check(which_stream, 'w', &errcode);    
  else if (which_atom == atom_user_input) 
    node = stream_to_ptr_check(which_stream, 'r', &errcode);    
  else       /* Not exactly: should be "alias"*/
    BUILTIN_ERROR(TYPE_ERROR(STREAM_OR_ALIAS),X(0),1); 
  
  if (node == NULL) BUILTIN_ERROR(errcode,X(0),1);

  if (which_atom == atom_user_input) 
    stream_user_input = node;
  else if (which_atom == atom_user_output)
    stream_user_output = node;
  else if (which_atom == atom_user_error)
    stream_user_error = node;

  return TRUE;
}


/* get_stream(StreamAlias, CurrentStream) */

BOOL prolog_get_stream(Arg)
     Argdecl;
{
  TAGGED which_atom;
  struct stream_node *node;

  DEREF(which_atom, X(0));
  if (which_atom == atom_user_input) 
    node = stream_user_input;
  else if (which_atom == atom_user_output)
    node = stream_user_output;
  else if (which_atom == atom_user_error)
    node = stream_user_error;
  else BUILTIN_ERROR(TYPE_ERROR(STREAM_OR_ALIAS),X(0),1);
   
  return cunify(Arg, X(1), ptr_to_stream_noalias(Arg, node));

}

/*   --------------------------------------------------------------  */


BOOL prolog_current_error(Arg)
     Argdecl;
{
  return cunify(Arg,ptr_to_stream(Arg,Error_Stream_Ptr),X(0));
}


/*   --------------------------------------------------------------  */


/* prolog_stream_code(?Stream,?Stream_code)
 * stream Stream	A prolog Stream
 * integer Stream_code  A unique number associated with Stream
 *
 * Description: Stream can be used by prolog predicates to perform IO
 * Stream_code can be used by C functions to somehow perform IO.
 * There is a problem due to the ambiguity of 'user':
 *	stream_code(user,X)
 * will return the stream code associated with user_output.
 */

BOOL prolog_stream_code(Arg)
     Argdecl;
{
  int errcode;
  struct stream_node *s;

  DEREF(X(1), X(1));
  if (IsVar(X(1)))
    {
      s = stream_to_ptr_check(X(0), 'x', &errcode);
      if (!s)
        BUILTIN_ERROR(errcode,X(0),1);

      if (s->streammode != 's'){                            /* Not a socket */
        Unify_constant(MakeSmall(fileno(s->streamfile)),X(1));
      } else {                                                  /* DCG, MCL */
        Unify_constant(s->label,X(1)); /* Can't be this done above as well? */
      }
      return TRUE;
    }
  else if (X(1) >= TaggedZero && X(1) < MakeSmall(ENG_NOFILES))
    {
      for (s = root_stream_ptr->backward;
	   s != root_stream_ptr && s->label != X(1);
	   s = s->backward)
	;
      if (s != root_stream_ptr && s->label == X(1))
	return cunify(Arg,ptr_to_stream(Arg,s),X(0));
      else
	return FALSE;
    }
  else if (IsInteger(X(1)))
    return FALSE;
  else
    BUILTIN_ERROR(TYPE_ERROR(INTEGER),X(1),2);
}


BOOL character_count(Arg)
     Argdecl;
{
  int errcode;
  struct stream_node *stream;

  stream = stream_to_ptr_check(X(0), 'x', &errcode);
  if (!stream)
    BUILTIN_ERROR(errcode,X(0),1);

  if (stream->isatty)
    stream = root_stream_ptr;
  return cunify(Arg,MakeInteger(Arg,stream->char_count),X(1));
}


BOOL line_position(Arg)
     Argdecl;
{
  int errcode;
  struct stream_node *stream;

  stream = stream_to_ptr_check(X(0), 'x', &errcode);
  if (!stream)
    BUILTIN_ERROR(errcode,X(0),1);

  if (stream->isatty)
    stream = root_stream_ptr;
  return cunify(Arg,MakeInteger(Arg,stream->char_count-stream->last_nl_pos),X(1));
}


BOOL line_count(Arg)
     Argdecl;
{
  int errcode;
  struct stream_node *stream;

  stream = stream_to_ptr_check(X(0), 'x', &errcode);
  if (!stream)
    BUILTIN_ERROR(errcode,X(0),1);

  if (stream->isatty)
    stream = root_stream_ptr;
  return cunify(Arg,MakeInteger(Arg,stream->nl_count),X(1));
}
