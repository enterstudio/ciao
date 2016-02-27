/*#include "fix_path.h" */ /* To rename paths like /mounted/... */

#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <unistd.h>
#include <stdlib.h>
#include <dirent.h>
#include <pwd.h>

#include "datadefs.h"
#include "support.h"
#include "compat.h"

/* declarations for global functions accessed here */

#include "unix_utils_defs.h"
#include "streams_defs.h"
#include "stacks_defs.h"
#include "main_defs.h"

/* local declarations */

#if defined(Win32)
extern char library_directory[];
#else
extern char *library_directory;
#endif

#if defined(Solaris)
int gethostname(char *name, int namelen);
#endif

#if defined(SunOS4)
#include <string.h>
int system(char *string);
int gethostname(char *name, int namelen);
int readlink(char *path, char *buf, int bufsiz);
#endif

#ifndef MAXPATHLEN
# define MAXPATHLEN 1024
#endif

#if defined(Win32)
#define DriveSelector(path) \
        (isalpha(path[0]) && path[1]==':' && \
         (path[2]=='/' || path[2]=='\\' || path[2]==(char)0))
#endif   

char cwd[MAXPATHLEN+1];/* Should be private --- each thread may cd freely! */

BOOL expand_file_name(name, target)
     char *name;
     char *target;
{

#if !defined(__pwd_h) && !defined(_PWD_H) && !defined(__PWD_H__) && !defined(_PWD_H_)
  extern struct passwd *getpwnam PROTO((char *));
#endif

  REGISTER char *src, *dest;
  char src_buff[MAXPATHLEN+1];

  if (!name[0]) {
    target[0] = (char)0;
    return TRUE;
  }    

#if defined(Win32)
  src = name;
  dest = src_buff;
  while ((*dest = (*src == '\\') ? '/' : *src))
    ++src, ++dest;
#else
  strcpy(src_buff,name);
#endif

  /* contract // to / (non-initial in Win32) */
#if defined(Win32)
  src = dest = src_buff+1;
#else
  src = dest = src_buff;
#endif
  while ((*dest = *src)) {
    while (src[0] == '/' && src[1] == '/') ++src;
    ++dest ; ++src;
  }

  src = src_buff;
  dest = target;

  switch (*src) {
  case '$':        /* environment var */
    ++src;
  envvar:
    switch (*dest++ = *src++) {
    case 0:
    case '/':
      --src, --dest, dest[0] = (char)0;
      if (dest == target) {
        strcpy(target,library_directory);
        dest = target+strlen(target);
      } else {
        if (!(dest = getenv(target)))
          USAGE_FAULT("file name: undefined variable")
        target[0] = (char)0;
        strcpy(target,dest);
        dest = target+strlen(target);
      }
      goto st1;
    default:
      goto envvar;
    }
    break;
  case '~':        /* home directory */
    ++src;
  homedir:
    switch (*dest++ = *src++)
    {
    case 0:
    case '/':
      --src, --dest, dest[0] = (char)0;
      if (dest == target) {
        if (!(dest = getenv("HOME")))
	  dest = library_directory;
        strcpy(target,dest);
        dest = target+strlen(target);
      } else {
        struct passwd *pw;
        if (!(pw = getpwnam(target)))
          USAGE_FAULT("file name: no such user")
        strcpy(target,(char *)pw->pw_dir);
        dest = target+strlen(target);
      }
      goto st1;
    default:
      goto homedir;
    }
    break;
  case '/':        /* absolute path */
    src++;
    *dest++ = '/';
    break;
  default:
#if defined(Win32)
    if (DriveSelector(src)) {    /* c:/ */
      dest[0] = dest[1] = '/';
      dest[2] = src[0];
      dest += 3;
      src += 2;
      goto st1;
    } else
#endif
      {
        strcpy(target,cwd);
        dest = target+strlen(target);
        if (dest[-1] != '/')
          *dest++ = '/';
      }
  }


 st0: /* prev char is '/' */
  switch (*dest++ = *src++) {
  case 0:
    if (dest-2 > target)
      dest[-2] = 0;
    return TRUE;
  case '/':
    goto st0;
  case '.':
    if (src[0] == '/' || src[0] == (char)0) {
      if (dest-2 >= target)
        dest -= 2;
    } else if (src[0] == '.' && (src[1] == '/' || src[1] == (char)0))	{
      if (dest-3 >= target) {
        dest -= 3;
        while (--dest, dest[0] != '/')
          ;
        src++;
      }
    }
  }
  
 st1: /* inside file name component */
  switch (*dest++ = *src++) {
    case 0:
      return TRUE;
    case '/':
      goto st0;
    default:
      goto st1;
  }
}


