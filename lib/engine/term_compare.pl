:- module(term_compare, [
        (==)/2, (\==)/2, (@<)/2, (@=<)/2, (@>)/2, (@>=)/2, compare/3],
        [assertions, isomodes]).

:- comment(title,"Comparing terms").

:- comment(author,"Daniel Cabeza").
:- comment(author,"Manuel Hermenegildo").

:- comment(usage, "These predicates are builtin in Ciao, so nothing special
   has to be done to use them.").

:- comment(module, "These built-in predicates are extra-logical. They
treat uninstantiated variables as objects with values which may be
compared, and they never instantiate those variables. They should
@em{not} be used when what you really want is arithmetic comparison or
unification.

The predicates make reference to a @index{standard total ordering} of terms,
which is as follows:

@begin{itemize}

@item Variables, by age (roughly, oldest first -- the order is @em{not}
 related to the names of variables).

@item Floats, in numeric order (e.g. -1.0 is put before 1.0). 

@item Integers, in numeric order (e.g. -1 is put before 1). 

@item Atoms, in alphabetical (i.e. character code) order. 

@item Compound terms, ordered first by arity, then by the name of the
    principal functor, then by the arguments in left-to-right
    order. Recall that lists are equivalent to compound terms with
    principal functor @tt{'.'/2}.

@end{itemize}

For example, here is a list of terms in standard order: 

@begin{verbatim}
[ X, -1.0, -9, 1, bar, foo, [1], X = Y, foo(0,2), bar(1,1,1) ]
@end{verbatim}
").

% Compiled inline -- these are hooks for the interpreter.

:- prop (@Term1 == @Term2) + native # "The terms @var{Term1} and @var{Term2} are
   strictly identical.".

X==Y :- X==Y.

:- prop (@Term1 \== @Term2) + native # "The terms @var{Term1} and @var{Term2} are
   not strictly identical.".

X\==Y :- X\==Y.

:- prop (@Term1 @< @Term2) + native # "The term @var{Term1} precedes the term
   @var{Term2} in the standard order.".

X@<Y :- X@<Y.

:- prop (@Term1 @=< @Term2) + native # "The term @var{Term1} precedes or is
   identical to the term @var{Term2} in the standard order.".

X@=<Y :- X@=<Y.

:- prop (@Term1 @> @Term2) + native # "The term @var{Term1} follows the term
   @var{Term2} in the standard order.".

X@>Y :- X@>Y.

:- prop (@Term1 @>= @Term2) + native # "The term @var{Term1} follows or is
   identical to the term @var{Term2} in the standard order.".

X@>=Y :- X@>=Y.

:- comment(compare(Op,Term1,Term2) , "@var{Op} is the result of
           comparing the terms @var{Term1} and @var{Term2}.").

:- true pred compare(?atm,@term,@term)
	=> member([(=),(>),(<)]) * term * term + native.

compare(X, Y, Z) :- compare(X, Y, Z).

:- comment(version_maintenance,dir('../../version')).

:- comment(version(1*9+199,2003/12/19,18:18*33+'CET'), "First
revision.  (Edison Mera)").

