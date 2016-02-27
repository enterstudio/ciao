:- module(basic_props,
        [term/1, int/1, nnegint/1, flt/1, num/1, atm/1, struct/1, gnd/1,
	 constant/1,
         callable/1, operator_specifier/1, list/1, list/2, member/2,
         sequence/2, sequence_or_list/2, character_code/1, string/1,
         predname/1, atm_or_atm_list/1, compat/2,
         iso/1, not_further_inst/2,
	 regtype/1
        ],
        [assertions]).

:- comment(title,"Basic data types and properties").

:- comment(author,"Daniel Cabeza").
:- comment(author,"Manuel Hermenegildo").

:- comment(module,"@cindex{properties, basic} This library contains
   the set of basic properties used by the builtin predicates, and
   which constitute the basic data types and properties of the
   language.  They can be used both as type testing builtins within
   programs (by calling them explicitly) and as properties in
   assertions.").

:- comment(term/1, "The most general type (includes all possible
   terms).").

:- true prop term(X) + regtype # "@var{X} is any term.".

term(_).

:- comment(int/1, "The type of integers. The range of integers is
        @tt{[-2^2147483616, 2^2147483616)}.  Thus for all practical
        purposes, the range of integers can be considered infinite.").

:- true prop int(T) + regtype # "@var{T} is an integer.".

int(X) :-
        nonvar(X), !,
        integer(X).
int(0).
int(N) :- posint(I), give_sign(I, N).

posint(1).
posint(N) :- posint(N1), N is N1+1.

give_sign(P, P).
give_sign(P, N) :- N is -P.

:- comment(nnegint/1, "The type of non-negative integers, i.e.,
	natural numbers.").

:- true prop nnegint(T) + regtype
	# "@var{T} is a non-negative integer.".

nnegint(X) :-
        nonvar(X), !,
        integer(X),
	X >= 0.
nnegint(0).
nnegint(N) :- posint(N).


:- comment(flt/1, "The type of floating-point numbers. The range of
        floats is the one provided by the C @tt{double} type, typically
        @tt{[4.9e-324, 1.8e+308]} (plus or minus).").

:- true prop flt(T) + regtype # "@var{T} is a float.".

flt(T) :- float(T), !.
flt(T) :- int(N), T is N/10.

:- comment(num/1, "The type of numbers, that is, integer or floating-point.").

:- true prop num(T) + regtype # "@var{T} is a number.".

num(T) :- number(T), !.
num(T) :- int(T).
% num(T) :- flt(T). % never reached!

:- comment(atm/1, "The type of atoms, or non-numeric constants.  The name of
        an atom must be of less than 512 characters.").

:- true prop atm(T) + regtype # "@var{T} is an atom.".

% Should be current_atom/1
atm(a).
atm(T) :- atom(T).

:- comment(struct/1, "The type of compound terms, or terms with
non-zeroary functors.").

:- true prop struct(T) + regtype # "@var{T} is a compound term.".

struct([_|_]):- !.
struct(T) :- functor(T, _, A), A>0. % compound(T).

:- comment(gnd/1, "The type of all terms without variables.").

:- true prop gnd(T) + regtype # "@var{T} is ground.".

gnd([]) :- !.
gnd(T) :- functor(T, _, A), grnd_args(A, T).

grnd_args(0, _).
grnd_args(N, T) :-
        arg(N, T, A),
        gnd(A),
        N1 is N-1,
        grnd_args(N1, T).

:- true prop constant(T) + regtype
   # "@var{T} is an atomic term (an atom or a number).".

constant(T) :- atm(T).
constant(T) :- num(T).

:- true prop callable(T) + regtype
   # "@var{T} is a term which represents a goal, i.e.,
        an atom or a structure.".

callable(T) :- atm(T).
callable(T) :- struct(T).

:- comment(operator_specifier/1, "The type and associativity of an
operator is described by the following mnemonic atoms:

@begin{description}

@item{@tt{xfx}} Infix, non-associative: it is a requirement that both of
the two subexpressions which are the arguments of the operator must be
of @em{lower} precedence than the operator itself.

@item{@tt{xfy}} Infix, right-associative: only the first (left-hand)
subexpression must be of lower precedence; the right-hand subexpression
can be of the @em{same} precedence as the main operator.

@item{@tt{xfx}} Infix, left-associative: same as above, but the other
way around.

@item{@tt{fx}} Prefix, non-associative: the subexpression must be of
@em{lower} precedence than the operator.

@item{@tt{fy}} Prefix, associative: the subexpression can be of the
@em{same} precedence as the operator.

@item{@tt{xf}} Postfix, non-associative: the subexpression must be of
@em{lower} precedence than the operator.

@item{@tt{yf}} Postfix, associative: the subexpression can be of the
@em{same} precedence as the operator.

@end{description}
").

:- true prop operator_specifier(X) + regtype # "@var{X} specifies the type and
        associativity of an operator.".

operator_specifier(fy). 
operator_specifier(fx). 
operator_specifier(yfx).
operator_specifier(xfy).
operator_specifier(xfx).
operator_specifier(yf). 
operator_specifier(xf). 

:- comment(list/1, "A list is formed with successive applications of the
functor @tt{'.'/2}, and its end is the atom @tt{[]}").

:- true prop list(L) + regtype # "@var{L} is a list.".

list([]).
list([_|L]) :- list(L).

:- true prop list(L,T) + regtype # "@var{L} is a list of @var{T}s.".
:- meta_predicate list(?, pred(1)).

list([],_).
list([X|Xs], T) :-
        T(X),
        list(Xs, T).

:- true prop member(X,L) # "@var{X} is an element of @var{L}.".

member(X, [X|_]).
member(X, [_Y|Xs]):- member(X, Xs).

:- comment(sequence/2, "A sequence is formed with zero, one or more
   occurrences of the operator @op{','/2}.  For example, @tt{a, b, c} is
   a sequence of three atoms, @tt{a} is a sequence of one atom.").

:- true prop sequence(S,T) + regtype # "@var{S} is a sequence of @var{T}s.".

:- meta_predicate sequence(?, pred(1)).

sequence(E, T) :- T(E).
sequence((E,S), T) :-
        T(E),
        sequence(S,T).

:- true prop sequence_or_list(S,T) + regtype
   # "@var{S} is a sequence or list of @var{T}s.".

:- meta_predicate sequence_or_list(?, pred(1)).

sequence_or_list(E, T) :- list(E,T).
sequence_or_list(E, T) :- sequence(E, T).

:- true prop character_code(T) => int + regtype
   # "@var{T} is an integer which is a character code.".

character_code(I) :- int(I).

:- true prop string(T) => list(character_code) + regtype
   # "@var{T} is a string (a list of character codes).".

string(T) :- list(T, character_code).

/*
:- comment(predname(P),"@var{P} is a Name/Arity structure denoting
	a predicate name: @includedef{predname/1}").
:- true prop predname(P) + regtype
   # "@var{P} is a predicate name spec @tt{atm}/@tt{int}.".
*/
:- true prop predname(P) + regtype
   # "@var{P} is a Name/Arity structure denoting
	a predicate name: @includedef{predname/1}".

predname(P/A) :-
	atm(P),
	int(A).

:- true prop atm_or_atm_list(T) + regtype
   # "@var{T} is an atom or a list of atoms.".

atm_or_atm_list(T) :- atm(T).
atm_or_atm_list(T) :- list(T, atm).


:- comment(compat/2,"This property captures the notion of type or
   @concept{property compatibility}. The instantiation or constraint
   state of the term is compatible with the given property, in the
   sense that assuming that imposing that property on the term does
   not render the store inconsistent. For example, terms @tt{X} (i.e.,
   a free variable), @tt{[Y|Z]}, and @tt{[Y,Z]} are all compatible
   with the regular type @pred{list/1}, whereas the terms @tt{f(a)} and
   @tt{[1|2]} are not.").

:- true prop compat(Term,Prop) 
   # "@var{Term} is @em{compatible} with @var{Prop}".
:- meta_predicate compat(?, pred(1)).

compat(T, P) :- \+ \+ P(T).

% No comment necessary: it is taken care of specially anyway in the
% automatic documenter.

:- true prop iso(G) # "@em{Complies with the ISO-Prolog standard.}".

:- impl_defined([iso/1]).

:- true prop not_further_inst(G,V) # "@var{V} is not further instantiated.".

:- impl_defined(not_further_inst/2).

:- true prop regtype(G) # "Defines a regular type.".

:- impl_defined(regtype/1).


:- comment(version_maintenance,dir('../../version')).

:- comment(version(1*3+100,1999/11/12,17:14*25+'MET'), "Added exported
   property regtype/2.  (Francisco Bueno Carrillo)").

:- comment(version(0*9+44,1999/04/13,12:24*07+'MEST'), "Added
   nnegint/1.  (Francisco Bueno Carrillo)").

:- comment(version(0*9+19,1999/03/25,16:32*32+'MET'), "Fixed bug in
   int/1 to avoid infinite loops when the argument is not compatible
   with int.  (Daniel Cabeza Gras)").

