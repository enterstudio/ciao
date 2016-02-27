:- module(random, [random/1, random/3, srandom/1], [foreign_interface]).

:- comment(module, "This module provides predicates for generating
        pseudo-random numbers").

:- comment(random(Number), "@var{Number} is a (pseudo-) random number in
        the range [0.0,1.0]").

:- true pred random(-float) + native(prolog_random).

:- comment(random(Low, Up, Number), "@var{Number} is a (pseudo-) random
        number in the range [@var{Low}, @var{Up}]").

:- true pred random(+int,+int,-int) + native(prolog_random3)
        # "If @var{Low} and @var{Up} are integers, @var{Number} is an
          integer.".

:- true pred random(+flt,+num,-flt).
:- true pred random(+int,+flt,-flt).

:- comment(srandom(Seed), "Changes the sequence of pseudo-random
        numbers according to @var{Seed}.  The stating sequence of
        numbers generated can be duplicated by calling the predicate
        with @var{Seed} unbound (the sequence depends on the OS).").

:- true pred srandom(+int) + native(prolog_srandom).

:- use_foreign_source(random).