#if defined(FIX_PATHS) /* Renaming paths like /mounted/... */

struct ren_pair { char *from; char *to; };

static struct ren_pair rename_path_pairs[] = REN_PAIRS;

int fix_path(path)
     char *path;
{
  char *from, *p1, buf[MAXPATHLEN+1];
  struct ren_pair *rp;

  for (rp = rename_path_pairs; *(from = rp->from) ; rp++) {
    for (p1 = path ; *from && *p1 ; from++, p1++) {
      if (*from != *p1) {break;}; /* "path" does not start with "from" */
    }
    if (! *from) { /* "path" starts with "from" */
      strcpy(buf,p1);
      strcpy(path,rp->to);
      strcat(path,buf);
      return TRUE;
    }
  }

  return FALSE;
}
#endif


void compute_cwd()
{
  getcwd(cwd,MAXPATHLEN+1);

#if defined(FIX_PATHS)
  fix_path(cwd);
#endif
}


BOOL prolog_unix_cd(Arg)
     Argdecl;
{
  char pathBuf[MAXPATHLEN+1];

  Unify_constant(MakeString(cwd),X(0));
  DEREF(X(0), X(0));

  DEREF(X(1), X(1));
  if (IsVar(X(1))){
    BUILTIN_ERROR(INSTANTIATION_ERROR,X(1),2)
  }

  if (!IsAtom(X(1))){
    BUILTIN_ERROR(TYPE_ERROR(ATOM),X(1),2)
  }
  
  if (!expand_file_name(GetString(X(1)),pathBuf))
    return FALSE;
  if (chdir(pathBuf))
    {
      ENG_perror("% chdir in working_directory/2");
      MINOR_FAULT("no such directory");
    }
  compute_cwd();
  return TRUE;
}

BOOL prolog_unix_shell0(Arg)
     Argdecl;
{
  char cbuf[MAXPATHLEN+10];

  strcpy(cbuf,"exec ");
  strcat(cbuf,getenv("SHELL"));
  return !system(cbuf);
}

BOOL prolog_unix_shell2(Arg)
     Argdecl;
{
  REGISTER char *p1, *p2;
  char cbuf[2*MAXATOM+MAXPATHLEN+20];

  DEREF(X(0),X(0));

  if (!TagIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,ATOM);

  strcpy(cbuf,"exec ");
  strcat(cbuf,getenv("SHELL"));
  strcat(cbuf," -c ");
  p1 = cbuf+strlen(cbuf);
  for(p2=GetString(X(0)); *p2;)
    *p1++ = '\\',
    *p1++ = *p2++;
  *p1++ = 0;
  return cunify(Arg,MakeSmall(system(cbuf)),X(1));
}


BOOL prolog_unix_system2(Arg)
     Argdecl;
{
  DEREF(X(0),X(0));

  if (!TagIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,ATOM);

  return cunify(Arg,MakeSmall(system(GetString(X(0)))),X(1));
}

/* Return the arguments with which the current prolog was invoked */


BOOL prolog_unix_argv(Arg)
     Argdecl;
{
  REGISTER TAGGED list = atom_nil;
  REGISTER char **p1 = prolog_argv;
  REGISTER int i;
  
  for (i=prolog_argc; i>1;) {
      MakeLST(list,MakeString(p1[--i]),list);
  }
  return cunify(Arg,list,X(0));
}

/* //) ( (+
BOOL prolog_unix_exit(Arg)
     Argdecl;
{
  DEREF(X(0),X(0));

  exit(GetSmall(X(0)));
  return TRUE;
}
*/

