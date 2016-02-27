:- module(faggr,[inject/3,prod/3,min/3,luka/3,dprod/3,max/3,dluka/3,'=>'/4],
	         [clpr,hiord]).



min(X,Y,Z):- X .=<. Y , Z .=. X.
min(X,Y,Z):- X .>. Y, Z .=. Y .

prod(X,Y,M):- M .=. X * Y.

luka(X,Y,M):- Z1.=.0,Z2.=. X + Y  - 1,max(Z1,Z2,M).

max(X,Y,Z):- X .>=. Y, Z .=. X.
max(X,Y,Z):- Y .>. X, Z .=. Y.

dprod(X,Y,M):- M .=. X + Y - (X * Y).

dluka(X,Y,M):- Z1.=.1,Z2.=. X + Y, min(Z1,Z2,M).


:- meta_predicate preinject(?,pred(3),?).

preinject([],_,[]).
preinject(L,P,T):- P(L,T).

:- meta_predicate inject(?,pred(3),?).

inject([],_,_).
inject([T],_,T).
inject([X,Y|Rest],P,T):-
	P(X,Y,T0),
	inject([T0|Rest],P,T).

:- meta_predicate postinject(?,pred(3),?).

preinject([],_,[]).
preinject(L,P,T):- P(L,T).


:- new_declaration(is_fuzzy/3,on).
:- is_fuzzy('=>',4,truth).

:- meta_predicate =>(pred(3),goal,goal,?).

=>(Formula,X,Y,M):- 
	functor(X,_,Ax),
	arg(Ax,X,Mx),
	functor(Y,_,Ay),
	arg(Ay,Y,My),
	call(X),
	call(Y),
	call(Formula,Mx,My,M).

