:- module(global, [
        set_global/2,
        get_global/2,
        push_global/2,
        pop_global/2,
        del_global/1],[assertions]).

:- data set/2.

set_global(N, T) :- 
        nonvar(N),
        (retract_fact(set(N, _)) -> true ; true),
        asserta_fact(set(N, T)).
get_global(N, T) :-
        nonvar(N),
        current_fact(set(N, T1)), !,
        T = T1.
push_global(N, T) :- 
        nonvar(N),
        asserta_fact(set(N, T)).
pop_global(N, T) :- 
        nonvar(N),
        retract_fact(set(N, T1)), !,
        T = T1.
del_global(N) :- 
        nonvar(N),
        retractall_fact(set(N,_)).

:- comment(version(0*4+5,1998/2/24), "Synchronized file versions with
   global CIAO version.  (Manuel Hermenegildo)").

%% Version comment prompting control for this file.
%% Local Variables: 
%% mode: CIAO
%% update-version-comments: "../version"
%% End:
