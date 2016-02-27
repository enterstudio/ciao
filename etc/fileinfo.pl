%% #!/bin/sh
%% exec ciao-shell $0 "$@"

%% CIAO syntax
:- use_package([assertions]).  

%% ISO Compat
:- use_module(library(read)).  
:- use_module(library(fastrw)).  
:- use_module(library(format)).  
:- use_module(library(aggregates)).  

%% CIAO libraries
:- use_module(library('compiler/c_itf')).
:- use_module(library('assertions/assrt_lib')).
:- use_module(library('assertions/assrt_write')).

:- comment(title,"Printing the declarations and code in a file").

:- comment(author,"Manuel Hermenegildo").

:- comment(module,"A simple program for @concept{printing assertion
   information} (@concept{predicate declarations}, @concept{property
   declarations}, @concept{type declarations}, etc.) and
   @concept{printing code-related information} (@concept{imports},
   @concept{exports}, @concept{libraries used}, etc.)  on a file. The
   file should be a single CIAO or Prolog source file. It uses the
   CIAO compiler's pass one to do it. This program is specially useful
   for example to check what the compiler is actually seeing after
   syntactic expansions, as well as for checking what assertions the
   @concept{assertion normalizer} is producing from the original
   assertions in the file. 

   @section{Usage (fileinfo)}

   @begin{verbatim}
   @includefact{usage_text/1}
   @end{verbatim}

   @section{More detailed explanation of options (fileinfo)}

   @includefact{option_text/1}
").

:- multifile library_directory/1.
:- dynamic library_directory/1.

main(Args) :-
	handle_args(Args).

handle_args(['-h']) :-
	usage.
handle_args(['-asr', File]) :-
	print_asr(File).
handle_args(IArgs) :-
	(  IArgs = ['-v'|Args]
	-> prolog_flag(verbose_compilation,_,on)
	;  prolog_flag(verbose_compilation,_,off),
	   Args=IArgs ),
	( Args = [Opt1,Opt2,Main|Libs], 
	  Opt1 = '-m' 
	; Args = [Opt2,Main|Libs] ),
	( Opt2 = '-a' ; Opt2 = '-c' ; Opt2 = '-e' ),
	!,
	(  prolog_flag(verbose_compilation,on,on)
	-> format("{Printing info for ~w with libs ~w}~n",[Main,Libs])
	;  true ),
	set_libs(OldLibs,Libs),
	get_code_and_related_assertions(Main,M,Base,_Suffix,_Dir),
	set_libs(_,OldLibs),
	(  Opt1 == '-m' 
	-> DM = M, DBase = Base
	;  true),
	handle_options(Opt2,DM,DBase),
	true.
handle_args(Args) :-
	format("error: invalid arguments ~w~n",[Args]),
	usage.

usage :-
	usage_text(Text),
        format(user_error,"Usage: ~s~n",[Text]).

