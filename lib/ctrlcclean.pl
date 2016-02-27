:- module(ctrlcclean, [ctrlc_clean/1, delete_on_ctrlc/2, ctrlcclean/0],
	[assertions]).

:- use_module(library(system), [delete_file/1, working_directory/2]).

:- meta_predicate(ctrlc_clean(goal)).

ctrlc_clean(Goal) :- catch(Goal, control_c, ctrlcclean).

:- data delOnCtrlC/2.

delete_on_ctrlc(File, Ref) :-
        working_directory(Dir, Dir),
        asserta_fact(delOnCtrlC(Dir, File), Ref).

ctrlcclean :-
        retract_fact(delOnCtrlC(Dir, File)),
        working_directory(_, Dir),
        delete_file(File),
        fail.
ctrlcclean :- halt.

:- comment(version(0*4+5,1998/2/24), "Synchronized file versions with
   global CIAO version.  (Manuel Hermenegildo)").

%% Version comment prompting control for this file.
%% Local Variables: 
%% mode: CIAO
%% update-version-comments: "../version"
%% End:


