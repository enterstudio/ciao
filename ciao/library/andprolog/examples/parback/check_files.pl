:- module(check_files, [speedups/0],[]).

:- use_package(andprolog).
:- use_module(library(apll)).

:- use_module(extras).
:- use_module(library(prolog_sys), [statistics/2]).
:- use_module(library(format), [format/2]).
:- use_module(library(sort)).
:- use_module(library(system)).
:- use_module(library(aggregates)).
:- use_module(library(between)).

:- use_module(library(read)).
:- use_module(library(arithpreds), [floor/2]).

:- data timeseq_first/1.
:- data timeseqfinal_first/1.
:- data timepar_first/1.

:- data timeseq/1.
:- data timeseqfinal/1.
:- data timepar/1.

speedups :-
	set_prolog_flag(gc, off),
	retractall_fact(timeseq(_)),
	retractall_fact(timeseq_first(_)),
	retractall_fact(timeseqfinal(_)),
	retractall_fact(timeseqfinal_first(_)),
	retractall_fact(timepar(_)),
	retractall_fact(timepar(_)),
     	L = ['files/file1','files/file2','files/file1','files/file2','files/file1','files/file2','files/file1','files/file2'],
 %%      	L = ['files/file1','files/file2'],
      	main_seq(L),
 	between(1, 2, N),
 	main_par(N, L).
speedups.

main_seq(R) :-
	between(1,1,_),
	main_seq_(R),
	fail.
main_seq(_) :-
	findall(SS1,retract_fact(timeseq(SS1)),LSeq1),
	findall(SS2,retract_fact(timeseq_first(SS2)),LSeq2),
	average(LSeq1,Seq1),
	average(LSeq2,Seq2),
	assertz_fact(timeseqfinal_first(Seq2)),
	assertz_fact(timeseqfinal(Seq1)).

main_seq_(R) :-
        statistics(walltime, [T1,_]),
	just_first(seq(R,F)),display(first_seq(F)),nl, 
        statistics(walltime, [T2,_]),
        DeltaSeq is T2 - T1,
	assertz_fact(timeseq_first(DeltaSeq)),
	fail.

main_seq_(R) :-
        statistics(walltime, [T1,_]),
	(seq(R,F),display(all_seq(F)),nl,fail;true),
        statistics(walltime, [T2,_]),
        DeltaSeq is T2 - T1,
	assertz_fact(timeseq(DeltaSeq)),
	fail.

main_par(A, R) :-
	ensure_agents(A),
	main_par_(R),
	fail.
main_par(A, _) :-
	current_fact(timeseqfinal_first(Seq)),
	findall(TP,retract_fact(timepar_first(TP)),L),
	average(L,Par),
	SpUp is 100*(Seq/Par),
	floor(SpUp,Sp1),
	Sp is Sp1/100,
	format("-- ~d agents, SpeedUp First=~2f vs Seq=~4f~n", [A,Sp,Seq]),
	fail.
main_par(A, _) :-
	current_fact(timeseqfinal(Seq)),
	findall(TP,retract_fact(timepar(TP)),L),
	average(L,Par),
	SpUp is 100*(Seq/Par),
	floor(SpUp,Sp1),
	Sp is Sp1/100,
	format("-- ~d agents, SpeedUp All=~2f vs Seq=~4f~n", [A,Sp,Seq]),
	fail.

main_par_(R) :-
 	pause(1),
        statistics(walltime, [T1,_]),
	just_first(par(R,F)), display(first_par(F)),nl,
        statistics(walltime, [T2,_]),
        DeltaSeq is T2 - T1,
	assertz_fact(timepar_first(DeltaSeq)),
	fail.
main_par_(R) :-
 %% 	between(1,100,N),
   	pause(1),
 %% 	display(execution(N)),nl,
 %% 	not_measure,
        statistics(walltime, [T1,_]),
	(par(R,F), display(all_par(F)),nl,fail;true),
        statistics(walltime, [T2,_]),
        DeltaSeq is T2 - T1,
	assertz_fact(timepar(DeltaSeq)),
	fail.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

seq([],_).
seq([File|File_rest],BadFile1) :-         
	seq(File_rest,BadFile2),
	check_files(File,BadFile1),
	BadFile1 = BadFile2.

par([],_).
par([File|File_rest],BadFile1) :- 
        check_files(File,BadFile1) & par(File_rest,BadFile2),
	BadFile1 = BadFile2.


check_files(File, BadFile) :-
	(
	    file_exists(File)->
	    open(File, read, S),
	    read_files(S, Files),
	    close(S),
	    check_source_files(Files, BadFile)
	;
	    format("File does not exist.~n", [])
	).

read_files(Stream, Files) :-
	read(Stream, T),
	(
	    T = end_of_file -> Files = []
	;
	    Files = [T|Rest],
	    read_files(Stream,Rest)
	).

check_source_files([], _) :- fail.
check_source_files([F|_Files], BadFile) :-
	check_source_files1(F, BadFile).
check_source_files([_F|Files], BadFile) :-
	check_source_files(Files, BadFile).

check_source_files1(F, BadFile) :-
 	pause,
	(
	    file_exists(F) -> 
	    fail
	;
	    BadFile = F
	).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

just_first(C) :-
	call(C), !.

pause :- fib(18,_).

fib(0, 0) :- !.
fib(1, 1) :- !.
fib(N, F) :-
        N > 1,
        N1 is N - 1,
        N2 is N - 2,
        fib(N1, F1),
	fib(N2, F2),
        F is F1 + F2.