%% :- module(_,_,[make,assertions]).
:- module(_,_,[assertions]).

:- use_module(library('make/make_rt')).
%% :- use_package(trace).

%% ISO Prolog-like modules
:- use_module(library(format),[format/3]).
:- use_module(library(aggregates),[findall/3]).

%% Ciao libraries
:- use_module(library(errhandle),[handle_error/2]).
:- use_module(library(lists),[append/3]).
:- use_module(library(system),[file_exists/1]).
:- use_module(library(messages),[error_message/2]).
%% *** Will be loaded INTO library also
:- use_module(library(compiler),[use_module/1]).
%% :- use_module(library(compiler),[ensure_loaded/1,use_module/1]).

:- comment(title,"The Ciao lpmake scripting facility").
:- comment(subtitle,"A portable make with all the power of Prolog inside").

:- comment(author,"Manuel Hermenegildo").
:- comment(author, "@tt{clip@@dia.fi.upm.es}").
:- comment(author, "@tt{http://www.clip.dia.fi.upm.es/}").
:- comment(author, "The CLIP Group").
:- comment(author, "Facultad de Inform@'{a}tica").
:- comment(author, "Universidad Polit@'{e}cnica de Madrid").

:- comment(copyright,"
Copyright @copyright{} 1997-2002 The Clip Group.

@include{Copyright.Manuals}
").

:- comment(summary,"@apl{lpmake} is a small Ciao application which
   uses the Ciao @lib{make} library to implement dependency-driven
   scripts in a similar way to the Un*x @apl{make}
   facility. @apl{lpmake} offers three main advantages. First,
   @em{portability}: it runs without need for recompilation on any
   platform. Second, @em{improved programming capabilities}. While
   @apl{lpmake} is simpler than @apl{make}, the full Ciao Prolog
   language is available within @apl{lpmake} scripts. This allows
   programming powerful operations without resorting to external
   packages or operating system commands (which allows execution on
   multiple operating systems), establishing more complex
   dependencies, etc. Finally, @em{autodocumentation}: it allows
   adding comments to targets so that calling @apl{lpmake} in a
   directory explains what commands the configuration files in that
   directory implement and what these commands will do.").

:- comment(module,"

   @cindex{make} @cindex{lpmake} 

   @bf{Note:} @apl{lpmake} and the @lib{make} library are still under
   development, and they may change in future releases.

   @apl{lpmake} is a Ciao application which uses the Ciao @lib{make}
   library to implement a dependency-driven scripts in a similar way
   to the Un*x @apl{make} facility.

   The original purpose of the Un*x @apl{make} utility is to determine
   automatically which pieces of a large program needed to be
   recompiled, and issue the commands to recompile them.  In practice,
   @apl{make} is often used for many other purposes: it can be used to
   describe any task where some files must be updated automatically
   from others whenever these change.  @apl{lpmake} can be used for
   the same types of applications as @apl{make}, and also for some new
   ones, and, while being simpler, it offers a number of advantages
   over @apl{make}. The first one is @em{portability}. When compiled
   to a bytecode executable @apl{lpmake} runs on any platform where a
   Ciao engine is available. Also, the fact that typically many of the
   operations are programmed in Prolog within the makefile, not
   needing external applications, improves portability further. The
   second advantage of @apl{lpmake} is @em{improved programming
   capabilities}.  While @apl{lpmake} is simpler than @apl{make},
   @apl{lpmake} allows using the Ciao Prolog language within the
   scripts. This allows establising more complex dependencies and
   programming powerful operations within the make file, and without
   resorting to external packages (e.g., operating system commands),
   which also helps portability. A final advantage of @apl{lpmake} is
   that it supports a form of @em{autodocumentation}: @cindex{lpmake
   autodocumentation} comments associated to targets can be included
   in the configuration files. Calling @apl{lpmake} in a directory
   which has such a configuration file explains what commands the
   configuration file support and what these commands will do.

   @section{General operation}

   To prepare to use @apl{lpmake}, and in a similar way to @apl{make},
   you must write a @index{configuration file}: a module (typically
   called @file{Makefile.pl}) that describes the relationships among
   files in your program or application, and states the commands for
   updating each file.  In a program, typically the executable file is
   updated from object files, which are in turn made by compiling
   source files.  Another example is running @apl{latex} and
   @apl{dvips} on a set of source @tt{.tex} files to generate a
   document in @tt{dvi} and @tt{postscript} formats. Once a suitable
   makefile exists, each time you change some source files, simply
   typing @tt{lpmake} suffices to perform all necessary operations
   (recompilations, processing text files, etc.).  The @apl{lpmake}
   program uses the dependency rules in the makefile and the last
   modification times of the files to decide which of the files need
   to be updated.  For each of those files, it issues the commands
   recorded in the makefile. For example, in the
   @apl{latex}/@apl{dvips} case one rule states that the @tt{.dvi}
   file whould be updated from the @tt{.tex} files whenever one of
   them changes and another rule states that the @tt{.ps} file needs
   to be updated from a @tt{.dvi} file every time it changes. The
   rules also describe the commands to be issued to update the files.

   So, the general process is as follows: @apl{lpmake} executes
   commands in the configuration file to update one or more target
   @em{names}, where @em{name} is often a program, but can also be a
   file to be generated or even a ``virtual'' target.  @apl{lpmake}
   updates a target if it depends on prerequisite files that have been
   modified since the target was last modified, or if the target does
   not exist.  You can provide command line arguments to @apl{lpmake}
   to control which files should be regenerated, or how. 

   @section{Format of the Configuration File}

   @apl{lpmake} uses as default configuration file the file
   @file{Makefile.pl}, if it is present in the current directory.
   This can be overridden and another file used by means of the
   @tt{-m} option. The configuration file must a @em{module} that uses
   the @lib{make} package. This package provides syntax for defining
   the dependency rules and functionality for correctly interpreting
   these rules. The configuration files can contain such rules and
   also arbitrary Ciao Prolog predicates. The syntax of the rules is
   described in @ref{The Ciao Make Package}, together with some examples.

   @section{lpmake usage}

@comment{This already talks about the autodocumentation...}
@begin{verbatim}
@includefact{usage_message/1}
@end{verbatim}

").

:- comment(ack,"Some parts of the documentation are taken from the
   documentation of GNU's @apl{gmake}.").

main :- 
 	make_toplevel(lpmake).

%% ---------------------------------------------------------------------------
%% Top-level (generic, used to be in make lib, but put here for simplicity)
%% ---------------------------------------------------------------------------

make_toplevel(ApplName) :-
	prolog_flag(argv, Args, _),
 	catch(parse_args(Args,ApplName), E, handle_make_error(E)).

handle_make_error(make_args_error(Format,Args,ApplName)) :- 
	append("~nERROR: ",Format,T1),
	append(T1,"~n~n",T2),
	format(user_error,T2,Args),
	report_usage(ApplName),
        report_commands(_Type,'').
handle_make_error(make_error(Format,Args)) :- 
	error_message(Format,Args).
handle_make_error(error(Error,Where)) :- 
	handle_error(Error, Where).

parse_args(['-h'|Args],ApplName) :- 
	report_usage(ApplName),
	parse_other_args_and_load(Args,Type,ConfigFile,[]),
	!,
        report_commands(Type,ConfigFile).
parse_args(['-help'|Args],ApplName) :- 
	report_usage(ApplName),
	parse_other_args_and_load(Args,Type,ConfigFile,[]),
	!,
        report_commands(Type,ConfigFile).
parse_args(['-v'|Args],_ApplName) :- 
	parse_other_args_and_load(Args,_Type,_ConfigFile,Targets),
	!,
	asserta_fact(make_option('-v')),
        process_targets(Targets).
parse_args(Args,_ApplName) :- 
	parse_other_args_and_load(Args,_Type,_ConfigFile,Targets),
	!,
        process_targets(Targets).
parse_args(Args,ApplName) :-
	throw(make_args_error("~nIllegal arguments: ~w~n~n",[Args],ApplName)).
	

parse_other_args_and_load([Type,ConfigFile|Targets],Type,ConfigFile,Targets):- 
	Type = '-m',
	!,
	load_config_file(Type,"module",ConfigFile).
%parse_other_args_and_load([Type,ConfigFile|Targets],Type,ConfigFile,Targets):-
%% 	Type = '-u',
%% 	!,
%% 	load_config_file(Type,"user file",ConfigFile).
parse_other_args_and_load(Targets,Type,ConfigFile,Targets) :- 
	\+ member('-h', Targets),
%%	\+ member('-u', Targets),
	\+ member('-m', Targets),
	!,
	Type = '-m',
	ConfigFile = 'Makefile.pl',
	load_config_file(Type,"(default) module",ConfigFile).

%% Needed to access predicates generated in user Makefile.pl files
%% Unfortunately, messes up using modules, so we settle for just modules
%% :- import(user,[do_dependency/3,dependency_exists/2,do_target/1,
%%                 target_exists/1,target_deps/2,target_comment/1,
%%                 dependency_comment/3]).

load_config_file(Type,Text,ConfigFile) :-
	(  file_exists(ConfigFile) 
	-> verbose_message("loading ~s ~w",[Text,ConfigFile]),
	(  Type = '-m'
	   -> use_module(ConfigFile),
	      dyn_load_cfg_module_into_make(ConfigFile)
	   ;  throw(make_error("configuration 'user' files not supported",[]))
	      %% ensure_loaded(ConfigFile),
	      %% dyn_load_cfg_file_into_make(ConfigFile)
	   )
	;  throw(make_error("file ~w does not exist",[ConfigFile])) ).

%% If no target process default if defined
process_targets([]) :-
	call_unknown(_:target_exists(default)),
	!,
	make(default).
%% else process first target
process_targets([]) :-
	call_unknown(_:target_exists(Target)),
	!,
	make(Target).
%% If targets specified, process them
process_targets(Targets) :-
	!,
	make(Targets).

%% -u not used any more
%%
%% [-v] [-u <.../Configfile.pl>] <command1> ... <commandn>
%% 
%%   Process commands <command1> ... <commandn>, using user 
%%   file <.../Configfile.pl> as configuration file. If no 
%%   configuration file is specified a file 'Makefile.pl' in 
%%   the current directory will be used. 
%% 
%% -h     [ -u <.../Configfile.pl> ]
%% -help  [ -u <.../Configfile.pl> ]

%% This is in narrow format because that way it looks nicer in a man page.
usage_message("

Supported command line options:

lpmake [-v] <command1> ... <commandn>

  Process commands <command1> ... <commandn>, using 
  file 'Makefile.pl' in the current directory as 
  configuration file. The configuration file must 
  be a module. This is useful to implement 
  inherintance across diferent configuration files, 
  i.e., the values declared in a configuration file 
  can be easily made to override those defined in 
  another.

  The optional argument '-v' produces verbose output, 
  reporting on the processing of the dependency rules. 
  Very useful for debugging Makefiles.

lpmake [-v] [-m <.../Configfile.pl>] <command1> ... <commandn>

  Same as above, but using file <.../Configfile.pl> 
  as configuration file. 

lpmake -h     [ -m <.../Configfile.pl> ]
lpmake -help  [ -m <.../Configfile.pl> ]

  Print this help message. If a configuration file is given, 
  and the commands in it are commented, then information on 
  these commands is also printed.

").

report_usage(ApplName) :-
	format(user_error,"~nUsage:~n~n       ~w <option(s)> <command(s)>~n",
	                  [ApplName]),
	usage_message(Text),
	format(user_error,Text,[]).

report_commands(Type,LoadedFile) :-
	format(user_error,"~nSupported commands:~n",[]),
	report_commands_aux(Type,LoadedFile).

report_commands_aux(_Type,'') :-
	!,
	format(user_error,"~n(no configuration file loaded)~n",[]).
report_commands_aux(Type,LoadedFile) :-
	(  Type = '-m'
	-> TypeText = "module"
	;  TypeText = "user file" ),
	format(user_error,"[From ~s: ~w]~n~n",[TypeText,LoadedFile]),
	(  findall(Target,call_unknown(_:target_exists(Target)),Targets),
	   Targets = [_ |_ ]
	-> ( member(Target,Targets),
	     format(user_error,"    ~w:~n",[Target]),
	     (  call_unknown(_:target_comment(Target))
	     -> true
	     ;  format(user_error,"    (no information available)~n",[]) ),
	     format(user_error,"~n",[]),
	     fail
	   ; true )
	;  format(user_error,
           "(no documented commands in the configuration file)~n",
	   []) ).

%%------------------------------------------------------------------------
%% VERSION CONTROL
%%------------------------------------------------------------------------
 
:- comment(version_maintenance,dir('../version')).

:- comment(version(1*9+27,2002/11/20,13:04*12+'CET'), "Not supporting
   the use of 'user' makefiles any more (too hard to adapt everything
   to their scoping rules), i.e., at the moment makefiles must be
   modules. May add support for user files again in the future.
   (Manuel Hermenegildo)").

%%------------------------------------------------------------------------


