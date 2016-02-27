:- module(translation, [
        expand_term/4,
        expand_clause/6,
        goal_trans/2,
        add_sentence_trans/2,
        del_sentence_trans/1,
        add_term_trans/2,
        del_term_trans/1,
        add_clause_trans/2,
        del_clause_trans/1,
        add_goal_trans/2,
        del_goal_trans/1
        ], [assertions]).

:- meta_predicate
        add_sentence_trans(+, spec),
        add_term_trans(+, spec),
%       add_goal_trans(+, spec), % Already in included  add_goal_trans.pl
        add_clause_trans(+, spec).

:- use_module(engine(internals), ['$meta_call'/1, term_to_meta/2]).
:- use_module(library(lists), [append/3]).

expand_term(X0, M, Dict, X2) :-
        sentence_translation(X0, M, Dict, X1), % not recursive
        term_translation(X1, M, Dict, X2).     % recursive

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- data sentence_translations/2.

add_sentence_trans(M, S) :-
        term_to_meta(T/A, S),
        atom(T),
        create_trans(A, T, M, Tr),
        ( retract_fact(sentence_translations(M,Ts)) ->
              append(Ts, [Tr], NTs)
        ; NTs = [Tr]
        ),
        asserta_fact(sentence_translations(M,NTs)).

del_sentence_trans(M) :-
        retractall_fact(sentence_translations(M,_)).

sentence_translation(X, M, Dict, Y) :-
        nonvar(X),
        sentence_translations(M, [T|Ts]), !,
        do_sent_trans(Ts, T, X, Dict, Y).
sentence_translation(X, _, _, X).

do_sent_trans([], T, X, Dict, Xt) :-
        do_translation(T, X, Dict, Xt).
do_sent_trans([T|Ts], T0, X, Dict, Y) :-
        do_translation(T0, X, Dict, Xt),
        do_sent_trans2(Xt, T, Ts, Dict, Y).

do_sent_trans2([], _, _, _, []) :- !.
do_sent_trans2([S1|S2], T, Ts, Dict, St) :- !,
        do_sent_trans(Ts, T, S1, Dict, S1t),
        append_clauses(S1t, S2t, St),
        do_sent_trans2(S2, T, Ts, Dict, S2t).
do_sent_trans2(S, T, Ts, Dict, St) :-
        do_sent_trans(Ts, T, S, Dict, St).

append_clauses([], L, L) :- !.
append_clauses([C|Cs], L, [C|R]) :- !, append(Cs, L, R).
append_clauses(C, L, [C|L]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- data term_translations/2.

add_term_trans(M, S) :-
        term_to_meta(T/A, S),
        atom(T),
        create_trans(A, T, M, Tr),
        ( retract_fact(term_translations(M,Ts)) ->
              append(Ts, [Tr], NTs)
        ; NTs = [Tr]
        ),
        asserta_fact(term_translations(M,NTs)).

del_term_trans(M) :-
        retractall_fact(term_translations(M,_)).

term_translation(X, M, Dict, Y) :-
        current_fact(term_translations(M,Ts)), !,
        term_translation_clauses(X, Ts, Dict, Y).
term_translation(X, _, _, X).

term_translation_clauses([], _, _, []) :- !.
term_translation_clauses([C|Cs], Ts, Dict, [D|Ds]) :- !,
        term_translation_t(C, Ts, Dict, D),
        term_translation_clauses(Cs, Ts, Dict, Ds).
term_translation_clauses(C, Ts, Dict, D) :-
        term_translation_t(C, Ts, Dict, D).

term_translation_t(X, _, _, Y) :- var(X), !, Y = X.
term_translation_t(X, Ts, Dict, Y) :-
        do_translations(Ts, X, Dict, Xt),
        functor(Xt, F, A),
        functor(Y, F, A),
        term_trans_args(A, Xt, Ts, Dict, Y).

term_trans_args(0, _, _, _, _) :- !.
term_trans_args(N, X, Ts, Dict, Y) :-
        arg(N, X, Xn),
        arg(N, Y, Yn),
        N1 is N-1,
        term_translation_t(Xn, Ts, Dict, Yn),
        term_trans_args(N1, X, Ts, Dict, Y).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

expand_clause(H, B, M, Dict, H1, B1) :-
        clause_translations(M, Ts), !,
        do_translations(Ts, clause(H,B), Dict, clause(H1,B1)).
expand_clause(H, B,_M,_Dict, H, B).

:- data clause_translations/2.

add_clause_trans(M, S) :-
        term_to_meta(T/A, S),
        atom(T),
        create_trans(A, T, M, Tr),
        ( retract_fact(clause_translations(M,Ts)) ->
              append(Ts, [Tr], NTs)
        ; NTs = [Tr]
        ),
        asserta_fact(clause_translations(M,NTs)).

del_clause_trans(M) :-
        retractall_fact(clause_translations(M,_)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- data goal_trans/2.

:- include(library('compiler/add_goal_trans')).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_trans(2, T,_M, T).
create_trans(3, T, M, Tr) :-
        functor(Tr, T, 1),
        arg(1, Tr, M).
create_trans(4, T, M, Tr) :-
        functor(Tr, T, 2),
        arg(1, Tr, M).

do_translations([], X, _, X).
do_translations([T|Ts], X, Dict, Y) :-
        do_translation(T, X, Dict, Xt),
        do_translations(Ts, Xt, Dict, Y).

do_translation(T, X, Dict, Y) :-
        comp_goal(T, Dict, G),
        arg(1, G, X),
        arg(2, G, Y),
        '$meta_call'(G), !.
do_translation(_, X, _, X).

comp_goal(T,_Dict, G) :-
        atom(T), !,
        functor(G, T, 2).
comp_goal(T,_Dict, G) :-
        functor(T, F, 1), !,
        arg(1, T, M),
        functor(G, F, 3),
        arg(3, G, M).
comp_goal(T, Dict, G) :-
        functor(T, F, 2), !,
        arg(1, T, M),
        functor(G, F, 4),
        arg(3, G, M),
        arg(4, G, Dict).


% ----------------------------------------------------------------------------

:- comment(version_maintenance,dir('../../version')).

:- comment(version(1*5+96,2000/03/29,20:32*24+'CEST'), "Added the
   posibility of having translations which receive the dictionary of
   variables.  Changed c_itf and assrt_lib accordingly (Daniel Cabeza
   Gras)").

:- comment(version(0*9+2,1999/03/10,21:11*10+'MET'), "Added code to
   handle declaration add_clause_trans/1, to be able to expand clauses
   when information about interface of related modules is needed (so the
   translation is done just before module expansion and compilation).
   (Daniel Cabeza Gras)").

% ----------------------------------------------------------------------------
