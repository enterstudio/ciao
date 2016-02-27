:- module(fib, [do_fib/0,fib/2]).
:- use_module(library(write)).
:- use_module(library(prolog_sys)).


n(0).
n(X):-
        n(Y),
        X is Y + 1.

fib(N,F):- 
        n(N),
        fibaux(0,1,N,F).

fibaux(Fact, _Fpost, 0,  Fact).
fibaux(Fact, Fpost, N, F):-
	N > 0,
        N1 is N - 1,
        Nfib is Fact + Fpost,
	fibaux(Fpost, Nfib, N1, F).


do_fib:-
        statistics(runtime, _),
        N = 1000,
        fib(N, F),
        fib(K, F),
        statistics(runtime, [_|T]),
        write('Answer to fibonacci is '),
        write(K),
        write(' (Should be '),
        write(N),
        write(').'),
        nl,
        write('Used '),
        write(T),
        write(' milliseconds'),
        nl.

