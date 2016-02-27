:- module(queens10,
	[
	    main/0,
	    main/1,
	    q10_seq/3,
	    q10_par/4
	],
	[andprolog]).

:- use_module(library(prolog_sys), [statistics/2]).
:- use_module(library(format), [format/2]).
:- use_module(library(aggregates)).
:- use_module(library(between)).
:- use_module(library(system)).
:- use_module(library(arithpreds), [floor/2]).

:- use_module(extras).

:- data timeseq/1.
:- data timeseqfinal/1.
:- data timepar/1.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main :-
	main_nondet.

main_nondet :-
	set_prolog_flag(gc, off),
	retractall_fact(timeseq(_)),
	retractall_fact(timeseqfinal(_)),
	retractall_fact(timepar(_)),
	main_seq(10),
	between(1,8,N),
	main_nondet_par(N,10),
	fail.
main_nondet.

main_seq(X) :-
	between(1,10,_),
        statistics(walltime, [T1,_]),
	q10_seq(10,X,_),
        statistics(walltime, [T2,_]),
        DeltaSeq is T2 - T1,
	assertz_fact(timeseq(DeltaSeq)),
	fail.
main_seq(_) :-
	findall(SS,retract_fact(timeseq(SS)),LSeq),
	average(LSeq,Seq),
	assertz_fact(timeseqfinal(Seq)).

main_nondet_par(N,X) :-
	ensure_agents(N),
	between(1,10,_),
	pause(1),
        statistics(walltime, [T3,_]),
	q10_par(10,X,10,_),
        statistics(walltime, [T4,_]),
	DeltaPar is T4 - T3,
	assertz_fact(timepar(DeltaPar)),
	fail.
main_nondet_par(N,X) :-
	current_fact(timeseqfinal(Seq)),
	findall(TP,retract_fact(timepar(TP)),L),
	average(L,Par),
	SpUp is 100*(Seq/Par),
	floor(SpUp,Sp1),
	Sp is Sp1/100,
	format("-- queens(~f), ~d agents, SpeedUp=~2f~n", [X,N,Sp]),
	fail.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main(_) :-
	set_prolog_flag(gc, off),
	ensure_agents(2),
	X = 10,
        statistics(walltime, [T1,_]),
	q10_par(10,X,10,_),
        statistics(walltime, [T2,_]),
        Delta is T2 - T1,
	format("-- queens(~f)=~f ms.~n", [X,Delta]),
	fail.
main(_).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

q10_seq(0,_,_).
q10_seq(M,N,Qs) :-
	M > 0,
	M1 is M - 1,
	q_seq(N,Qs),
	q10_seq(M1,N,Qs).

q_seq(N,Qs) :-
	queens_seq(N,Qs),
	fail.
q_seq(_,_).

q10_par(0,_,_,_).
q10_par(M,N,G,Qs) :-
	M > 0,
	M1 is M - 1,
	q_par(N,G,Qs) &
	q10_par(M1,N,G,Qs).

q_par(N,G,Qs) :-
	queens_par(N,G,Qs),
	fail.
q_par(_,_,_).

queens_seq(N, Qs):-
        queens_list(N, Ns),
        solve_queens_seq(Ns, [], Qs).    % To place, placed, result

solve_queens_seq([], Qs, Qs).
solve_queens_seq(Unplaced, Placed, Qs):-
        select_queen(Q, Unplaced, NewUnplaced),
        no_attack(Q, Placed),
        solve_queens_seq(NewUnplaced, [Q|Placed], Qs).

queens_par(N, Gran, Qs):-
        queens_list(N, Ns),
        solve_queens_par(Ns, N, Gran, [], Qs).    % To place, placed, result

solve_queens_par([], _, _, Qs, Qs).
solve_queens_par(Unplaced, N, Gran, Placed, Qs):-
	N1 is N - 1,
        select_queen(Q, Unplaced, NewUnplaced),
	(
	    N < Gran ->
	    no_attack(Q, Placed),
	    solve_queens_seq(NewUnplaced, [Q|Placed], Qs)
	;
	    no_attack(Q, Placed) &
            solve_queens_par(NewUnplaced, N1, Gran, [Q|Placed], Qs)
	).

no_attack(Q, Safe):- no_attack_acc(Safe, Q, 1).

no_attack_acc([], _Queen, _Nb).
no_attack_acc([Y|Ys], Queen, Nb):-
        Queen =\= Y + Nb,
        Queen =\= Y - Nb,
        Nb1 is Nb + 1,
        no_attack_acc(Ys, Queen, Nb1).

select_queen(X, [X|Ys], Ys).
select_queen(X, [Y|Ys], [Y|Zs]):-
        select_queen(X, Ys, Zs).

queens_list(0, []).
queens_list(N, [N|Ns]):-
        N > 0,
        N1 is N - 1,
        queens_list(N1, Ns).