BOOL prolog_unix_mktemp(Arg)
     Argdecl;
{
  char template[MAXATOM];

  extern char *mktemp PROTO((char *));
  
  DEREF(X(0),X(0));

  if (!TagIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,ATOM);

  strcpy(template,GetString(X(0)));
  mktemp(template);
  return cunify(Arg,MakeString(template),X(1));
}

BOOL prolog_unix_access(Arg)
     Argdecl;
{
  char pathBuf[MAXPATHLEN+1];
  int mode;

  DEREF(X(0),X(0));

  if (!TagIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,ATOM);

  DEREF(X(1),X(1));

  if (!TagIsSmall(X(1)) || (mode = GetSmall(X(1))) & ~255) /* Not a byte */
    ERROR_IN_ARG(X(1),1,BYTE)

  if (!expand_file_name(GetString(X(0)),pathBuf))
    return FALSE;

  if (access(pathBuf,mode))
    {
      /* ENG_perror("% access in file_exits/2"); --this must be quiet. */
      MINOR_FAULT("access() failed");
    }
  return TRUE;
}

/* directory_files(+Path, FileList) */

BOOL prolog_directory_files(Arg)
     Argdecl;
{
  char pathBuf[MAXPATHLEN+1];
  DIR *dir;
  int gap;
  struct dirent *direntry;

  /* Using X(2) to build the result - DCG */

  DEREF(X(0),X(0));

  if (!TagIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,ATOM);

  if (!expand_file_name(GetString(X(0)),pathBuf))
    return FALSE;

  if (! (dir = opendir(pathBuf))) {
    ENG_perror("% opendir in directory_files/2");
    return FALSE;
  } else {
    X(2) = atom_nil;
    gap = HeapDifference(w->global_top,Heap_End)-CONTPAD;

    while ((direntry = readdir(dir))) {
      if ((gap -= 2) < 0) {
        explicit_heap_overflow(Arg,CONTPAD+32,3);
        gap += 32;
      }
      MakeLST(X(2),MakeString(direntry->d_name),X(2));
    }
  }

  closedir(dir);

  return cunify(Arg,X(2),X(1));
}

/* file_properties(+File, Type, Linkto, ModTime, Protection, Size)

   ModTime: the time (in seconds since 1, Jan, 1970, since file File
   (absolute path) was last modified.
 */

BOOL prolog_file_properties(Arg)
     Argdecl;
{
  struct stat statbuf;
  char pathBuf[MAXPATHLEN+1];
  char symlinkName[MAXATOM+1];
  int len;

  DEREF(X(0),X(0));

  if (!TagIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,ATOM);

  if (!expand_file_name(GetString(X(0)),pathBuf))
    return FALSE;

  DEREF(X(2),X(2));
  if (X(2)!=atom_nil) { /* Link wanted */
    symlinkName[0] = (char) 0;
    if ((len=readlink(pathBuf, symlinkName, MAXATOM)) > 0)
      symlinkName[len] = (char) 0;
    Unify_constant(MakeString(symlinkName),X(2));
  }

  DEREF(X(1),X(1));
  DEREF(X(3),X(3));
  DEREF(X(4),X(4));
  DEREF(X(5),X(5));
  if (   (X(1)!=atom_nil)
      || (X(3)!=atom_nil)
      || (X(4)!=atom_nil)
      || (X(5)!=atom_nil) ) {

    if (stat(pathBuf, &statbuf)) {
      if (current_ferror_flag==atom_on)
        BUILTIN_ERROR(NO_SUCH_FILE,X(0),1)
      else
        return FALSE;
    }

    if (X(1)!=atom_nil) {
    Unify_constant(( S_ISREG(statbuf.st_mode) ? atom_regular
                   : S_ISDIR(statbuf.st_mode) ? atom_directory
                   : S_ISLNK(statbuf.st_mode) ? atom_symlink
                   : S_ISFIFO(statbuf.st_mode) ? atom_fifo
                   : S_ISSOCK(statbuf.st_mode) ? atom_socket
                   : atom_unknown), X(1));
    }

    if (X(3)!=atom_nil) {
      /* Cannot be Unify_constant because it is a large integer */
      if (!cunify(Arg,MakeInteger(Arg,statbuf.st_mtime),X(3)))
        return FALSE;  
    }

    if (X(4)!=atom_nil) {
      Unify_constant(MakeSmall(statbuf.st_mode&0xfff),X(4));
    }

    if (X(5)!=atom_nil) {
      Unify_constant(MakeSmall(statbuf.st_size), X(5));
    }
  }
  
  return TRUE;
}

