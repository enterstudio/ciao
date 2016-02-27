:- module(_,[
	make_directory/1, 
%%      make_dirpath/1,
	del_dir_if_empty/1, 
	move_files/2,move_file/2,
	copy_files/2,copy_file/2,
	cat/2,cat_append/2,
	convert_permissions/4,
	symbolic_link/2, symbolic_link/3,
	delete_files/1,del_file_nofail/1,del_file_nofail/2,
	del_endings_nofail/2,
	ls/3,ls/2,
	filter_alist_pattern/3,
	'-'/1, do/2,
	set_perms/2,
	readf/2,
	datime_string/1,
	datime_string/2,
	all_values/2,
	no_tr_nl/2,
	call_unknown/1,
	replace_strings_in_file/3,
	writef/3,
	writef/2 ],[assertions,isomodes,hiord]).

%% The idea is that it is an extension
:- reexport(library(system)).
%%  [datime/9,working_directory/2,file_exists/1,
%%   file_exists/2,file_property/2,chmod/2,system/2,delete_file/1,
%%   directory_files/2,cd/1]

:- use_module(library(patterns)).
:- use_module(library(filenames)).
:- use_module(library(messages),
	[warning_message/2,error_message/2,note_message/2]).
:- use_module(library(terms),[atom_concat/2]).
:- use_module(library(lists),[list_concat/2,append/3]).
:- use_module(library(sort),[sort/2]).
:- use_module(library(aggregates),[findall/3]).

%% IDEA: where they used to take an atom, all now take in addition a 
%% list of atoms, which are concatenated (saves all the 
%% calls to atom_concat).

%% -------------------------------------------------------------------------
%% Preds from the SICSTus library that we need to implement
%% -------------------------------------------------------------------------

%% In ciao it is called pause/1.
%% `sleep(+SECONDS)'
%%      Puts the SICStus Prolog process asleep for SECOND seconds.

%%    Some predicates are described as invoking the default shell.
%% Specifically this means invoking `/bin/sh' on UNIX platforms. On MSDOS,
%% Windows and OS/2, the command interpreter given by the environment
%% variable `COMSPEC' is invoked.

%% Needs to be added 
%% :- comment(delete_file(FileName,Options), "@var{FileName} is the
%%    name of an existing file or directory.  @var{Options} is a list of
%%    options. Possible options are @tt{directory}, @tt{recursive} or @tt{ignore}.
%%    If @var{FileName} is not a directory it is deleted, otherwise if
%%    the option @tt{directory} is specified but not @tt{recursive}, the
%%    directory will be deleted if it is empty. If @tt{recursive} is
%%    specified and @var{FileName} is a directory, the directory and all
%%    its subdirectories and files will be deleted.  If the operation
%%    fails, an exception is raised unless the @tt{ignore} option is
%%    specified.").
%% 
%% :- true pred delete_file(+atm,+list(delete_file_option)).
%% 
%% delete_file(FileName,[recursive]) :- delete_file(FileName,[recursive])
%% 
%% 
%% 
%% :- comment(delete_file(FileName), "Equivalent to
%%    @tt{delete_file(FileName,[recursive])}.").
%% 
%% :- true pred delete_file(+atm).
%% 
%% delete_file(FileName) :- delete_file(FileName,[recursive])
%% 
%% :- regtype delete_file_option(X) # "@var{X} is an option controlling
%%    file deletion".
%% 
%% delete_file_option(directory).
%% delete_file_option(recursive).
%% delete_file_option(ignore).


del_dir_if_empty(Dir) :-
	working_directory(CD,CD),
	(  file_exists(Dir)
	-> cd(Dir),
	   (  ls('*',['..','.']) %% empty dir!
	   -> delete_directory(Dir)
	   ;  true )
	;  true ),
	cd(CD).

:- redefining(make_directory/1). % It is defined in library(system)

:- comment(make_directory(DirName),"Makes a new directory called
   @var{DirName}.").

:- true pred make_directory(+atm).

%% Needs real implementation...
make_directory(DirName) :-
	(  file_exists(DirName)
	-> note_message("did not create ~w (it already exists)",[DirName])
	;  do(['mkdir ',DirName],fail) ).

%% version which also creates path
%% Needs real implementation...
 %% make_dirpath(DirName) :-
 %% 	(  file_exists(DirName)
 %% 	-> note_message("did not create ~w (it already exists)",[DirName])
 %% 	;  do(['mkdir -p ',DirName],fail) ).

%% Note name and type change, and it enumerates.
%% `environ(?VAR, ?VALUE)'
%%      VAR is the name of an environment variable, and VALUE is its
%%      value.  Both are atoms.  Can be used to enumerate all current
%%      environment variables.
     

