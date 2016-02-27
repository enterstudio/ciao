:- module(odd, [
        setarg/3,
        undo/1],
	[assertions, isomodes]).

% misc predicates not defined elsewhere

%%        call_residue/2, freeze/1, freeze/2, frozen/2.

:- use_module(engine(internals)).

:- comment(title, "Miscellaneous predicates").
:- comment(author, "Manuel Carro, Daniel Cabeza").

:- comment(module, "This module implements some miscellaneous
   non-logical (but sometimes very useful) predicates.").


 %% call_user_def(Goal) :-
 %% 	'$predicate_property'(Goal, _, _),
 %% 	reset_debugger(State),
 %% 	(call(Goal); set_debugger(State), fail),
 %% 	(set_debugger(State); reset_debugger(_), fail).




:- true pred setarg(Index, Term, NewArg) : integer * struct * term =>
integer * struct * term # "Replace destructively argument @var{Index} in
@var{Term} by @var{NewArg}.  The assignment is undone on
backtracking. This is a major change to the normal behavior of data
assignment in CIAO Prolog.".

setarg(I, F, X):-
        '$setarg'(I, F, X, on).

:- true pred undo(Goal) : callable => callable # "
@tt{call(@var{Goal})} is executed on backtracking.  This is a major
change to the normal @concept{control} of CIAO Prolog execution.".

undo(X):-
        '$undo_goal'(call(X)).


% call_residue_top_list(Limit, Res) :-		% for debugger/toplevel
% 	 '$constraint_list'(Limit, Vars),
% 	 call_residue_top_list(Vars, Res, []).
% 
% call_residue_top_list([]) --> [].
% call_residue_top_list([Var|Vars]) --> [Var-Goal],
% 	{frozen(Var, Goal)},
% 	call_residue_top_list(Vars).
% 
% % SICStus specific.
% call_residue(Goal, Res) :-
% 	_=[C],
% 	copy_term(Goal, Goal1),
% 	'$constraint_list'(C, Frozen0),
% 	frozen_vars(Frozen0, Residue0, []),
% 	call(Goal1),
% 	'$constraint_list'(C, Frozen1),
% 	frozen_vars(Frozen1, Residue1, []),
% 	defrost_vars(Frozen1),
% 	sort(Residue0, Res0),
% 	call_residue_subtract(Residue1, Res0, Res),
% 	Goal = Goal1.
% 
% frozen_vars([]) --> [].
% frozen_vars([V|Vs]) -->
% 	{frozen(V, Conj)},
% 	call_residue_constraints(Conj, V),
% 	frozen_vars(Vs).
% 
% defrost_vars([]).
% defrost_vars([V|Vs]) :-
% 	'$defrost'(V, []),
% 	defrost_vars(Vs).
% 
% call_residue_constraints(true, _) --> !.
% call_residue_constraints((G0,G1), V) --> !,
% 	call_residue_constraints(G0, V),
% 	call_residue_constraints(G1, V).
% call_residue_constraints(Goal, V) --> [V-Goal].
% 
% call_residue_subtract([], _, []).
% call_residue_subtract([_-Goal1|Res1], Res2, Res) :-
% 	call_residue_contains(Res2, Goal1), !,
% 	call_residue_subtract(Res1, Res2, Res).
% call_residue_subtract([V-Goal1|Res1], Res2, [V-Goal1|Res]) :-
% 	call_residue_subtract(Res1, Res2, Res).
% 
% call_residue_contains([_-Goal|Goals], Goal1) :-
% 	call_residue_contains(Goals, Goal, Goal1).
% 
% call_residue_contains(_, Goal, Goal1) :- Goal==Goal1.
% call_residue_contains([_-Goal|Goals], _, Goal1) :- 
% 	call_residue_contains(Goals, Goal, Goal1).

:- comment(version(1*3+95,1999/11/08,18:37*30+'MET'), "Moved dummy
   library to odd (Daniel Cabeza Gras)").

:- comment(version(0*4+5,1998/2/24), "Synchronized file versions with
   global CIAO version.  (Manuel Hermenegildo)").

%% Version comment prompting control for this file.
%% Local Variables: 
%% mode: CIAO
%% update-version-comments: "../version"
%% End:


:- comment(version_maintenance,dir('../version')).