BOOL prolog_unix_chmod(Arg)
     Argdecl;
{
  char pathBuf[MAXPATHLEN+1];

  DEREF(X(0),X(0));

  if (!TagIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,ATOM);

  if (!expand_file_name(GetString(X(0)),pathBuf))
    return FALSE;

  DEREF(X(1),X(1));

  if (!TagIsSmall(X(1)))
    return FALSE;

  if (chmod(pathBuf, GetSmall(X(1))))
    {
      ENG_perror("% chmod in chmod/2");
      MINOR_FAULT("chmod() failed");
    }

  return TRUE;
}

BOOL prolog_unix_umask(Arg)
     Argdecl;
{
  int i;
  
  DEREF(X(1),X(1));

  if (IsVar(X(1))) {
      i = umask(0);
      (void)umask(i);
      return cunify(Arg,MakeSmall(i),X(0));
  } else {
    if (!TagIsSmall(X(1)))
      return FALSE;
    return cunify(Arg,MakeSmall(umask(GetSmall(X(1)))),X(0));
  }
}




BOOL prolog_unix_delete(Arg)
     Argdecl;
{
  char pathBuf[MAXPATHLEN+1];

  DEREF(X(0),X(0));

  if (!TagIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,ATOM);

  if (!expand_file_name(GetString(X(0)),pathBuf))
    return FALSE;

  if (unlink(pathBuf))
    {
      ENG_perror("% unlink in delete_file/1");
      MINOR_FAULT("unlink() failed");
    }

  return TRUE;
}

/*
 *  current_host(?HostName).
 */
BOOL prolog_current_host(Arg)
     Argdecl;
{
  char hostname[MAXHOSTNAMELEN*4];
  
  if (gethostname(hostname, sizeof(hostname)) < 0)
    SERIOUS_FAULT("current_host/1 in gethostname");
  
  if (!strchr(hostname, '.')) {
    struct hostent *host_entry;
    char **aliases;
    
    /* If the name is not qualified, then pass the name through the name
       server to try get it fully qualified */
    if ((host_entry = gethostbyname(hostname)) == NULL)
      SERIOUS_FAULT("current_host/1 in gethostbyname"); 
    strcpy(hostname, host_entry->h_name);
    
    /* If h_name is not qualified, try one of the aliases */
    
    if ((aliases=host_entry->h_aliases)) {
      while (!strchr(hostname, '.') && *aliases)
        strcpy(hostname, *aliases++);
      if (!strchr(hostname, '.'))
        strcpy(hostname, host_entry->h_name);
    }
    
#if HAS_NIS
    /* If still unqualified, then get the domain name explicitly.
       This code is NIS specific, and causes problems on some machines.
       Apollos don't have getdomainname, for example. */
    if (!strchr(hostname, '.')) {
      char domain[MAXHOSTNAMELEN*3];
      
      if (getdomainname(domain, sizeof(domain)) < 0)
        SERIOUS_FAULT("current_host/1 in getdomainname");
      strcat(hostname, ".");
      strcat(hostname, domain);
    }
#endif
  }

  DEREF(X(0),X(0));

  return cunify(Arg, MakeString(hostname), X(0));
}

/* getenvstr(+Name,-Value) */

BOOL prolog_getenvstr(Arg)
     Argdecl;
{
  char *s;
  int i;
  TAGGED cdr;

  DEREF(X(0),X(0));
  DEREF(X(1),X(1));
  
  if (!TagIsATM(X(0)))
    BUILTIN_ERROR(TYPE_ERROR(ATOM),X(0),1)

  if ((s = getenv(GetString(X(0)))) == NULL) return FALSE;

  s += (i = strlen(s));
  if (HeapDifference(w->global_top,Heap_End)<CONTPAD+(i<<1))
    explicit_heap_overflow(Arg,CONTPAD+(i<<1),2);

  cdr = atom_nil;
  while (i>0) {
    i--;
    MakeLST(cdr,MakeSmall(*(--s)),cdr);
  }
  return cunify(Arg,cdr,X(1));
}


