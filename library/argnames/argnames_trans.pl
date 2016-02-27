:- module(argnames_trans, [argnames_def/3, argnames_use/3], [assertions]).

:- use_module(library(terms), [arg/2]).

:- data argnames/4.

argnames_def((:- argnames(R)), _, M) :-
        functor(R, F, N),
        ( argnames(F, _, R0, M)  ->
            ( R0 == R -> true
            ; inform_user(['ERROR: incompatible argnames declaration ',R])
            )
        ; arg(R, A), \+ atomic(A) ->
            inform_user(['ERROR: invalid argnames declaration ',R])
        ; assertz_fact(argnames(F,N,R,M))
        ).
argnames_def(end_of_file, end_of_file, M) :-
        retractall_fact(argnames(_,_,_,M)).

argnames_use($(F,TheArgs), T, M) :-
        atom(F),
        argnames_args(TheArgs, Args),
        argnames_trans(F, Args, M, T).

argnames_trans(F, Args, M, T) :-
        argnames(F, A, R, M),
        functor(T, F, A),
        insert_args(Args, R, A, T), !.
argnames_trans(F, Args, _, _) :-
        argnames_args(TheArgs, Args), !,
        inform_user(['WARNING: invalid argnames ',F,' $ ',TheArgs,
                     ' - not translated']),
        fail.

insert_args([], _, _, _).
insert_args('=>'(F,A), R, N, T) :-
        insert_arg(N, F, A, R, T).
insert_args(('=>'(F,A), As), R, N, T) :-
        insert_arg(N, F, A, R, T),
        insert_args(As, R, N, T).

insert_arg(N, F, A, R, T) :-
        N > 0,
        (   arg(N, R, F) ->
                arg(N, T, A)
        ;   N1 is N-1,
            insert_arg(N1, F, A, R, T)
        ).

argnames_args({}, []).
argnames_args({Args}, Args).

% ----------------------------------------------------------------------------
:- comment(version_maintenance,dir('../../version')).

:- comment(version(0*4+5,1998/2/24), "Synchronized file versions with
   global CIAO version.  (Manuel Hermenegildo)").
% ----------------------------------------------------------------------------

/********************************
  Example translations :

:- argnames person(name, age, profession).

p(person${}).
q(person${age=> 25}).
r(person${name=> D, profession=>prof(D),age=>age(D)}).
s(person${age=>t(25), name=> daniel}).

% argnames(person, 3, person(name,age,profession)).
% 
% p(person(_,_,_)).
% q(person(_,25,_)).
% r(person(A,age(A),prof(A))).
% s(person(daniel,t(25),_)).

********************************/