%% Note options:
%% `exec(+COMMAND, [+STDIN,+STDOUT,+STDERR], -PID)'
%%      Passes COMMAND to a new default shell process for execution.  The
%%      standard I/O streams of the new process are connected according to
%%      what is specified by the terms +STDIN, +STDOUT, and +STDERR
%%      respectively.  Possible values are:
%% 
%%     `null'
%%           Connected to `/dev/null' or equivalent.
%% 
%%     `std'
%%           The standard stream is shared with the calling process. Note
%%           that the standard stream may not be referring to a console if
%%           the calling process is "windowed". To portably print the
%%           output from the subprocess on the Prolog console, `pipe/1'
%%           must be used and the program must explicitly read the pipe
%%           and write to the console. Similarly for the input to the
%%           subprocess.
%% 
%%     `pipe(-STREAM)'
%%           A pipe is created which connects the Prolog stream STREAM to
%%           the standard stream of the new process. It must be closed
%%           using `close/1'; it is not closed automatically when the
%%           process dies.
%% 
%%      PID is the process identifier of the new process.
%% 
%%      On UNIX, the subprocess will be detached provided none of its
%%      standard streams is specified as `std'. This means it will not
%%      receive an interruption signal as a result of C being typed.

%% Note atom-based options:
%% `file_exists(+FILENAME, +PERMISSIONS)'
%%      FILENAME is the name of an existing file or directory which can be
%%      accessed according to PERMISSIONS.  PERMISSIONS is an atom, an
%%      integer (see access(2)), or a list of atoms and/or integers.  The
%%      atoms must be drawn from the list `[read,write,search,exists]'.
%% 

%% These, somewhat incompatible
%% `host_id(-HID)'
%%      HID is the unique identifier, represented by an atom, of the host
%%      executing the current SICStus Prolog process.
%% 
%% `host_name(-HOSTNAME)'
%%      HOSTNAME is the standard host name of the host executing the
%%      current SICStus Prolog process.
%% 
%% `pid(-PID)'
%%      PID is the identifier of the current SICStus Prolog process.

%% `kill(+PID, +SIGNAL)'
%%      Sends the signal SIGNAL to process PID.