/*
   pause(+Seconds): make this process sleep for Seconds seconds
*/

BOOL prolog_pause(Arg)
     Argdecl;
{
  TAGGED x0;
  long time;
  
  DEREF(x0, X(0));
  if (!TagIsSmall(x0)){
    BUILTIN_ERROR(TYPE_ERROR(INTEGER),X(0),1)
  }

  time = GetSmall(x0);

  sleep(time);

  return TRUE;
}


/*
  get_pid(?PID): PID is unified with  the process identificator number 
  of this process 
*/

BOOL prolog_getpid(Arg)
     Argdecl;
{
  TAGGED x0;

  DEREF(x0, X(0));
  return cunify(Arg, x0, MakeSmall(getpid()));
}


/* $find_file(+LibDir,+Path,+Opt,+Suffix,?Found,-AbsPath,-AbsBase,-AbsDir)
 * string LibDir	a library in which to search for Path
 * string Path		a path, may be absolute or relative. If LibDir
 *			is specified then Path must be relative to LibDir.
 * string Opt           an optional suffix to Path, must precede Suffix, is
 *                      included in AbsBase
 * string Suffix        an optional suffix to Path, not included in AbsBase
 * atom   Found         true or fail
 * string AbsPath       the absolute pathname of Path
 * string AbsBase       the absolute pathname of Path, without Suffix
 * string AbsDir        the absolute pathname of the directory of Path
 *
 * Description: Try to find in LibDir, in this order:
 *   Path+Opt+Suffix
 *   Path+Suffix
 *   Path
 *   Path/Path+Opt+Suffix
 *   Path/Path+Suffix
 *   Path/Path
 * if any found, unify Found with true, and return in AbsPath, AbsBase and
 * AbsDir the appropriate values, else unify Found with false, and return in
 * AbsPath, AbsBase and AbsDir the values corresponding to the last option
 * (no Opt nor Suffix).
 */

#if !defined(S_ISDIR)                                 /* Notably, Solaris */
#  define S_ISDIR(m)	(((m) & S_IFMT) == S_IFDIR)
#endif

BOOL prolog_find_file(Arg)
     Argdecl;
{
  char *libDir, *path, *opt, *suffix;
  char pathBuf[MAXPATHLEN+8];
  char relBuf[2*MAXATOM+2];
  REGISTER char *bp;
  char *cp;
  struct stat file_status;

  DEREF(X(0),X(0));
  libDir = GetString(X(0));
  DEREF(X(1),X(1));
  path = GetString(X(1));
  DEREF(X(2),X(2));
  opt = GetString(X(2));
  DEREF(X(3),X(3));
  suffix = GetString(X(3));
  
  if (path[0] == '/' || path[0] == '$' || path[0] == '~'
#if defined(Win32)
      || path[0] == '\\' || DriveSelector(path)
#endif
      ) {
    strcpy(relBuf,path);
  } else {
    strcpy(relBuf,libDir);
    if (relBuf[strlen(relBuf)-1]!='/')
      strcat(relBuf,"/");
    strcat(relBuf,path);
  }

  if (!expand_file_name(relBuf,pathBuf))
    return FALSE;

#if defined(FIX_PATHS)
  fix_path(pathBuf);
#endif

  cp = pathBuf + strlen(pathBuf);

 searchPath:
  
  if (*opt) {
    strcpy(cp,opt);
    bp = cp + strlen(cp);
    strcpy(bp,suffix);
    if(!access(pathBuf,F_OK)) {
      stat(pathBuf, &file_status);
      if (!S_ISDIR(file_status.st_mode)) {
        Unify_constant(atom_true,X(4));    /* found path+opt+suffix */
        goto giveVals;
      }
    }
  }
  
  bp = cp;

  if (*suffix) {
    strcpy(bp,suffix);
    if(!access(pathBuf,F_OK)) {
      stat(pathBuf, &file_status);
      if (!S_ISDIR(file_status.st_mode)) {
        Unify_constant(atom_true,X(4));    /* found path+suffix */
        goto giveVals;
      }
    }
  }

  *bp = 0;
  
  if(!access(pathBuf,F_OK)){
    stat(pathBuf, &file_status);
    if (S_ISDIR(file_status.st_mode)) {    /* directory */
      while (*bp!='/') --bp;               /* duplicate dir name */
      *cp++ = *bp++ ;
      while (*bp!='/')
        *cp++ = *bp++ ;
      *cp = 0;
      goto searchPath;                     /* search inside */
    } else {
      Unify_constant(atom_true,X(4));      /* found path */
      if (*suffix && strcmp(bp -= strlen(suffix), suffix))
                     /* does not end in suffix */
        bp = cp;
      goto giveVals;
    }
  }

  Unify_constant(atom_fail,X(4));

 giveVals:

  Unify_constant(MakeString(pathBuf),X(5));

  *bp = 0;

  Unify_constant(MakeString(pathBuf),X(6));

  while (*bp!='/')
    --bp;
  *bp = 0;

  Unify_constant(MakeString(pathBuf),X(7));
  
  return TRUE;
}


