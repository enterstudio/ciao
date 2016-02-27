:- module(assrt_lib,
	[
	    set_libs/2,
	    get_code_and_norm_assertions/2,
	    get_code_and_related_assertions/5,
	    get_code_and_related_assertions_opts/6,
	    cleanup_code_and_related_assertions/0, 
	    check_code_and_assrt_syntax/1,
	    clause_read/7,
	    assertion_read/9,
	    assertion_body/7,

	    generate_asr_file/2,
	    read_asr_file/2,
	    rel_data/1,

	    print_assertions/1,
	    print_unformatted_assertions/1,

%% 	    normalize_assertions/1,
%% 	    normalize_assertions/2,
	    normalize_assertion/9,

	    norm_goal_prop/3, 
	    denorm_goal_prop/3

	],
	[
	    assertions, basicmodes, regtypes
	]).

:- comment(title,"Assertion processing library").

:- comment(author,"Manuel Hermenegildo").

:- comment(module,"

This module defines some predicates which are useful for writing
programs which process assertions (as defined in the @lib{assertions}
library). The exported predicates allow reading assertions in all
acceptable syntactic forms and converting them to a normalized format.

If you want to have access to some of the declarations read by the
predicates exported by this file it is also necessary to include the
library @lib{compiler/c_itf}.

").

:- comment(bug, "Should go into higher order properties and check the
   arguments for import/export also (and should probably look at the
   meta-predicate declarations for these)?").

% ISO-Prolog compatibility libraries
:- use_module(library(aggregates),[findall/3]).
:- use_module(library(dynamic)).  
:- use_module(library(read)).
:- use_module(library(write)).

% Other libraries
:- use_module(library(fastrw)).
:- use_module(library('assertions/assrt_write'),[write_assertion/6]).
:- use_module(library('assertions/assertions_props')).
:- use_module(library('assertions/c_itf_props')).
:- use_module(library('compiler/c_itf')).
:- use_module(library(ctrlcclean), 
      [ctrlc_clean/1,delete_on_ctrlc/2,ctrlcclean/0]).
:- use_module(library(errhandle)).  
:- use_module(library(messages)).
:- use_module(library(miscprops)).
%% :- use_module(library(formulae),[list_to_conj/2]).
:- use_module(library(lists),[append/3]).
:- use_module(library(system),
	[fmode/2,chmod/2,file_exists/1,file_exists/2,delete_file/1]).
:- use_module(library('compiler/translation'),
	[expand_clause/6,del_goal_trans/1,del_clause_trans/1]).

%% ---------------------------------------------------------------------------
:- pred asr_version(int) # "Contains a version number which identifies
   the @tt{.asr} files associated with this version of the assertion
   library. Should be changed every time changes are made which render
   the @tt{.asr} files incompatible, since this forces recomputation
   of all such files.".

asr_version('1.3.2').

%% ---------------------------------------------------------------------------
:- pred set_libs(go(OldLibs),go(NewLibs)) :: list(atom) * list(atom) 

# "The arguments contain library directories that will be used to
   locate files used as modules, syntax files, or which appear in
   include declarations. @var{OldLibs} is the current set of libraries
   and @var{NewLibs} the new one.".
%% ---------------------------------------------------------------------------

:- multifile library_directory/1.
:- dynamic library_directory/1.

set_libs(OldLibs,Libs) :-
	findall(D,retract(library_directory(D)),OldLibs),
	set_lib_dirs(Libs).

set_lib_dirs([]).
set_lib_dirs([H|T]) :- 
	assertz(library_directory(H)),
	set_lib_dirs(T).

%% ---------------------------------------------------------------------------
:- pred check_code_and_assrt_syntax(in(I)) :: filename
 
# "This predicate is useful for checking the syntax of the code and
   assertions in a file, as well as imports and exports.  Full
   (semantic) assertion checking must be done with the preprocessor.".
%% ---------------------------------------------------------------------------

check_code_and_assrt_syntax(I):-
	get_code_and_related_assertions(I,_M,_Base,_Suffix,_Dir),
	%% So that it can be used over and over again interactively
        cleanup_code_and_related_assertions.

%% ---------------------------------------------------------------------------
:- pred cleanup_code_and_related_assertions/0
 
# "Cleans up data asserted by assertion/code reader/normalizer.".
%% ---------------------------------------------------------------------------

cleanup_code_and_related_assertions :-
        cleanup_c_itf_data,
	retractall_fact(clause_read(_,_,_,_,_,_,_)),
	retractall_fact(assertion_read(_,_,_,_,_,_,_,_,_)).

%% ---------------------------------------------------------------------------
:- pred get_code_and_related_assertions(
	in(I),     go(M),    go(Base), go(Suffix), go(Dir) )
   ::   filename * moddesc * atom    * atom      * atom 
 

# "This is the main entry point to the @concept{assertion
   reader/normalizer}. Reads all declarations and code in @var{I} and
   leaves it asserted in the database, in the format defined in
   @lib{'compiler/c_itf'}. Clauses are stored in @pred{clause_read/7}.

   Also, it reads and normalizes @em{all} assertions in this file and
   all related files, leaving them asserted in @pred{assertion_read/9}
   facts. If up to date @tt{.asr} files exist for this or any of the
   related files, the assertion information is read directly from such
   @tt{.asr} files. @cindex{.asr files} Otherwise, the @tt{.pl} file
   is read and an up to date @tt{.asr} file is generated containing
   all assertions in the @tt{.pl} file, normalized and stored as
   @pred{assertion_read/9} facts.

   @var{M} is the name of the module defined by the file. @var{Base} is
   the absolute name of the file @var{I} but with no
   suffix. @var{Suffix} is the file suffix (e.g.,
   '@tt{.pl}'). @var{Dir} is the directory part of the filename (with
   no @tt{/} at the end).

   Since this predicate is intended for gathering file information for
   purposes which can be other than compilation to executable code
   (e.g., generating documentation or in the preprocessor) this
   predicate catches errors and proceeds in cases where file
   processing (e.g., during actual compilation) might normally abort.".

:- pred get_code_and_related_assertions_opts(
	in(I),     in(Opts),    go(M),    go(Base), go(Suffix), go(Dir) )
   ::   filename * list(atom) * moddesc * atom    * atom      * atom 

# "Version which accepts some options in @var{Opts}. In particular,
   @tt{'-v'} produces verbose output for debugging. Also passes
   on the options in @var{Opts} to pass two of the assertion
   normalizer. ".

%% ---------------------------------------------------------------------------


get_code_and_related_assertions(I,M,Base,Suffix,Dir):-
	get_code_and_related_assertions_opts(I,[],M,Base,Suffix,Dir).

get_code_and_related_assertions_opts(I,Opts,M,Base,Suffix,Dir):-
	(  ( prolog_flag(verbose_compilation,on,on) ; member('-v',Opts) )
	-> Verb = verbose
	;  Verb = quiet ),
        error_protect(ctrlc_clean(
		process_files_from(I, asr, any, 
		                   process_file_assertions(I,Verb,Opts), 
                                   false, false, needs_processing(I,Verb))
				 )),
	get_file_data(I,Base,M,Suffix,Dir).

get_code_and_norm_assertions(Base,M):-
	process_file_assertions_(Base,[]),
	defines_module(Base,M).

get_file_data(I,Base,M,Suffix,Dir):-
	substract_pl(I,_Main,Suffix),
        base_name(I,Base),
	defines_module(Base,M),
        file_data(Base, _PlName, Dir).

substract_pl(FPL,F,'.pl') :-
	atom_concat(F,'.pl',FPL),
	!. %% it ends in .pl
%% else, it does not end in .pl
substract_pl(F,F,'').


%% ---------------------------------------------------------------------------

:- pred clause_read(Base, Head, Body, VarNames, Source, Line0, Line1)

   # "After calling @pred{get_assertions_and_code/5} this predicate
      contains the clauses in the file. The format is the same as that
      of @pred{clause_of/7} in @lib{c_itf}".

:- data clause_read/7.

%% ---------------------------------------------------------------------------

:- pred needs_processing/3 # "Controls if a given file needs to be
   fully processed by the assertion reader or it suffices to read its
   @tt{.asr} file. This is controlled by the modification dates of the
   @tt{.pl} and @tt{.asr} files. It also depends on whether it is the
   main file (for which the code is always read) or a file used by
   it.".

%% Main file will be processed (read) even if it hasn't changed.
needs_processing(Base,I,_Verb) :- 
	base_name(I,Base),
	% format("*** needs_proc: Will process fully (later) ~w.asr~n",[Base]),
	!.
%% Aux file, valid .asr file, valid version: read .asr data
needs_processing(Base,_I,Verb) :- 
	\+ old_file_extension(Base, '.asr'),
	read_asr_file_(Base,Verb), % Fails if wrong version!
	!,
	fail.
%% Aux file, invalid .asr file or invalid version: generate .asr data (later).
needs_processing(_Base,_I,_Verb) :- 
	% format("*** needs_proc: Should generate (later) ~w.asr~n",[Base]),
	true.

%% ---------------------------------------------------------------------------

:- pred read_asr_file/2 # "Reads the data in the .asr file. Fails if
   version is different from current version (so that .asr will be
   regenerated).".

read_asr_file(Base,V) :-
	( ( prolog_flag(verbose_compilation,on,on) ; V=='-v' )
	-> Verb = verbose
	;  Verb = quiet ),
	retractall_fact(rel_data(_)),
	read_asr_file_(Base,Verb).

read_asr_file_(Base,Verb) :-
	atom_concat(Base,'.asr',AsrName),
        open(AsrName, read, Stream),
        current_input(CI),
        set_input(Stream),
        ( asr_version(V),
          read(v(V)), 
	  !
        ; verb_message(Verb,['{Old version in ',AsrName,'}']),
	  set_input(CI),
          close(Stream),
          fail
        ),
%%        working_directory(OldDir, Dir),
        verb_message(Verb,['{Reading ',AsrName]),
        read_asr_data_loop(Verb),
        set_input(CI),
        close(Stream),
        verb_message(Verb,'}').
%%        working_directory(_, OldDir).


%% read/1 version
%% read_asr_data_loop :-
%% 	repeat,
%% 	fast_read(X),
%% 	( X == end_of_file
%% 	; assertz_fact(X), % asserts clauses of assertion_read/9
%% 	  % format("*** Asserted: ~w~n",[X]),
%% 	  fail ).

%% fast_read/1 version (just fails at end of file)
read_asr_data_loop(Verb) :-
	(  fast_read(X)
	-> assertz_fact(X), % asserts clauses of assertion_read/9
	                    % ...and now also rel_data/1 (PBC)
	   % verb_message(Verb,[ 'Asserted: ',X]),
	   read_asr_data_loop(Verb)
	;  true ).

%% ---------------------------------------------------------------------------

:- pred process_file_assertions/4 # "Processes the assertions in a
   file, generating the corresponding @tt{.asr} file. In the case of the
   main file, also reads in the code.".

%% Main file
process_file_assertions(Base,I,_Verb,Opts) :- 
	base_name(I,Base),
	!,
	process_file_assertions_(Base,Opts).
process_file_assertions(Base,_I,Verb,_Opts) :-
%% Other files
	defines_module(Base,M),
	normalize_assertions(M,Base),
	generate_asr_file(Base,Verb,related).

process_file_assertions_(Base,Opts):-
	c_itf:comp_defines(Base), %% force generation of defines/5 data
	defines_module(Base,M),
	normalize_assertions(M,Base,Opts),
	%% We do not generate the asr file for main (it could be only 
        %% partly normalized due to -modes option
	%  generate_asr_file(Base,Verb,main), %% MH2
        %% c_itf erases the clauses, so we must save them here 
        %% (or do the processing inside c_itf...)
	%% Second translation -PBC
        activate_translation(Base,M,add_clause_trans),
        activate_translation(Base,M,add_goal_trans),
        expand_clause(0,0,M,_,_,_), % Translator initialization
	save_clause_of(Base,M),
	%% deactivate translations
	del_goal_trans(M),
	del_clause_trans(M).

save_clause_of(Base,M):-
	clause_of(Base,Head,Body,VarNames,Source,Line0,Line1),
        ( number(Head)
	-> H=Head,
	   B=Body
	 ; % do the "second expansion"
%	   io_aux:message(['{Original: ',(Head:-Body)]),
	   expand_clause(Head,Body,M,VarNames,H,B)
%	   io_aux:message(['{Expanded: ',(H:-B)])
	),
	% one more patch!!
	( var(VarNames) -> VarNames=[] ; true ),
	assertz_fact(clause_read(Base,H,B,VarNames,Source,Line0,Line1)),
	fail.
save_clause_of(_Base,_M).

:- push_prolog_flag(multi_arity_warnings,off).

generate_asr_file(Base,V) :-
	( ( prolog_flag(verbose_compilation,on,on) ; V=='-v' )
	-> Verb = verbose
	;  Verb = quiet ),
	generate_asr_file(Base,Verb,related).

:- pred generate_asr_file/3 # "Does the actual generation of the
   @tt{.asr} file. Only assertions related to exported predicates are
   saved. Assertions for non-exported predicates remain in the database
   only for the main file (@tt{main} in fourth argument).".

generate_asr_file(Base,Verb,Component) :-
	atom_concat(Base,'.asr',AsrName),
	verb_message(Verb,['{Generating ',AsrName]),
	file_data(Base, PlName, Dir),
        fmode(PlName, Mode),
        prolog_flag(fileerrors, OldFE, off),
        ( stream_of_file(AsrName, Dir, Stream, Ref) ->
            current_output(CO),
            set_output(Stream),
            asr_version(V),
            display_term(v(V)),
            write_asr_data_of(Base,Component),
            write_rel_data,
            set_output(CO),
            close(Stream),
            chmod(AsrName, Mode),
            erase(Ref)
        ;   message(['{In ',PlName]),
	    message(warning, ['cannot create ',AsrName]),
	    message('}'),
	    read_asr_file_(Base,Verb)
	),
	verb_message(Verb,'}'),
        set_prolog_flag(fileerrors, OldFE).

:- pop_prolog_flag(multi_arity_warnings).

%% Among other things, makes sure unfinished files are deleted on ctrlc
stream_of_file(Path, Dir, Stream, Ref) :-
        file_exists(Dir, 2), % Write permission
        ( file_exists(Path) -> delete_file(Path) ; true ),
        delete_on_ctrlc(Path, Ref),
        open(Path, write, Stream).

%% Normalization has occurred by now
write_asr_data_of(Base,Component) :-
	defines_module(Base,M),
	collect_prop_defs(Base,M,Component), %% MH1
	prolog_flag(write_strings, Old, on),
	print_exported_assertions_as_facts(Base,M,Component),
	set_prolog_flag(write_strings, Old).

%% Extra data for interfacing modules:
:- data rel_data/1.

write_rel_data:-
	rel_data(X),
	fast_write(rel_data(X)),
	fail.
write_rel_data.

%% user files: all assertions exported
print_exported_assertions_as_facts(Base,user(F),_Component) :-
	!,
	( assertion_read(PD,user(F),Status,Type,Body,Dict,S,LB,LE),
%%	  writeq(assertion_read(PD,user(F),Status,Type,Body,Dict,S,LB,LE)),
%%	  write(' .'), nl,
	  fast_write(assertion_read(PD,user(F),Status,Type,Body,Dict,S,LB,LE)),
	  fail
	; true ),
	( clause_of(Base,0,comment(P,CBody),VNs,S,L0,L1),
	  ( P = Fu/A ; functor(P,Fu,A) ),
	  defines_pred(Base,Fu,A),
	  fast_write(
		     clause_read(Base,0,comment(P,CBody),VNs,S,L0,L1)),
	  assertz_fact(
		     clause_read(Base,0,comment(P,CBody),VNs,S,L0,L1)),
	  fail
	; true ).
%% else, module: check for exports
print_exported_assertions_as_facts(Base,M,Component) :-
	( assertion_read(PD,M,Status,Type,Body,Dict,S,LB,LE),
	  functor(PD,F,A),
	  ( exports(Base, F, A, _DefType, _Meta)
	  ->
%%	  writeq(assertion_read(PD,M,Status,Type,Body,Dict,S,LB,LE)),
%%	  write(' .'), nl,
	     fast_write(assertion_read(PD,M,Status,Type,Body,Dict,S,LB,LE))
	   ; delete_assertion_if_not_main_file(Component,
	                 assertion_read(PD,M,Status,Type,Body,Dict,S,LB,LE))
	  ),
	  fail
	; true ),
	( clause_of(Base,0,comment(P,CBody),VNs,S,L0,L1),
	  ( P = Fu/A ; functor(P,Fu,A) ),
	  exports(Base,Fu,A,_DefType,_Meta),
	  fast_write(
		     clause_read(Base,0,comment(P,CBody),VNs,S,L0,L1)),
	  assertz_fact(
		     clause_read(Base,0,comment(P,CBody),VNs,S,L0,L1)),
	  fail
	; true ),
	print_reexported_assertions_as_facts(Base,M).

delete_assertion_if_not_main_file(main,_Assertion).
delete_assertion_if_not_main_file(related,Assertion):-
	retract_fact(Assertion).


%% :- data pending_reexport/4.

%% special case: take care also of assertions reexported by a module!
print_reexported_assertions_as_facts(Base,M) :-
	( exports(Base, F, A, _DefType, _Meta),
	  reexported_from(Base,M,F,A,MI),
	  functor(PD,F,A),
	  (  assertion_read(PD,MI,Status,Type,Body,Dict,S,LB,LE)
	  -> 
	     %% writeq(assertion_read(PD,M,Status,Type,Body,Dict,S,LB,LE)),
	     %% write(' .'), nl, 
	     fast_write(assertion_read(PD,M,Status,Type,Body,Dict,S,LB,LE))
	  ;  true
	     %% MH2 Actually, this seems to be working now
	     %% message(['{In ',Base,'.pl']),
	     %% message(warning,['pending reexport for ',F,'/',A,' from ',MI]),
	     %% %% asserta_fact(pending_reexport(PD,Base,M,MI))
   	     %% message('}')
	  ),
	  fail
	; true ).

%% Only one solution needed
reexported_from(Base,M,F,A,MI) :- 
	\+ defines_pred(Base, F, A),
	imports(M, MI, F, A),
	!.

imports(M, MI, F, A):- imports(M, MI, F, A, _).

:- set_prolog_flag(multi_arity_warnings, off).

verb_message(verbose,Message) :-
	io_aux:message(Message).
verb_message(quiet,_Message).

verb_message(verbose,Type,Message) :-
	io_aux:message(Type,Message).
verb_message(quiet,_Type,_Message).

:- set_prolog_flag(multi_arity_warnings, on).

%% ---------------------------------------------------------------------------
%% Made behaviour depend on whether it is main file or component 
%% Avoids repetition for main file MH1
:- pred collect_prop_defs(Base,M,Component) : moddesc(M)
   # "This predicate collects clauses defining properties that are exported
      by module @var{M} and leaves them as @pred{clause_read/7} facts, and
      writing those facts to the @tt{.asr} file.".

collect_prop_defs(Base,M,Component):- 
	assertion_read(PD,M,_AStatus,prop,_ABody,_ADict,_S,_LB,_LE),
	% Check that the prop is exported
        functor(PD,F,A),
	exports(Base, F, A, _DefType, _Meta),
	clause_of(Base,PD,Body,Dict,S,LB,LE), 
	%% If main, all *clauses* have already been asserted!
	(  Component = main
	-> true 
	;  assertz_fact(clause_read(Base,PD,Body,Dict,S,LB,LE)) ),
	fast_write(clause_read(Base,PD,Body,Dict,S,LB,LE)),
	fail.
collect_prop_defs(_Base,_M,_Component). 

%% ---------------------------------------------------------------------------
:- pred normalize_assertions(moddesc) # "This predicate calls
   @pred{normalize_assertions_pass_one/1} and then
   @pred{normalize_assertions_pass_two/1}, thus leaving all assertions
   in the database in fully normalized form, as
   @pred{assertion_read/9} facts.".
%% ---------------------------------------------------------------------------

:- push_prolog_flag(multi_arity_warnings,off).

normalize_assertions(M,Base):-
	normalize_assertions(M,Base,[]).

%% ---------------------------------------------------------------------------
:- pred normalize_assertions(moddesc,Options) # "Same as
   @pred{normalize_assertions/1} except that it passes on the options
   in @var{Opts} to pass two.".
%% ---------------------------------------------------------------------------

normalize_assertions(M,Base,Opts):-
	normalize_assertions_pass_one(M,Base),
	normalize_assertions_pass_two_opts(M,Opts).

:- pop_prolog_flag(multi_arity_warnings).

%% ---------------------------------------------------------------------------
:- pred normalize_assertion(M,Assrt,PD,AStatus,AType,NABody,S,LB,LE) 

:: moddesc * term * term * assrt_status * assrt_type * assrt_body
   * atm * int * int

# "Normalizes one assertion (see @pred{assertion_read/9} and
   @pred{normalize_assertions/1}.".
%% ---------------------------------------------------------------------------

normalize_assertion(M,Assrt,PD,AStatus,AType,NABody,S,LB,LE) :-
	normalize_one_assertion_pass_one(
                  M,Assrt,PD,AStatus,AType,ABody,S,LB,LE),
	% modedefs have already been transformed -- leave as is 
        (  AType = modedef 
	-> NABody = ABody
	;  normalize_properties(ABody,NABody,M,_Functor,[],AType,S,LB,LE) ).

%% ---------------------------------------------------------------------------
:- pred normalize_assertions_debug(M) :: moddesc # "Same as
   @pred{normalize_assertions/0} but it reports on the normalization
   process by printing all assertions after normalization passes one
   and two. If @var{M} is instantiated only information on module
   @var{M} is printed. Otherwise information for all modules is
   printed.".
%% ---------------------------------------------------------------------------

normalize_assertions_debug(M,Base) :-
	normalize_assertions_debug_opts(M,Base,[]).

normalize_assertions_debug_opts(M,Base,Opts) :-
	prolog_flag(write_strings, Old, on),
	io_aux:message(['{Normalizing assertions in ',M,' (pass one)']),
	normalize_assertions_pass_one(M,Base),
	io_aux:message('}'),
	print_unformatted_assertions(_M),
	io_aux:message(['{Normalizing assertions in ',M,' (pass two)']),
	normalize_assertions_pass_two_opts(M,Opts),
	io_aux:message('}'),
        current_output(CI),
        set_output(user_error),
	print_unformatted_assertions(_M),
        set_output(CI),
	set_prolog_flag(write_strings, Old).


%% ---------------------------------------------------------------------------
:- pred print_assertions(M) :: moddesc # "Prints the assertions stored
   in the database as @pred{assertion_read/9} facts, performing some
   pretty-printing and simplification (e.g., eliminating empty
   fields). If @var{M} is instantiated, only information on module
   @var{M} is printed. Otherwise information for all modules is
   printed.".
%% ---------------------------------------------------------------------------

print_assertions(M) :-
	io_aux:message('{Printing assertions read '),
	assertion_read(PD,M,Status,Type,Body,Dict,_S,_LB,_LE),
	%% Using now version in library(assrt_write)
	write_assertion(PD,Status,Type,Body,Dict,status),
	fail.
print_assertions(_M) :-
	io_aux:message('}').

%% ---------------------------------------------------------------------------
:- pred print_unformatted_assertions(M) :: moddesc # "Prints the
   assertions stored in the database as @pred{assertion_read/9} facts,
   in a raw format (no attempt is made to simplify the assertions). If
   @var{M} is instantiated, only information on module @var{M} is
   printed. Otherwise information for all modules is printed.".
%% ---------------------------------------------------------------------------

print_unformatted_assertions(M) :-
	io_aux:message('{Printing assertions read'),
	assertion_read(PD,M,Status,Type,Body,Dict,_S,_LB,_LE),
	%% Using now version in library(assrt_write)
	local_write_assertion(PD,Status,Type,Body,Dict,status,M),
	fail.
print_unformatted_assertions(_M) :-
	io_aux:message('}').

local_write_assertion(PD,Status,Type,Body,_Dict,_Flag,M) :-
	assertion_body(PD,DP,CP,AP,GP,CO,Body),
	io_aux:message(['(in module ',M,':)']),
	io_aux:message([':- ',Status,' ',Type,' ',PD,
                       ' :: ',DP,' : ',CP,' => ',AP,' + ',GP,' # ',CO]).

%% ---------------------------------------------------------------------------
:- pred normalize_assertions_pass_one(moddesc) # "For each assertion
   normalizes the assertion body (but not the properties inside or
   those properties and modes which appear in the head). The predicate
   descriptor (both that in the assertion body and the first argument
   of @pred{assertion_read/9}) is partially normalized in that
   @tt{functor/arity} formats are expanded into terms, but modes and
   properties in arguments are left for the second pass (i.e.,
   @tt{p(X,+)} may be present, but not @tt{p/2}). However, if the
   assertion is a @tt{modedef} then it is fully normalized at this
   time (including body properties, which are normalized but not
   checked) so that @pred{normalize_assertions_pass_two/1} can use it
   later while normalizing other assertions. The (partially)
   normalized assertion is left asserted as an @pred{assertion_read/9}
   fact.".
%% ---------------------------------------------------------------------------

normalize_assertions_pass_one(M,Base) :-
%	defines_module(Base,M),
	(  %% Normalize all assertions in this module
	   clause_of(Base,1,Assrt,Dict,S,LB,LE), 
	   normalize_one_assertion_pass_one(
		M,Assrt,PD,AStatus,AType,NNAss,S,LB,LE),
	   assertz_fact(assertion_read(PD,M,AStatus,AType,NNAss,Dict,S,LB,LE)),
 	   fail
	;  true ).
	
normalize_one_assertion_pass_one(M,Assrt,PD,AStatus,AType,NNAss,S,LB,LE) :-
	normalize_if_assertion_body(M,Assrt,AStatus,AType,NAss,S,LB,LE),
	assertion_body(PD,_DP,_CP,_SP,_GP,_CO,NAss),
	(  AType = modedef
	-> %% modedef body props have to be normalized at this time!
	   normalize_modedef_properties(NAss,NNAss,M,S,LB,LE)
	;  NNAss = NAss
	).
%% Changed back so that it fails for decls which should not be recognized 
%% as assertions! MH

%% ---------------------------------------------------------------------------
:- pred assertion_read(Goal,M,Status,Type,Body,Dict,Source,LB,LE)

:: ( moddesc(M), assrt_status(Status), assrt_type(Type),
     assrt_body(Body), dictionary(Dict), int(LB), filename(Source),
     int(LE) )

# "Each fact represents that an assertion for @var{Goal} has been read
   in module @var{M}, which has status @var{Status} and is of type
   @var{Type}.  @var{Body} is the actual body of the
   assertion. @var{Dict} contains the names of the variables which
   appear in the assertion. @var{Source} is the file in which the
   assertion appears (treats included files correctly). @var{LB} and
   @var{LE} are the first and last line numbers in this source file in
   which the assertion appears (if the source is not available or has
   not been read @var{LB}=@var{LE}=0).  @var{Goal} may be normalized
   or not, i.e., it may contain modes or properties, but it is always
   a term of the same functor and arity as the predicate it represents
   (i.e., it is not in Functor/Arity format). @var{Body} is always
   normalized (but the properties or property conjunctions inside may
   not -- see @pred{normalize_assertions_pass_one/1} and
   @pred{normalize_assertions_pass_two/1}.".
%% ---------------------------------------------------------------------------

:- data assertion_read/9. 

%% ---------------------------------------------------------------------------
:- pred normalize_assertions_pass_two/1 # "For each assertion left by
   @pred{normalize_assertions_pass_one/1} (except for @tt{modedef}
   mode declarations, which are left as is) extracts all head
   properties and modes, normalizes all body properties, adds the head
   properties and the properties implied by the head modes to the body
   properties, and checks that a definition (or, at least, a
   declaration) is available for each property (issuing a warning
   otherwise). The old (partially) normalized assertion is eliminated
   and the fully normalized assertion is left asserted (again as an
   @pred{assertion_read/9} fact) in its place. Body property
   conjunctions are (currently) represented as lists to facilitate
   processing.".

:- pred normalize_assertions_pass_two_opts/2 # "Same as
   @pred{normalize_assertions_pass_two/1} except that it admits options
   in the second argument.".
%% ---------------------------------------------------------------------------

normalize_assertions_pass_two(M) :-
	normalize_assertions_pass_two_opts(M,[]).

normalize_assertions_pass_two_opts(M,Opts) :-
	( assertion_read(PD,M,AStatus,AType,NAss,Dict,S,LB,LE),
	  %% modedefs already transformed in pass one -- leave as is
	  AType \== modedef,
	  retract_fact(assertion_read(PD,AM,AStatus,AType,NAss,Dict,S,LB,LE)),
	  normalize_properties(NAss,NPropAss,M,F/A,Opts,AType,S,LB,LE),
	  check_body_properties(M,AM,F,A,NPropAss,S,LB,LE),
	  assertion_body(NPD,_,_,_,_,_,NPropAss),
	  assertz_fact(
	     assertion_read(NPD,AM,AStatus,AType,NPropAss,Dict,S,LB,LE)),
	  fail
	; true ).

%% -------------------------------------------------------------------------
:- pred normalize_if_assertion_body(
   M,Ass,AssrtStatus,AssrtType,NBodyAndHead,S,LB,LE)
:: moddesc * assrt_body * assrt_status * assrt_type 
   * assrt_body * atm * int * int

# "The assertion-related declaration @var{U} is in canonical format in
   @var{N}.".
%% -------------------------------------------------------------------------

normalize_if_assertion_body(M,Ass,AssrtStatus,AssrtType,NBodyAndHead,S,LB,LE):-
	normalize_status_and_type(Ass,AssrtStatus,AssrtType,UBody),
	%% At this point it has been recognized as an assertion...
        %% Check for old comments (using ;):
        (  UBody = (_;_) 
	-> warning_message(loc(S,LB,LE),
	     "old comment syntax (assertion ignored)",[]),
	   %% More verbose version...
	   %% warning_message(loc(S,LB,LE),
	   %%  "old comment syntax in ~w assertion body: ~w (assrt ignored)",
	   %%  [AssrtType,Ass]),
	   fail
        ;  normalize_assertion_body(M,AssrtType,UBody,NBodyAndHead,S,LB,LE) ).

normalize_assertion_body(_M,AssrtType,UBody,NBodyAndHead,_S,_LB,_LE) :-
	norm_body(UBody,Format,NBody),
	assertion_format(AssrtType,Format), % Do not put before norm_body!
	!,
	assertion_body(PD,DP,CP,AP,GP,CO,NBody),
	%% Put all heads  in f(var,..,var) form
	(  PD = F/A 
	-> functor(NPD,F,A)
	;  NPD=PD ),
	assertion_body(NPD,DP,CP,AP,GP,CO,NBodyAndHead).
normalize_assertion_body(M,AssrtType,UBody,_NBodyAndHead,S,LB,LE) :-
 	error_message(loc(S,LB,LE),"~w assertion syntax in module ~w: ~w",
                      [AssrtType,M,UBody]),
	fail.
	
% For debugging...
report_assertion_body(ND) :-
	prolog_flag(write_strings, Old, on),
	assertion_body(PD,DP,CP,AP,GP,CO,ND),
	simple_message("***~n",[]),
	simple_message("Predicate = ~w~n",[PD]),
	simple_message("Cmpt Info = ~w~n",[DP]),
	simple_message("Call Info = ~w~n",[CP]),
	simple_message("Answ Info = ~w~n",[AP]),
	simple_message("Othe Info = ~w~n",[GP]),
	simple_message("Comment   = ~s~n",[CO]),
	set_prolog_flag(write_strings, Old).

%% ---------------------------------------------------------------------------
:- pred normalize_status_and_type(
  +assrt_body,go(assrt_status),go(assrt_type),go(assrt_body)).
%% ---------------------------------------------------------------------------

normalize_status_and_type(Ass,AssrtStatus,AssrtType,UBody) :- 
	Ass  =.. [AssrtType,UBody],
	assrt_type(AssrtType),
	default_assrt_status(AssrtType,AssrtStatus),
	!.
normalize_status_and_type(Ass,AssrtStatus,AssrtType,UBody) :- 
	Ass  =.. [AssrtType,AssrtStatus,UBody],
	assrt_type(AssrtType),
	nonvar(AssrtStatus),
	assrt_status(AssrtStatus),
	!.
normalize_status_and_type(Ass,AssrtStatus,AssrtType,UBody) :- 
	Ass  =.. [AssrtType,AssrtStatus,UBody],
	assrt_type(AssrtType),
	var(AssrtStatus),
	default_assrt_status(AssrtType,AssrtStatus),
	!.

%% ---------------------------------------------------------------------------
:- pred default_assrt_status(+assrt_type,-assrt_status) 
# "Defines the status to be used for a given assertion type, if an
   assertion status is not specified explicitly.".
%% ---------------------------------------------------------------------------

default_assrt_status(entry,   true ) :- !. %% ???
default_assrt_status(modedef, true ) :- !. %% ???
default_assrt_status(X,       check) :-
	assrt_type(X),
	!.

%% ---------------------------------------------------------------------------
:- pred assertion_format(assrt_type(AssrtType),assrt_format_code(Code)) 
# "@var{Code} describes an admissible format in which assertions of
   the class @var{AssrtType} can be written.".
%% ---------------------------------------------------------------------------

%% Admissible assertion formats:
assertion_format(pred,    X) :- assrt_format_code(X).
assertion_format(decl,    X) :- assrt_format_code(X). %% ?
assertion_format(prop,    X) :- assrt_format_code(X). 
%% Obsolete: delete eventually...
%% assertion_format(type,    t).
%% Not needed any more...
%%assertion_format(type,    g). %% Added for now to put typedef there...
%% assertion_format(compat,  d). %% Not using these as basic any more?!
assertion_format(calls,   c).
assertion_format(success, s).
assertion_format(comp,    g).
%% These to become obsolete?
assertion_format(entry,   c).
assertion_format(entry,   t).
%% Not an assertion any more, but a status instead
%% assertion_format(trust,   X) :- assrt_format_code(X).
assertion_format(modedef, X) :- assrt_format_code(X).

:- prop assrt_format_code(X) + regtype
   # "@var{X} is a designator for an assertion format.".

assrt_format_code(p).
assrt_format_code(d).
assrt_format_code(c).
assrt_format_code(s).
assrt_format_code(g).
assrt_format_code(t).

%% ---------------------------------------------------------------------------
:- pred norm_body(B,NB) 
   # "@var{NB} is a normalized assertion body corresponding to the
     unnomalized assertion body @var{B}.".
%% ---------------------------------------------------------------------------

%% MH: Added new assertions for transition. Marked as %N
%% MH: No comments allowed now in basic assertions (difficult to document).

% ------------ A  B   C  D  E --FormatId--------------------------- %ABCDE
norm_body((PD::DP:CP=>AP+GP#CO),p,(PD::DP  :CP  =>AP  +GP  #CO)):-!.%11111%N
norm_body((PD::DP:CP=>AP+GP   ),p,(PD::DP  :CP  =>AP  +GP  #"")):-!.%11110
norm_body((PD::DP:CP=>AP   #CO),p,(PD::DP  :CP  =>AP  +true,CO)):-!.%11101%N%N
norm_body((PD::DP:CP=>AP      ),p,(PD::DP  :CP  =>AP  +true#"")):-!.%11100
norm_body((PD::DP:CP    +GP#CO),p,(PD::DP  :CP  =>true+GP  #CO)):-!.%11011%N
norm_body((PD::DP:CP    +GP   ),p,(PD::DP  :CP  =>true+GP  #"")):-!.%11010
norm_body((PD::DP:CP       #CO),p,(PD::DP  :CP  =>true+true#CO)):-!.%11001%N
norm_body((PD::DP:CP          ),p,(PD::DP  :CP  =>true+true#"")):-!.%11000
norm_body((PD::DP   =>AP+GP#CO),p,(PD::DP  :true=>AP  +GP  #CO)):-!.%10111%N
norm_body((PD::DP   =>AP+GP   ),p,(PD::DP  :true=>AP  +GP  #"")):-!.%10110
norm_body((PD::DP   =>AP   #CO),p,(PD::DP  :true=>AP  +true#CO)):-!.%10101%N
norm_body((PD::DP   =>AP      ),p,(PD::DP  :true=>AP  +true#"")):-!.%10100
norm_body((PD::DP       +GP#CO),p,(PD::DP  :true=>true+GP  #CO)):-!.%10011%N
norm_body((PD::DP       +GP   ),p,(PD::DP  :true=>true+GP  #"")):-!.%10010
norm_body((PD::DP          #CO),p,(PD::DP  :true=>true+true#CO)):-!.%10001%N
norm_body((PD::DP             ),d,(PD::DP  :true=>true+true#"")):-!.%10000
norm_body((PD    :CP=>AP+GP#CO),p,(PD::true:CP  =>AP  +GP  #CO)):-!.%01111%N
norm_body((PD    :CP=>AP+GP   ),p,(PD::true:CP  =>AP  +GP  #"")):-!.%01110
norm_body((PD    :CP=>AP   #CO),s,(PD::true:CP  =>AP  +true#CO)):-!.%01101%N
norm_body((PD    :CP=>AP      ),s,(PD::true:CP  =>AP  +true#"")):-!.%01100
norm_body((PD    :CP    +GP#CO),p,(PD::true:CP  =>true+GP  #CO)):-!.%01011%N
norm_body((PD    :CP    +GP   ),g,(PD::true:CP  =>true+GP  #"")):-!.%01010
norm_body((PD    :CP       #CO),p,(PD::true:CP  =>true+true#CO)):-!.%01001%N
norm_body((PD    :CP          ),c,(PD::true:CP  =>true+true#"")):-!.%01000
norm_body((PD       =>AP+GP#CO),p,(PD::true:true=>AP  +GP  #CO)):-!.%00111%N
norm_body((PD       =>AP+GP   ),p,(PD::true:true=>AP  +GP  #"")):-!.%00110
norm_body((PD       =>AP   #CO),p,(PD::true:true=>AP  +true#CO)):-!.%00101%N
norm_body((PD       =>AP      ),s,(PD::true:true=>AP  +true#"")):-!.%00100
norm_body((PD           +GP#CO),p,(PD::true:true=>true+GP  #CO)):-!.%00011%N
norm_body((PD           +GP   ),g,(PD::true:true=>true+GP  #"")):-!.%00010
norm_body((PD              #CO),p,(PD::true:true=>true+true#CO)):-!.%00001%N
norm_body((PD                 ),t,(PD::true:true=>true+true#"")):-!.%00000
% ----------------------------------------------------------------- % ----

assertion_body(Pred,Compat,Call,Succ,Comp,Comm,
	      (Pred::Compat:Call=>Succ+Comp#Comm)).

%% ---------------------------------------------------------------------------
:- pred normalize_properties(
	Ass,NAss,in(M,moddesc),out(predname),Opts,AType,S,LB,LE) 

   : nabody(Ass) => nabody(NAss) 

   # "The body of @var{NAss} contains the normalized versions of the
     properties in the head and body of @var{Ass}. Body @em{structure}
     is assumed to be normalized in @var{Ass}(i.e., it is assumed that
     the assertion has already been filtered by
     @pred{normalize_body/2}). @var{M} is the current module, @var{AM}
     the module in which the assertion is declared.".
%% ---------------------------------------------------------------------------

normalize_properties(Ass,NAss,M,F/A,Opts,AType,S,LB,LE) :-
       	assertion_body(PD,   DP,  CP,  AP,  GP,CO,Ass),
       	assertion_body(NPD,CNDP,CNCP,CNAP,CNGP,CO,NAss),
	functor(PD,F,A),
	% Normalize properties and modes in head
        get_head_arg_props(PD,NPD,ADP,ACP,AAP,AGP,M,Opts,AType,S,LB,LE),
	% Normalize properties written in "prop * prop" format, 
        % turn conjuction into a list (not such a good idea?)
	norm_arg_props(DP,NDP,NPD,A,M,S,LB,LE),
	norm_arg_props(CP,NCP,NPD,A,M,S,LB,LE),
	norm_arg_props(AP,NAP,NPD,A,M,S,LB,LE),
	% Normalize properties written as "prop" (rather than "prop(Goal)")
	norm_goal_props(GP,NGP,NPD),
	% Add head arg props to the other props found
	append(ADP,NDP,CNDP),
	append(ACP,NCP,CNCP),
	append(AAP,NAP,CNAP),
	append(AGP,NGP,CNGP),
	!.
normalize_properties(Ass,_,_M,AM,_Opts,_AT,S,LB,LE):-
       	assertion_body(PD,  _DP, _CP, _AP, _GP,_CO,Ass),
 	error_message(loc(S,LB,LE),
                      "assertion syntax for ~w in module ~w",[PD,AM]),
	fail.
	
normalize_modedef_properties(( PD:: DP: CP=> AP+ GP#CO),
	                     ( PD::NDP:NCP=>NAP+NGP#CO), M,S,LB,LE) :-
	functor(PD,_,A),
	% Normalize properties written in "prop * prop" format, 
        % turn conjuction into a list (not such a good idea?)
	norm_arg_props(DP,NDP,PD,A,M,S,LB,LE),
	norm_arg_props(CP,NCP,PD,A,M,S,LB,LE),
	norm_arg_props(AP,NAP,PD,A,M,S,LB,LE),
	% Normalize properties written as "prop" (rather than "prop(Goal)")
	% In fact, it is better not to normalize these here: 
        % since they have to be normalized w.r.t. the target predicate 
	%% norm_goal_props(GP,NGP,PD),
        % Even better: normalize as normal properties! (this way we do not 
        % leave behind half normalized modedefs which the 
        % assertion pretty printer would not like
%% 	( GP \== true
%% 	-> simple_message("*** Normalizing ~w modedef goal prop ~w",[PD,GP])
%% 	;  true ),
%% 	norm_arg_props(GP,NGP,PD,A,M),
%% 	( NGP \== []
%% 	-> simple_message("*** Normalized ~w modedef goal prop ~w",[PD,NGP])
%% 	;  true ),
	% Except that then they cannot be documented well... so, normalize
	% after all, and undo it later...
%%  	(  GP \== true
%%  	-> simple_message("*** Normalizing ~w modedef goal prop ~w",[PD,GP])
%% 	;  true ),
	norm_goal_props(GP,NGP,PD),
%%  	(  NGP \== []
%% 	-> simple_message("*** Normalized ~w modedef goal prop ~w",[PD,NGP])
%% 	;  true ),
	%% NGP=GP,
	!.
normalize_modedef_properties(( PD:: _DP:  _CP=>  _AP+  _GP# _CO),_,M,S,LB,LE):-
 	error_message(loc(S,LB,LE),
	          "syntax in modedef declaration for ~w in module ~w",[PD,M]),
	fail.
	
%% ---------------------------------------------------------------------------
:- pred get_head_arg_props(Head,NPD,NDP,NCP,NAP,M,Opts,AType,S,LB,LE) 
   => (list(NDP),list(NCP),list(NAP))

   # "@var{Head} is a head descriptor whose arguments possibly include
      mode annotations. These get translated into standard
      properties. @var{NPD} is the new head descriptor. @var{NDP}
      contais the new compatible properties. @var{NCP}
      contais the new call properties. @var{NAP} contains the new
      answer properties.".
%% ---------------------------------------------------------------------------

get_head_arg_props(PD,NPD,DP,CP,AP,GP,M,Opts,AType,S,LB,LE) :-
	functor(PD, F,A),
	functor(NPD,F,A),
	transform_head_arg_props(
           0,A,PD,NPD,DP,CP,AP,GP,F,A,M,Opts,AType,S,LB,LE).

transform_head_arg_props(Last,Last,_PD,_NPD,[],[],[],[],_,_,_,_,_,_,_,_) :-
	!.
transform_head_arg_props(
               PArg,Last,PD,NPD,DP,CP,AP,GP,F,A,M,Opts,AType,S,LB,LE) :-
	Arg is PArg+1,
	arg(Arg,PD,PDA),
	arg(Arg,NPD,NPDA),
	get_arg_props(
           PDA,NPDA,DP-DPT,CP-CPT,AP-APT,GP-GPT,NPD,F,A,M,Opts,AType,S,LB,LE),
	transform_head_arg_props(
		Arg,Last,PD,NPD,DPT,CPT,APT,GPT,F,A,M,Opts,AType,S,LB,LE).

%% Handling of ISO standard-like "modes" and properties which appear 
%% literally in the head.
%% 
%% p(+A) p(+) p(int) p(+int) p(+list(int)) ...
%% p(ilist(A,integer)) (parametric mode)
%% 
%% Argument is a variable - do nothing
get_arg_props(PDA,PDA,D-D,C-C,A-A,G-G,_NPD,_F,_A,_M,_Opts,_AType,_S,_LB,_LE) :-
	var(PDA),
	!.
%% Argument is a defined (possibly parametric) mode, 
get_arg_props(PDA,NPDA,NDP,NCP,NAP,NGP,NPD,_F,_A,M,Opts,AType,S,LB,LE) :- 
	with_or_without_arg(PDA,NNPDA,Prop),
	%% This M below forces modedefs to be in the file
        %% i.e., they must be in the file or in includes...
        %% But they could possibly also be imported from a module?
	assertion_read(Prop,M,_AStatus,modedef,NPropAss,_Dict,_AS,_ALB,_ALE),
	(  member('-modes',Opts), 
	   \+ propfunctor(AType)
	-> %% Keep modes (and their properties!): do nothing.
	   NPDA = PDA, NDP=DL-DL, NCP=CL-CL, NAP=AL-AL, NGP=GL-GL
	;  %% Assumed that the Props have already been put in list form!
	   NPDA = NNPDA,
	   NPropAss= ((_Prop::CompatProps:CallProps=>AnswerProps+GoalProps#_)),
	   !,
	   resolve_applications(CompatProps,ACompatProps,S,LB,LE),
	   diff_append_props(ACompatProps,NDP),
	   resolve_applications(CallProps,ACallProps,S,LB,LE),
	   diff_append_props(ACallProps,NCP),
	   resolve_applications(AnswerProps,AAnswerProps,S,LB,LE),
	   diff_append_props(AAnswerProps,NAP),
           % Goal Props in modedef should have to be normalized at this point.
           % Since now they come normalized as normal properties, first 
	   % denormalize a bit (to conj) and then fully normalize:
%%  	   (  GoalProps \== []
%% 	   -> simple_message("*** Processing ~w modedef goalprops ~w",[F/A,GoalProps])
%% 	   ;  true ),
%% 	   list_to_conj(GoalProps,CGoalProps),
%% 	   norm_goal_props(CGoalProps,NGoalProps,NPD),
%%  	   (  GoalProps \== []
%%  	   -> simple_message("*** Processed ~w modedef goalprops ~w",[F/A,NGoalProps])
%% 	   ;  true ),
%%  	   (  GoalProps \== []
%% 	   -> simple_message("*** Processing ~w modedef goalprops ~w",[F/A,GoalProps])
%% 	   ;  true ),
	   norm_goal_props(DNGoalProps,GoalProps,_),
	   norm_goal_props(DNGoalProps,NGoalProps,NPD),
%%  	   (  NGoalProps \== []
%%  	   -> simple_message("*** Processed ~w modedef goalprops ~w",[F/A,NGoalProps])
%% 	   ;  true ),
	   resolve_applications(NGoalProps,AGoalProps,S,LB,LE),
	   diff_append_props(AGoalProps,NGP)
	).
%% Else, argument is assumed to be a (possibly parametric) property
%% If '-headprops' is on, leave as is:
get_arg_props(PDA,PDA,D-D,C-C,A-A,G-G,_NPD,_F,_A,_M,Opts,AType,_S,_LB,_LE) :-
	member('-headprops',Opts), 
	\+ propfunctor(AType),
	!.
%% Else, properties are added to compatibility field!
get_arg_props(PDA,NPDA,NDP,NCP,NAP,NGP,_NPD,_F,_A,_M,_Opts,_AType,_S,_LB,_LE):-
	with_or_without_arg(PDA,NPDA,Prop),
	!,
	diff_append_props([Prop],NDP),
	diff_append_props([],NCP),
	diff_append_props([],NAP),
	diff_append_props([],NGP).
get_arg_props(PDA,PDA,DP-DP,CP-CP,AP-AP,G-G,_NPD,F,A,M,_Opts,_AType,S,LB,LE) :-
	error_message(loc(S,LB,LE),
             "syntax of argument '~w' in assertion for ~w/~w in module ~w",
	              [PDA,F,A,M] ).

%% with no argument variable, e.g., p(+), p(in(foo))
with_or_without_arg(PDA,NPDA,Prop) :-
          ground(PDA),
	  !,
 	  PDA =.. [F|Rest],
 	  Prop =.. [F,NPDA|Rest].
%% with argument variable, e.g., p(+(X)), p(in(X,foo))
with_or_without_arg(PDA,NPDA,Prop) :-
   	  PDA =.. [_,NPDA|Rest],
	  var(NPDA),
	  ground(Rest),
	  !,
 	  Prop = PDA.

resolve_applications([],[],_S,_LB,_LE) :- 
	!.
%% newer ciao versions translate T(X,Y) to call(T,X,Y) instead.
%% resolve_applications([apply(CF,[Arg])|R],[Prop|NR]) :-
%% 	!,
%% 	CF =.. [PF|FArgs],
%% 	Prop =.. [PF,Arg|FArgs],
%% 	resolve_applications(R,NR).
resolve_applications([Call|R],[Prop|NR],S,LB,LE) :-
	nonvar(Call),
	Call =.. [call,CF|Args],
	!,
	(  nonvar(CF)
	-> CF =.. [PF|FArgs],
	   %% we take care of call(foo(X),Y)
	   append(FArgs,Args,AllArgs), 
	   %% we take care recursively of nesting: call(foo,X,call(bar,Y))
	   resolve_applications(AllArgs,AllArgsResolved,S,LB,LE),
	   Prop =.. [PF|AllArgsResolved]
	;  error_message(loc(S,LB,LE),
	   "principal functor not sufficiently instantiated in mode: ~w",
                         [Call])
        ),
	resolve_applications(R,NR,S,LB,LE).
resolve_applications([Prop|R],[NProp|NR],S,LB,LE) :-
	nonvar(Prop),
	!,
	Prop =.. [Functor|Args],
	resolve_applications(Args,ArgsResolved,S,LB,LE),
	NProp =.. [Functor|ArgsResolved],
	resolve_applications(R,NR,S,LB,LE).
resolve_applications([Prop|R],[Prop|NR],S,LB,LE) :-
	resolve_applications(R,NR,S,LB,LE).

diff_append_props([],T-T).
diff_append_props([H|T],PH-PT) :-
	PH=[H|NPT],
	diff_append_props(T,NPT-PT).

%% ---------------------------------------------------------------------------
:- comment(norm_arg_props/8,"@var{Props} is a term describing
     properties in an assertion call or sucess point. @var{PropExpr}
     is the normalized version of @var{Props} in list format. ").

:- pred norm_arg_props(Props,PropExpr,PD,Arity,M,S,LB,LE) 
   :  (property_conjunction(Props),var(PropExpr),nonvar(PD),int(Arity)) 
   => nonvar(PropExpr).

:- pred norm_arg_props(Props,PropExpr,PD,Arity,M,S,LB,LE) 
   :  (property_starterm(Props),var(PropExpr),nonvar(PD),int(Arity)) 
   => nonvar(PropExpr).

%% ---------------------------------------------------------------------------

% No props
norm_arg_props(true,[],_PD,_Arity,_M,_S,_LB,_LE) :-
	!.
% No props
norm_arg_props([],[],_PD,_Arity,_M,_S,_LB,_LE) :-
	!.
% Abridged props: * main funct or single prop (arity zero or {} main functor)
norm_arg_props(Props,PropExp,PD,Arity,M,S,LB,LE) :-
	%% The last two are the two unary base cases (hardest to detect)
	( Props = _R * _L ; Props = '{}'(_) ; ground(Props) ),
 	!,
 	norm_abridged_props(Props,PropExp,PD,Arity,M,S,LB,LE).
% Normal props (conjucntion)
norm_arg_props(Props,PropExp,_PD,_Arity,_M,_S,_LB,_LE) :-
 	norm_normal_props(Props,PropExp).
	
% No disjunctions supported yet... 
norm_normal_props((Prop,Rest),[Prop|NRest]) :-
	!,
	norm_normal_props(Rest,NRest). 
norm_normal_props(FinalProp,[FinalProp]).

norm_abridged_props(Ps * P,NPs,PD,Arg,M,S,LB,LE) :-
	!,
	add_argvars(P,Arg,PD,NP),
	NArg is Arg - 1,
	norm_abridged_props(Ps,NLs,PD,NArg,M,S,LB,LE),
	append(NLs,NP,NPs).
norm_abridged_props(P,NP,PD,Arg,_M,_S,_LB,_LE) :-
	Arg = 1,
	add_argvars(P,Arg,PD,NP).
norm_abridged_props(_P,_NP,PD,_Arg,M,S,LB,LE) :-
	error_message(loc(S,LB,LE),
	   "arity mismatch in declaration for ~w in ~w",[PD,M]).

add_argvars('{}'(P),Arg,PD,NPs) :- 
	!,
	add_tuple_argvars(P,Arg,PD,NPs).
add_argvars(P,Arg,PD,[NP]) :- 
	add_argvar(P,Arg,PD,NP).

add_tuple_argvars(','(P,PR),Arg,PD,[NP|NPs]) :-
	!,
	add_argvar(P,Arg,PD,NP),
	add_tuple_argvars(PR,Arg,PD,NPs).
add_tuple_argvars(P,Arg,PD,[NP]) :-
	add_argvar(P,Arg,PD,NP).

add_argvar(P,Arg,PD,NP) :-
	P =.. [F|Vars],
	arg(Arg,PD,Var),
	NP =.. [F,Var|Vars].

%% ---------------------------------------------------------------------------
:- comment(norm_goal_props(Props,PropList,NPr), "@var{Props} is a
   term describing global properties in an assertion. The standard
   format is a conjunction of 0-ary (or, possibly unary)
   properties. @var{PropList} is the normalized version of @var{Props}
   in list format.").

:- pred norm_goal_props(+Props,-PropList,-NPr) # "Normalizes global
   properties.".
:- pred norm_goal_props(-Props,+PropList,+NPr) # "Denormalizes global
   properties.".
%% ---------------------------------------------------------------------------

%% Needs to be improved?
norm_goal_props(true,[],_) :-
	!.
norm_goal_props((GP,GPs),[NGP|NGPs],NPD) :-
	!,
	norm_goal_prop(GP,NGP,NPD),
	norm_goal_props(GPs,NGPs,NPD).
norm_goal_props(GP,[NGP],NPD) :-
	!,
	norm_goal_prop(GP,NGP,NPD).

%% Univ is not smart enough for one version
norm_goal_prop(GP,NGP,NPD) :-
	nonvar(GP),
	!,
	GP  =..[F|Args],
	NGP =.. [F,NPD|Args].
norm_goal_prop(GP,NGP,NPD) :-
	nonvar(NGP),
	!,
	NGP =.. [F,NPD|Args],
	GP  =..[F|Args].

denorm_goal_prop(NGP,GP,NPD) :-
	norm_goal_prop(GP,NGP,NPD).
	
%% ---------------------------------------------------------------------------
:- pred check_body_properties(
   in(CurrentMod,moddesc),in(AssrtMod,moddesc),
   in(F,atom),in(A,int),in(NAss,nabody),in(S),in(LB),in(LE))

        # "Checks each property in the body of assertion @var{NAss}
          (see @pred{check_property/4}). Checks only assertions in the
          current module @var{CurrentMod}.".
%% ---------------------------------------------------------------------------

check_body_properties(M,M,F,A,NAss,S,LB,LE):- !,
       	assertion_body(_NPD,CNDP,CNCP,CNAP,CNGP,_CO,NAss),
	check_properties(CNDP,F,A,M,S,LB,LE),
	check_properties(CNCP,F,A,M,S,LB,LE),
	check_properties(CNAP,F,A,M,S,LB,LE),
	check_properties(CNGP,F,A,M,S,LB,LE).
check_body_properties(M,AM,_Functor,_Arity,_NAss,_S,_LB,_LE):- 
	M \== AM.

%% ---------------------------------------------------------------------------
:- pred check_properties(Props,in(F,atm),in(A,int),in(M,moddesc),
	                 in(S,atm),in(LB,int),in(LE,int))

	: list(Props)

        # "Checks each property in @var{Props} (see @pred{check_property/4}).".
%% ---------------------------------------------------------------------------

check_properties([],_F,_A,_M,_S,_LB,_LE).
check_properties([Prop|Props],F,A,M,S,LB,LE) :-
	check_property(Prop,F,A,M,S,LB,LE),
	check_properties(Props,F,A,M,S,LB,LE).

%% ---------------------------------------------------------------------------
:- pred check_property(+Prop,in(F,atom),in(A,int),in(M,moddesc),
	               in(S,atm),in(LB,int),in(LE,int)) 

# "Checks that, for a property @var{Prop} (which appears in a
   declaration for @var{F}/@var{A} in module @var{M}), a definition
   for that property is visible to that module.".
%% ---------------------------------------------------------------------------

%% 0.8 version: the decls are not sometimes available yet...
%% but line numbers available!
check_property(Prop,F,A,M,S,LB,LE) :- 
  	%% simple_message("** Checking ~w",[Prop]),
	functor(Prop,PF,PA),
	(  ( imports(M,_PM,PF,PA)
	   ; defines(M,PF,PA) )
	-> true
	;  warning_message(loc(S,LB,LE),
		  "~w used in assrt for ~w in ~w not defined or imported",
		  [PF/PA,F/A,M] ) ),
	!.

%% 0.7 version
%% check_property(Prop,F,A,M) :- 
%%   	%% simple_message("** Checking ~w",[Prop]),
%% 	functor(Prop,PF,PA),
%% 	functor(NProp,PF,PA),
%% 	(  assertion_read(NProp,PM,_AStatus,Type,_NPropAss,_Dict,_LC),
%% 	   propfunctor(Type)
%%            %% simple_message("** Found ~w as a ~w in module ~w",[NProp,Type,PM])
%% 	-> true
%% 	;  warning_message("no decl for prop ~w used in assrt for ~w in ~w",
%% 		  [PF/PA,F/A,M] ) ),
%% 	(  ( imports(M,PM,PF,PA)
%% 	   ; defines(M,PF,PA) )
%% 	-> true
%% 	;  warning_message("~w used in assrt for ~w in ~w not defined or imported",
%% 		  [PF/PA,F/A,M] ) ),
%% 	!.

%% ---------------------------------------------------------------------------

:- comment(version_maintenance,dir('../../version')).

:- comment(version(1*3+88,1999/10/22,14:21*30+'MEST'), "Added
   treatment of rel_data/1.  (Francisco Bueno Carrillo)").

:- comment(version(1*3+85,1999/10/19,13:20*53+'MEST'), "Fixed bug in creating
   @tt{.asr} from @tt{.pl} when in the same ciaopp session the @tt{_opt}
   had been created (there was a confusion between the original @tt{.pl}
   and the new @tt{_opt} files). As a result @tt{normalize_assertions/1,2}
   are now @tt{normalize_assertions/2,3} (Francisco Bueno Carrillo)").

:- comment(version(1*3+43,1999/08/02,19:45*06+'MEST'), "Fixed bug in
   the normalization of parametric modes. Made them work also when
   nested applications are used. Also, better error handling. (Manuel
   Hermenegildo)").

:- comment(version(1*3+26,1999/07/09,13:41*50+'MEST'), "Exported
   assrt_lib cleanup.  (Francisco Bueno Carrillo)").

:- comment(version(1*3+8,1999/06/29,17:12*44+'MEST'), "imports/4
   redefined to imports/5.  (Francisco Bueno Carrillo)").

:- comment(version(0*9+93,1999/05/18,13:49*38+'MEST'), "Added comments
   for exported predicates to the @tt{.asr} files.  (Francisco Bueno
   Carrillo)").

:- comment(version(0*9+58,1999/04/26,13:08*40+'MEST'), "Fixed bug that
   made prop definitions appear repeated for the main file.  (Manuel
   Hermenegildo)").

:- comment(version(0*9+57,1999/04/26,13:07*12+'MEST'), "Modified
   normalization logic when generating @tt{.asr} files: now, options
   (like not expanding mode definitions) are taken into account for
   the main file only. Also, the @tt{.asr} files are now always fully
   normalized. Note that the meaning of modes is context-dependent.
   Also, the @tt{.asr} file is not generated now for the main file
   (since the assertions could be non-normalized.  (Manuel
   Hermenegildo)").

:- comment(version(0*9+50,1999/04/14,16:49*09+'MEST'), "Leave in the
   database only the related assertions for predicates that are
   exported.  (Francisco Bueno Carrillo)").

:- comment(version(0*9+49,1999/04/14,12:02*12+'MEST'), "Output to .asr
   file the clauses defining exported properties.  (Francisco Bueno
   Carrillo)").

:- comment(version(0*8+34,1999/02/23,14:42*07+'MET'), "Incorporated
   offline changes (Jan99): i/o in .asr files to @pred{fast_read/1},
   @pred{fast_write/1}.  (Manuel Hermenegildo)").

:- comment(version(0*8+28,1998/12/07,17:46*53+'MET'), "Verbose or
   quiet processing of the assertions may now also be controlled via
   the standard @flag{verbose_compilation} prolog flag. The @tt{'-v'})
   option can still be used to make assertion processing verbose while
   keeping the lower-level module interface processing (done by
   @lib{compiler/c_itf}) quiet. (Manuel Hermenegildo)").

:- comment(version(0*8+27,1998/12/07,17:41*10+'MET'), "Added entry
   point for using library as assertion (and program) syntax check.
   (Manuel Hermenegildo)").

:- comment(version(0*8+26,1998/12/07,17:15*00+'MET'), "Added cleanup
   predicate.  (Manuel Hermenegildo)").

:- comment(version(0*8+25,1998/12/04,20:42*08+'MET'), "Verbose
   (@tt{'-v'}) option now supported, which allows quiet operation
   otherwise. (Manuel Hermenegildo)").

:- comment(version(0*8+23,1998/12/03,20:22*34+'MET'), "All errors are
   now reported with line numbers and source file name.  (Manuel
   Hermenegildo)").

:- comment(version(0*8+18,1998/12/03,12:09*03+'MET'), "Added accurate
   source file and line numbers to @pred{assertion_read}.  (Manuel
   Hermenegildo)").

:- comment(version(0*8+12,1998/12/01,18:03*07+'MET'), "Completed
   global changes for adaptation to 0.8.  (Manuel Hermenegildo)").

:- comment(version(0*8+3,1998/11/05,22:35*06+'MET'), "@tt{;} not
   supported any more as separator in assertions.  (Manuel
   Hermenegildo)").

:- comment(version(0*8+2,1998/11/05,14:44*48+'MET'), "Modified to cope
   with the new behaviour of the c_itf predicates in 0.8.  (Manuel
   Hermenegildo)").

:- comment(version(0*6+14,1998/08/04,13:17*00+'MET DST'), "Eliminated
   compat as basic assertion (it is now a property).  (Manuel
   Hermenegildo)").

:- comment(version(0*6+13,1998/08/04,12:06*35+'MET DST'), "Improved
   error detection of assertions with illegal syntax (previously some
   of them simply failed silently).  (Manuel Hermenegildo)").

:- comment(version(0*6+12,1998/08/04,11:32*29+'MET DST'), "Simplified
   assertion format: comments not allowed any more in basic assertions
   (did not make much sense).  (Manuel Hermenegildo)").

:- comment(version(0*6+6,1998/07/24,19:46*11+'MET DST'), "Added format
   definitions for the new assertion format. For now, both are
   supported simultaneously.  (Manuel Hermenegildo)").

:- comment(version(0*5+46,1998/07/08,16:46*45+'MET DST'), "Made trust
   be a status again.  (Francisco Bueno Carrillo)").

:- comment(version(0*4+12,1998/2/19), "Added module qualification
   c_itf: to the (meta-)calls within error_protect, and took them out
   because they don't work in ciao. (Francisco Bueno Carrillo)").

:- comment(version(0*4+11,1998/2/12), "Redone normalization of global
   properties: fixed bugs and now treatment is much simpler.  (Manuel
   Hermenegildo)").

:- comment(version(0*4+10,1998/2/12), "Assertion order is now kept
   (except that all modedefs appear first).  (Manuel Hermenegildo)").

:- comment(version(0*4+9,1998/2/11), "Added options to selectively
   skip normalization of modes and properties (useful sometimes in
   automatic documentation). (Manuel Hermenegildo)").

:- comment(version(0*4+8,1998/2/9), "Now doing fix_if_type in
   line. (Manuel Hermenegildo / Francisco Bueno Carrillo)").

:- comment(version(0*4+7,1998/2/6), "Added fix_if_type/5. (Francisco
   Bueno Carrillo)").

:- comment(version(0*4+6,1998/2/6), "Improved error
   detection/reporting in check_property. (Manuel Hermenegildo)").

:- comment(version(0*4+5,1998/2/2), "Fixed bug in normalization of
   computation properties in modedefs. (Manuel Hermenegildo)").

:- comment(version(0*4+4,1998/2/2), "Assertion printing now uses
   library('assertions/assrt_write'). (Manuel Hermenegildo)").

:- comment(version(0*4+3,1997/12/26), "Eliminated need for
   denorm_body/2 in preprocessor. (Francisco Bueno Carrillo)").

:- comment(version(0*4+2,1998/1/24), "Fixed several bugs related to
   support of parametric modes. (Manuel Hermenegildo)").

:- comment(version(0*4+1,1998/1/23), "Fixed interface to suit the
   preprocessor. Finally most assertion reading code is unified
   here. (Francisco Bueno)").

:- comment(version(0*4+0,1998/1/23), "Major rewrite of the library
   interface: adaptation to use both in the preprocessor and in the
   automatic documenter. (Manuel Hermenegildo)").

:- comment(version(0*3+13,1998/1/23), "New normalization including
   modes, etc. (Manuel Hermenegildo)").

:- comment(version(0*3+12,1998/1/20), "Added modedef operator. (Manuel
   Hermenegildo)").

:- comment(version(0*3+11,1998/1/9), "New version using the CIAO
   native module dependency navigation builtins. (Manuel
   Hermenegildo)").

:- comment(version(0*3+10,1998/1/8), "Changed variable dictionary
   representation to ISO standard. (Manuel Hermenegildo)").

:- comment(version(0*3+9,1997/12/23), "Added support for both CIAO
   and SICStus dictionaries -- this still needs to be unified in a
   better way. (Manuel Hermenegildo)").

:- comment(version(0*3+8,1997/12/23), "Took out support for scripts
   until peek_char implemented in CIAO. (Manuel Hermenegildo)").

:- comment(version(0*3+7,1997/12/23), "Fixed bug in normalization of
   global properties. (Manuel Hermenegildo)").

:- comment(version(0*3+6,1997/12/23), "Modified treatment of
   declarations (including syntax/1, etc.) (Manuel Hermenegildo)").

:- comment(version(0*3+5,1997/12/23), "Fixed problem with included
   files when such file does not exist. (Manuel Hermenegildo)").

:- comment(version(0*3+4,1997/11/5), "Added typedef operator. (Manuel
   Hermenegildo)").

:- comment(version(0*3+3,1997/9/15), "Added check/1. (Manuel
   Hermenegildo)").

:- comment(version(0*3+2,1997/9/12), "Original library split into two
   parts: formal assertions and text. (Manuel Hermenegildo)").

:- comment(version(0*3+1,1997/12/2), "Added denorm_body/2 and exported
   (for preprocessor) (Francisco Bueno Carrillo)").

:- comment(version(0*3+0,1997/11/28), "Added support for new @tt{decl}
   definitions. (Manuel Hermenegildo)").

:- comment(version(0*2+6,1997/11/18), "Added support for the include
   declaration (Francisco Bueno Carrillo)").

:- comment(version(0*2+5,1997/9/19), "Separated Libs being accessed
   from Libs used by accessing program! (Manuel Hermenegildo)").

:- comment(version(0*2+4,1997/8/15), "Changed to ground
   representation. Vars are '$var(Name)', avoided dictionary.").

:- comment(version(0*2+3,1997/08/11), "Improved documentation. (Manuel
   Hermenegildo)").

:- comment(version(0*2+2,1997/08/11), "Added support for
   multi-argument properties in compact format.").

:- comment(version(0*2+1,1997/07/31), "Added syntax support for
   expressing properties directly in the head.").

:- comment(version(0*2+0,1997/07/21), "Added (ad-hoc) handling of ISO
   standard-like modes and in-line properties.").

:- comment(version(0*1+0,1997/07/18), "Started documentation.").

%% ---------------------------------------------------------------------------