usage_text("
    fileinfo -asr <filename.asr> 
       : pretty prints the contents of <filename.asr> 

    fileinfo [-v] [-m] <-a|-c|-e> <filename> [libdir1] ... [libdirN]
    -v : verbose output (e.g., lists all files read)
    -m : restrict info to current module
    -a : print assertions 
    -c : print code and interface (imports/exports, etc.)
    -e : print only errors - useful to check syntax of assertions in file

    fileinfo -h
       : print this information
").

option_text("
   @begin{itemize} 

   @item If the @tt{-a} option is selected, @tt{fileinfo} prints the
   assertions (only code-oriented assertions -- not comment-oriented
   assertions) in the file @em{after normalization}. If the @tt{-c}
   option is selected @tt{fileinfo} prints the file interface, the
   declarations contained in the file, and the actual code. If the
   @tt{-e} option is selected @tt{fileinfo} prints only any sintactic
   and import-export errors found in the file, including the
   assertions.

   @item @tt{filename} must be the name of a Prolog or CIAO source
   file.

   @item This filename can be followed by other arguments which will
   be taken to be library directory paths in which to look for files
   used by the file being analyzed. 

   @item If the @tt{-m} option is selected, only the information
   related to the current module is printed.

   @item The @tt{-v} option produces verbose output. This is very
   useful for debugging, since all the files accessed during assertion
   normalization are listed.

   @item In the @tt{-asr} usage, @apl{fileinfo} can be used to print
   the contents of a @tt{.asr} file in human-readable form.

   @end{itemize}
").

handle_options('-a',M,_Base) :-
	!,
	prolog_flag(write_strings, Old, on),
	print_assertions(M),
	set_prolog_flag(write_strings, Old).
handle_options('-c',M,Base) :-
	!,
	print_gathered_module_data(M,Base).
handle_options('-e',_M,_Base).

print_gathered_module_data(_M,Base) :-
	set_prolog_flag(write_strings, on),
	format("{Printing code info~n",[]),

	defines_module(Base,DefMod),
          format("~w defines module ~w~n",[Base,DefMod]),

	forall((exports(Base,F,A,T,Met),
           format("~w exports ~w/~w (~w) meta=~w~n",[Base,F,A,T,Met]))),

	forall((def_multifile(Base,F,A,Mo),
           format("~w defines multifile ~w/~w as ~w~n",[Base,F,A,Mo]))),

	forall((defines(Base,F,A,T,Met),
           format("~w defines ~w/~w (~w) meta=~w~n",[Base,F,A,T,Met]))),

	forall((decl(Base,Decl),
           format("~w has itf-exported new declaration ~w~n",[Base,Decl]))),

	forall((uses_file(Base,File),
           format("~w uses ~w~n",[Base,File]))),

	forall((adds(Base,File),
           format("~w does ensure_loaded of user file ~w~n",[Base,File]))),

	forall((imports_pred(Base,M2,F,A,Met), % M2\==builtin,M2\==internals,
           format("~w imports ~w/~w from ~w meta=~w~n",[Base,F,A,M2,Met]))),

	forall((imports_all(Base,M2), 
           format("~w imports all from ~w~n",[Base,M2]))),

	forall((includes(Base,File), 
           format("~w includes ~w~n",[Base,File]))),

	forall((loads(Base,Path),
           format("~w loads ~w as compilation module~n",[Base,Path]))),

	forall((clause_read(Base,Head,Body,VNs,Source,LB,LE),
           format("~w (~w-~w):~n ~w :- ~w.~nDictionary:~w~n",
                  [Source,LB,LE,Head,Body,VNs]))),

        format("}~n",[]).

forall(G) :-
	( call(G),
	  fail
	;
	  true ).

print_asr(File) :-
	prolog_flag(write_strings, _, on),
	read_asr_file(File).

read_asr_file(File) :-
        current_input(CI),
        open(File, read, Stream),
        set_input(Stream),
	read(Version),
	format("Normalizer version: ~w~n",[Version]),
        read_asr_data_loop,
        set_input(CI),
        close(Stream).

read_asr_data_loop :-
	(  fast_read(X)
	-> process_assrt(X),
	   read_asr_data_loop
	;  true ).

process_assrt(assertion_read(PD,_M,Status,Type,Body,Dict,_S,_LB,_LE)) :- 
	!,
	write_assertion(PD,Status,Type,Body,Dict,status).
process_assrt(clause_read(_Base,H,B,Dict,_S,_LB,_LE)) :- 
	!,
	unify_vars(Dict),
	format("Clause ~w :- ~w.\n",[H,B]).
process_assrt(X) :- 
	format("*** Warning: ~w is not an assertion~n",[X]).

unify_vars([]).
unify_vars([N=V|Dict]):-
	V='$VAR'(N),
	unify_vars(Dict).

%% ---------------------------------------------------------------------------

:- comment(version_maintenance,on).

:- comment(version(0*5+6,1999/04/15,20:33*06+'MEST'), "Added @tt{-asr}
   usage.  (Manuel Hermenegildo)").

:- comment(version(0*5+5,1998/11/30,17:22*58+'MET'), "Adapted to new
   version of c_itf.  (Manuel Hermenegildo)").

:- comment(version(0*5+4,1998/2/7), "Modified documentation. Added -m
   option. (Manuel Hermenegildo)").

:- comment(version(0*5+3,1998/1/28), "Added options to print just
   assertions or assertions and code. (Manuel Hermenegildo)").

:- comment(version(0*5+2,1998/1/27), "Simplified using the predicates
   exported by the assertions library. (Manuel Hermenegildo)").

:- comment(version(0*5+1,1998/1/15), "Added documentation. (Manuel
   Hermenegildo)").

:- comment(version(0*5+0,1998/1/15), "First version. (Manuel
   Hermenegildo)").

%% ---------------------------------------------------------------------------