extern char *emulator_architecture;

/*
 *  get_arch(?ArchName).
 */
BOOL prolog_getarch(Arg)
     Argdecl;
{
  DEREF(X(0),X(0));
  return cunify(Arg, MakeString(emulator_architecture), X(0));
}


extern char *emulator_os;

/*
 *  get_os(?OsName).
 */
BOOL prolog_getos(Arg)
     Argdecl;
{
  DEREF(X(0),X(0));
  return cunify(Arg, MakeString(emulator_os), X(0));
}


/*
 * exec(+Process, -StdIn, -StdOut, -StdErr): connect to an external process
 */

#define Read  0 
#define Write 1 

#define STDIN  0 
#define STDOUT 1 
#define STDERR 2


BOOL prolog_exec(Arg)
     Argdecl;
{
  char *command;
  BOOL dup_stderr;
  int 
    pipe_in[2],                                   /* Child standard input */
    pipe_out[2],                                 /* Child standard output */
    pipe_err[2];                                  /* Child standard error */

  struct stream_node 
    *str_in,                       /* Connection to child standard input  */
    *str_out,                     /* Connection to child standard output  */
    *str_err;                      /* Connection to child standard error  */
  
  int pid;

  DEREF(X(0), X(0));
  if (!IsAtom(X(0))){
    BUILTIN_ERROR(TYPE_ERROR(ATOM),X(0),1)
  }

  pipe(pipe_in);
  pipe(pipe_out);

  DEREF(X(3), X(3));
  if (X(3) == atom_nil)
    dup_stderr = FALSE;
  else {
    dup_stderr = TRUE;
    pipe(pipe_err);
  }

  command = GetString(X(0));

  /* Empty buffers before launching child */
  fflush(NULL);

  pid = fork();

  if (pid == -1) {
    SERIOUS_FAULT("exec/4 could not fork() new process");
  } else 
    if (pid == 0) {                                              /* Child */
      close(pipe_in[Write]);      
      dup2(pipe_in[Read],STDIN);
      close(pipe_out[Read]);
      dup2(pipe_out[Write],STDOUT);
      if (dup_stderr) {
        close(pipe_err[Read]);
        dup2(pipe_err[Write],STDERR);
      }
      if (execlp("sh", "sh", "-c", command, NULL) < 0){
        MAJOR_FAULT("exec(): could not start process");
      } else return TRUE;
    } else {                                                      /* Parent */
      close(pipe_in[Read]);
      str_in  = new_stream(X(0), "w", fdopen(pipe_in[Write], "w"));
      close(pipe_out[Write]);
      str_out = new_stream(X(0), "r", fdopen(pipe_out[Read], "r"));
      if (dup_stderr) 
        close(pipe_err[Write]);
        str_err = new_stream(X(0), "r", fdopen(pipe_err[Read], "r"));
      return  cunify(Arg, ptr_to_stream(Arg, str_in), X(1))
        &&    cunify(Arg, ptr_to_stream(Arg, str_out), X(2))
        &&   (dup_stderr ? 
              cunify(Arg, ptr_to_stream(Arg, str_err), X(3)) :
              TRUE); 
    }
}