:- comment(move_files(Files, Dir), "Move @var{Files} to directory
	@var{Dir} (note that to move only one file to a directory,
	@pred{rename_file/2} can be used).").

:- true pred move_files(+list(atm),+atm).

%% Need to do this better of course...
move_files([],_Dir).
move_files([File|Files],Dir) :-
	move_file(File,Dir),
	move_files(Files,Dir).

move_file(File,Dir) :-
	atom_concat([Dir,'/',File],Target),
	rename_file(File,Target).
	
:- comment(copy_files(Files, Dir), "Copy @var{Files} to directory
	@var{Dir} (note that to move only one file to a directory,
	@pred{rename_file/2} can be used).").

:- true pred copy_files(+list(atm),+atm).

%% Need to do this better of course...
copy_files([],_Dir).
copy_files([File|Files],Dir) :-
	copy_file(File,Dir),
	copy_files(Files,Dir).

%% Must be done using OS -- this is way too slow...
copy_file(File,Dir) :-
	file_exists(File),
	file_property(File, type(directory)),
	!,
	atom_concat([Dir,'/',File],Target),
	cat(File,Target).
copy_file(File,Target) :-
	cat(File,Target).
	
%% This one missing (simple to add?)
%% `system'
%%      Starts a new interactive default shell process.  The control is
%%      returned to Prolog upon termination of the shell process.
%% 

%% In sicstus, fails if return not zero, i.e., should be:
%% system(Path) :- system(Path, 0).?????
%% 
%% :- comment(system(Command), "Executes @var{Command} using the shell
%%         @apl{/bin/sh}.").
%% 
%% :- true pred system(+atm).
%% 
%% system(Path) :- system(Path, _Status).
%% 

%% `tmpnam(-FILENAME)'
%%      Interface to the ANSI C function tmpnam(3).  A unique file name is
%%      created and unified with FILENAME.

%% `wait(+PID, -STATUS)'
%%      Waits for the child process PID to terminate. The exit status is
%%      returned in STATUS. The function is similar to that of the UNIX
%%      function `waitpid(3)'.


:- push_prolog_flag(multi_arity_warnings,off).

:- pred symbolic_link(Source,Dir) # "Create a symbolic link in
   @var{Dir} pointing to file or directory @var{Source} (performs a
   copy in Windows).".

%% Needs to be implemented...
symbolic_link(Source,Dir) :-
	do(['cd ',Dir,' ; ln -s ',Source],nofail).

:- pred symbolic_link(Source,Dir,NewName) # "Create a symbolic link in
   @var{Dir} pointing to file or directory @var{Source} and give it
   name @var{NewName} (performs a copy in Windows).".

%% Needs to be implemented...
symbolic_link(Source,Dir,NewName) :-
	do(['cd ',Dir,' ; ln -s ',Source,' ',NewName],nofail).

:- pop_prolog_flag(multi_arity_warnings).

%% -------------------------------------------------------------------------
%% Very useful predicates
%% -------------------------------------------------------------------------

:- push_prolog_flag(multi_arity_warnings,off).

:- comment(ls(Dir,Pattern,FileList), "@var{FileList} is
        the unordered list of entries (files, directories, etc.) in
        @var{Directory} whose names match @var{Pattern}.If
        @var{Directory} does not exist @var{FileList} is empty.").

:- true pred ls(+atm,+pattern,-list(atm)).

ls(Dir,Pattern,SFileList) :-
	file_exists(Dir),
	!,
	directory_files(Dir,Files),
	filter_alist_pattern(Files,Pattern,FileList),
	sort(FileList,SFileList).
ls(_Dir,_Pattern,[]).


:- comment(ls(Pattern,FileList), 
        "@var{FileList} is the unordered list of entries (files,
        directories, etc.) in the current directory whose names match
        @var{Pattern} (same as
        @tt{ls('.',Pattern,FileList)}).").

:- true pred ls(+pattern,-list(atm)).

ls(Pattern,FileList) :-
	ls('.',Pattern,FileList).

:- pop_prolog_flag(multi_arity_warnings).

:- comment(filter_alist_pattern(UnFiltered,Pattern,Filtered),
        "@var{Filtered} contains the elements of @var{UnFiltered}
         which match with @var{Pattern}.").

:- true pred filter_alist_pattern(+list(atm),+pattern,-list(atm)).

filter_alist_pattern([],_,[]).
filter_alist_pattern([T|Ts],Pattern,O) :-
	match_pattern_pred(Pattern,T),
	!,
	O = [T|NTs],
	filter_alist_pattern(Ts,Pattern,NTs).
filter_alist_pattern([_T|Ts],Pattern,NTs) :-
	filter_alist_pattern(Ts,Pattern,NTs).

%% -------------------------------------------------------------------------

:- meta_predicate(-(goal)).

-(G) :- G, !.
-(G) :- warning_message("could not complete goal ~w",[G]).

%% Files can have paths
set_perms([],_Perms) :-
	!.
set_perms([File|Files],Perms) :-
	!,
	set_perms(File,Perms),
	set_perms(Files,Perms).
set_perms(File,perm(User,Group,Others)) :-
	(  file_exists(File)
	-> convert_permissions(User,Group,Others,P),
	   no_path_file_name(File,FileName),
	   atom_concat(Path,FileName,File),
	   (  Path = ''
	   -> chmod(File,P)
	   ;  working_directory(WD,WD),
	      cd(Path),
	      chmod(FileName,P),
	      cd(WD) )
	;  error_message("file ~w not found",[File]) ).

convert_permissions(U,G,O,P) :-
	valid_mode(U,NU),
	valid_mode(G,NG),
	valid_mode(O,NO),
	P is NU << 6 + NG << 3 + NO.

valid_mode( ''  , 0 ).
valid_mode( x   , 1 ).
valid_mode( w   , 2 ).
valid_mode( wx  , 3 ).
valid_mode( r   , 4 ).
valid_mode( rx  , 5 ).
valid_mode( rw  , 6 ).
valid_mode( rwx , 7 ).


del_endings_nofail([],_FileBase).
del_endings_nofail([Ending|Endings],FileBase) :-
	del_file_nofail(FileBase,Ending),
	del_endings_nofail(Endings,FileBase).

:- push_prolog_flag(multi_arity_warnings,off).

del_file_nofail(File) :-
	del_file_nofail(File,'').

del_file_nofail(FileBase,Ending) :-
	atom_concat([FileBase,Ending],File),
	file_exists(File,2), % exists and writeable
	!,
	delete_file(File). 
del_file_nofail(FileBase,Ending) :-
	atom_concat([FileBase,Ending],File),
	file_exists(File),   % exists but not writeable
	!,
	warning_message("Could not delete file ~w~w",[FileBase,Ending]).
del_file_nofail(_FileBase,_Ending).
%% 	!,
%% 	note_message("File ~w~w not deleted (does not exist)",
%% 	             [FileBase,Ending]).

:- pop_prolog_flag(multi_arity_warnings).

delete_files([]).
delete_files([File|Files]) :-
	del_file_nofail(File),
	delete_files(Files).


do([],_Fail) :-
	!.
do([A|As],Fail) :-
	!,
	atom_concat([A|As],Command),
	do_command(Command,Fail).
do(Command,Fail) :-
	do_command(Command,Fail).

do_command(Command,Fail) :-
	atom(Command),
	system(Command, ReturnCode),
	(  ReturnCode < 0
	-> error_message("~w returned code ~w",[Command,ReturnCode]),
	   Fail = nofail %% else fail
	;  true ).

cat(Sources,Target) :-
	(  file_exists(Target)
	-> delete_file(Target)
	;  true ),
	cat_append(Sources,Target).

cat_append(Sources,Target) :- 
	open(Target,append,O),
	(  cat_append_stream(Sources,O) 
	-> close(O) 
	;  close(O) ).

cat_append_stream([],_O) :- 
	!.
cat_append_stream([Source|Sources],O) :- 
	!,
	cat_append_stream_one(Source,O),
	cat_append_stream(Sources,O).
cat_append_stream(Source,O) :- 
	cat_append_stream_one(Source,O).
	
cat_append_stream_one(Source,O) :-
	atom(Source),
	Source \== [],
	!,
	open(Source,read,I),
	copy_stream(I,O),
	close(I).
	
copy_stream(I,O) :-
	get_code(I,Code),
	(  Code = -1 -> true ; put_code(O,Code), copy_stream(I,O) ).


readf(Files,List) :- 
	do_readf(Files,List,[]).

do_readf([],T,T) :- 
	!.
do_readf([Source|Sources],H,T) :- 
	!,
	readf_one(Source,H,T1),
	do_readf(Sources,T1,T).
do_readf(Source,H,T) :- 
	readf_one(Source,H,T).
	
readf_one(Source,H,T) :-
	atom(Source),
	Source \== [],
	!,
	open(Source,read,I),
	copy_stream_list(I,H,T),
	close(I).
	
copy_stream_list(I,H,T) :-
	get_code(I,Code),
	(  Code = -1 -> H=T ; H=[Code|R], copy_stream_list(I,R,T) ).




datime_string(T) :-
	datime(_,Year,Month,Day,Hour,Min,Sec,_WeekDay,_YearDay),
	datime_string(datime(Year,Month,Day,Hour,Min,Sec),T).

datime_string(datime(Year,Month,Day,Hour,Min,Sec),T) :-
	number_codes(Day,DayS), number_codes(Month,MonthS),
	number_codes(Year,YearS), number_codes(Hour,HourS),
	number_codes(Min,MinS), number_codes(Sec,SecS),
	list_concat([ DayS, "/", MonthS, "/", YearS, " ", HourS, ":",
	              MinS,  ":", SecS ], T).

%% :- meta_predicate(all_values(pred(1),?)).
%% 
%% all_values(PredName,Values) :-
%% 	findall(T,call_unknown(PredName(T)),Values).

%% Dynamic version...
all_values(PredName,Values) :-
	findall(T,call_unknown(PredName(T)),Values).

:- meta_predicate call_unknown(goal).

% Complication is so that flag is left as it was also upon failure.
call_unknown(G) :-
	prolog_flag(unknown,Old,fail),
	(  %% call(_:G), 
	   call(G),
	   prolog_flag(unknown,_,Old)
	;  prolog_flag(unknown,_,Old),
	   fail ).

no_tr_nl(L,NL) :- 
	append(NL,[10],L),
	!.
no_tr_nl(L,L).
		 
%% 

replace_strings_in_file(Ss,F1,F2) :-
	readf(F1,F1S),
	replace_strings(Ss,F1S,F2S),
	writef(F2S,F2).

:- push_prolog_flag(multi_arity_warnings,off).

%% Not really necessary... (simply open output and display...)
%% Also, there is file_to_string, etc. => unify

writef(Codes,File) :- 
	writef(Codes,write,File).

writef(Codes,_Mode,_File) :- 
	( \+ Codes = [_|_] ),
	!,
	throw(error(domain_error(string,Codes),writef/3-1)).
writef(_Codes,Mode,_File) :- 
	( \+ ( Mode = write ; Mode = append ) ),
	!,
	throw(error(domain_error(write_or_append,Mode),writef/3-2)).
writef(_Codes,_Mode,File) :- 
	( \+ atom(File); File = [] ),
	!,
	throw(error(domain_error(filename,File),writef/3-3)).
writef(Codes,Mode,File) :-
	open(File,Mode,O),
	codes_to_stream(Codes,O),
	close(O).

:- pop_prolog_flag(multi_arity_warnings).

codes_to_stream([],_O).
codes_to_stream([H|T],O) :-
	put_code(O,H),
	codes_to_stream(T,O).

replace_strings([],O,O).
replace_strings([S1-S2|Ss],I,O) :-
	replace_string(I,S1,S2,TO),
	replace_strings(Ss,TO,O).

replace_string(_I,S1,_S2,_TO) :-
	atom(S1),
	!,
	throw(error(domain_error(string,atom),replace_string/4-2)).
replace_string(_I,_S1,S2,_TO) :-
	atom(S2),
	!,
	throw(error(domain_error(string,atom),replace_string/4-3)).
replace_string(I,S1,S2,TO) :-
	do_replace_string(I,S1,S2,TO).

do_replace_string([],_S1,_S2,[]).
do_replace_string(I,S1,S2,O) :-
	match(S1,I,RI),
	!,
	append(S2,NO,O),
	do_replace_string(RI,S1,S2,NO).
do_replace_string([H|RI],S1,S2,[H|RO]) :-
	do_replace_string(RI,S1,S2,RO).


match([],I,I).
match([H|T],[H|IT],RI) :-
	match(T,IT,RI).
	

%%------------------------------------------------------------------------
%% VERSION CONTROL
%%------------------------------------------------------------------------
 
:- comment(version_maintenance,dir('../../version')).

:- comment(version(1*7+180,2002/01/25,20:08*39+'Hora est�ndar
   romance'), "Moved cyg2win/3 to system.pl ()").

:- comment(version(1*7+170,2002/01/03,18:17*59+'CET'), "Removed
   make_dirpath (real implementation now in system.pl) (MCL)").

:- comment(version(1*7+128,2001/10/26,18:27*47+'CEST'), "Bug fixed in
   cyg2win/3: when third argument was 'swap', the slash after the
   drive letter colon keept unchanged.  (Jesus Correas Fernandez)").


%%------------------------------------------------------------------------




