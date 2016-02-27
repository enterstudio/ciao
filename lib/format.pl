:- module(format, 
	[format/2, format/3, format_control/1],
	[dcg,assertions,isomodes]).

:- use_module(library(write)).
% :- use_module(library(dcg_expansion)). % This is not at all needed!!
% >> take '$format_print_float' & '$format_print_integer' out of emulator!DCG
:- use_module(engine(internals)).

%% FOR TEMPORARILY PARTIALLY DOCUMENTING:
:- use_module(library('assertions/doc_props')).

:- set_prolog_flag(multi_arity_warnings, off).

% ------------------------------------------------------------------------
:- comment(title,"Formatted output").

:- comment(author, "The CLIP Group").

:- comment(module,"The @tt{format} family of predicates is due to 
	Quintus Prolog. They act as a Prolog interface to the C 
	@tt{stdio} function @tt{printf()}, allowing formatted output.

	Output is formatted according to an output pattern which can
        have either a format control sequence or any other character,
	which will appear verbatim in the output. Control sequences
        act as place-holders for the actual terms that will be output.
        Thus  
        @begin{verbatim}
        ?- format(""Hello ~q!"",world).
        @end{verbatim}
        @noindent
        will print @tt{Hello world!}.

        If there is only one item to print it may be supplied alone.
        If there are more they have to be given as a list. If there are 
        none then an empty list should be supplied. There has to be as
        many items as control characters.

        The character @tt{~} introduces a control sequence. To print 
        a @tt{~} verbatim just repeat it:  
        @begin{verbatim}
        ?- format(""Hello ~~world!"", []).
        @end{verbatim}
        @noindent
        will result in @tt{Hello ~world!}.

        A format may be spread over several lines. The control
        sequence @tt{\\c} followed by a @key{LFD} will translate to the 
        empty string:  
        @begin{verbatim}
        ?- format(""Hello \\c
        world!"", []).
        @end{verbatim}
        @noindent
        will result in @tt{Hello world!}.").

:- comment(format_control/1,"
The general format of a control sequence is @tt{~@var{N}@var{C}}.
The character @var{C} determines the type of the control sequence.
@var{N} is an optional numeric argument.  An alternative form of @var{N}
is @tt{*}. @tt{*} implies that the next argument in @var{Arguments}
should be used as a numeric argument in the control sequence.  Example:  

@begin{verbatim}
?- format(""Hello~4cworld!"", [0'x]).
@end{verbatim}

@noindent
and

@begin{verbatim}
?- format(""Hello~*cworld!"", [4,0'x]).
@end{verbatim}

@noindent
both produce

@begin{verbatim}
Helloxxxxworld!
@end{verbatim}

The following control sequences are available.

@begin{itemize}

@item ~a
The argument is an atom.  The atom is printed without quoting.  

@item ~@var{N}c
(Print character.)  The argument is a number that will be interpreted as an
ASCII code. @var{N} defaults to one and is interpreted as the number of
times to print the character.  

@item ~@var{N}e
@item ~@var{N}E
@item ~@var{N}f
@item ~@var{N}g
@item ~@var{N}G
(Print float).  The argument is a float.  The float and @var{N} will be
passed to the C @tt{printf()} function as  

@begin{verbatim}
printf(""%.@var{N}e"", @var{Arg})
printf(""%.@var{N}E"", @var{Arg})
printf(""%.@var{N}f"", @var{Arg})
printf(""%.@var{N}g"", @var{Arg})
printf(""%.@var{N}G"", @var{Arg})
@end{verbatim}

If @var{N} is not supplied the action defaults to

@begin{verbatim}
printf(""%e"", @var{Arg})
printf(""%E"", @var{Arg})
printf(""%f"", @var{Arg})
printf(""%g"", @var{Arg})
printf(""%G"", @var{Arg})
@end{verbatim}

@item ~@var{N}d
(Print decimal.) The argument is an integer. @var{N} is interpreted as the
number of digits after the decimal point.  If @var{N} is 0 or missing, no
decimal point will be printed.  Example:  

@begin{verbatim}
?- format(""Hello ~1d world!"", [42]).
?- format(""Hello ~d world!"", [42]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello 4.2 world!
Hello 42 world!
@end{verbatim}

@noindent
respectively.

@item ~@var{N}D
(Print decimal.) The argument is an integer.  Identical to @tt{~@var{N}d}
except that @tt{,} will separate groups of three digits to the left of the
decimal point.  Example:  

@begin{verbatim}
?- format(""Hello ~1D world!"", [12345]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello 1,234.5 world!
@end{verbatim}

@item ~@var{N}r
(Print radix.) The argument is an integer. @var{N} is interpreted as a radix.
@var{N} should be >= 2 and <= 36.  If @var{N} is missing the radix defaults to
8.  The letters @tt{a-z} will denote digits larger than 9.  Example:  

@begin{verbatim}
?- format(""Hello ~2r world!"", [15]).
?- format(""Hello ~16r world!"", [15]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello 1111 world!
Hello f world!
@end{verbatim}

@noindent
respectively.

@item ~@var{N}R
(Print radix.) The argument is an integer.  Identical to @tt{~@var{N}r} except
that the letters @tt{A-Z} will denote digits larger than 9.  Example:  

@begin{verbatim}
?- format(""Hello ~16R world!"", [15]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello F world!
@end{verbatim}

@item ~@var{N}s
(Print string.) The argument is a list of ASCII codes.  Exactly @var{N}
characters will be printed. @var{N} defaults to the length of the string.
Example:  

@begin{verbatim}
?- format(""Hello ~4s ~4s!"", [""new"",""world""]).
?- format(""Hello ~s world!"", [""new""]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello new  worl!
Hello new world!
@end{verbatim}

@noindent
respectively.

@item ~i
(Ignore argument.) The argument may be of any type.  The argument will be
ignored.  Example:  

@begin{verbatim}
?- format(""Hello ~i~s world!"", [""old"",""new""]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello new world!
@end{verbatim}

@item ~k
(Print canonical.) The argument may be of any type.  The argument will be
passed to @tt{write_canonical/2} (@ref{Term output}).  Example:  

@begin{verbatim}
?- format(""Hello ~k world!"", [[a,b,c]]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello .(a,.(b,.(c,[]))) world!
@end{verbatim}

@item ~p
(print.) The argument may be of any type.  The argument will be passed to
@tt{print/2} (@ref{Term output}).  Example:

@noindent
suposing the user has defined the predicate

@begin{verbatim}
:- multifile portray/1.
portray([X|Y]) :- print(cons(X,Y)).
@end{verbatim}

@noindent
then

@begin{verbatim}
?- format(""Hello ~p world!"", [[a,b,c]]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello cons(a,cons(b,cons(c,[]))) world!
@end{verbatim}

@item ~q
(Print quoted.) The argument may be of any type.  The argument will be
passed to @tt{writeq/2} (@ref{Term output}).  Example:  

@begin{verbatim}
?- format(""Hello ~q world!"", [['A','B']]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello ['A','B'] world!
@end{verbatim}

@item ~w
(write.) The argument may be of any type.  The argument will be passed to
@tt{write/2} (@ref{Term output}).  Example:  

@begin{verbatim}
?- format(""Hello ~w world!"", [['A','B']]).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello [A,B] world!
@end{verbatim}

@item ~@var{N}n
(Print newline.) Print @var{N} newlines. @var{N} defaults to 1.
Example:  

@begin{verbatim}
?- format(""Hello ~n world!"", []).
@end{verbatim}

@noindent
will print as

@begin{verbatim}
Hello
 world!
@end{verbatim}

@item ~N
(Fresh line.) Print a newline, if not already at the beginning of a line.

@item ~~
(Print tilde.) Prints @tt{~}

@end{itemize}


The following control sequences are also available for compatibility,
but do not perform any useful functions.

@begin{itemize}
@item ~@var{N}|
(Set tab.) Set a tab stop at position @var{N}, where @var{N} defaults to
the current position, and advance the current position there.

@item ~@var{N}+
(Advance tab.) Set a tab stop at @var{N} positions past the current
position, where @var{N} defaults to 8, and advance the current position
there.

@item ~@var{N}t
(Set fill character.) Set the fill character to be used in the next
position movement to @var{N}, where @var{N} defaults to @key{SPC}.
@end{itemize}

").


% ------------------------------------------------------------------------

:- prop format_control(C) + ( regtype, doc_incomplete ) 
   # "@var{C} is an atom or string describing how the arguments should
      be formatted. If it is an atom it will be converted into a
      string with @tt{name/2}.".

format_control(C) :- string(C).
format_control(C) :- atm(C).

% format(+Control, +Arguments)
% format(+Stream, +Control, +Arguments)
% Stream Stream
% atom or list of chars Control corresponds roughly to the first argument of
%				the C stdio function printf().
% list or atom Arguments	corresponds to the rest of the printf()
%				arguments
%

:- true pred format(format_control(Format),Arguments)
   # "Print @var{Arguments} onto current output stream according to format
      @var{Format}.".

:- true comp format(C,A) + native(format(C,A)).

format(Control, _) :-
        var(Control), !,
        throw(error(instantiation_error, format/2-1)).
format(Control, Arguments) :- format1(Control, Arguments), !.
format(Control, Arguments) :-
	throw(error(invalid_arguments(format(Control, Arguments)), format/2)).

:- true pred format(+Stream,format_control(Format),Arguments)
   # "Print @var{Arguments} onto @var{Stream} according to format
      @var{Format}.".

:- true comp format(S,C,A) + native(format(S,C,A)).

format(_, Control, _) :-
        var(Control), !,
        throw(error(instantiation_error, format/3-2)).
format(Stream, Control, Arguments) :-
        current_output(Curr),
        set_output(Stream),
	(   format1(Control, Arguments) -> OK=yes
	;   OK=no
	),
        set_output(Curr),
        OK=yes, !.
format(_, Control, Arguments) :-
	throw(error(invalid_arguments(format(..., Control, Arguments)), format/3)).

format1(Control, Arguments) :-
	(   atom(Control) -> atom_codes(Control, ControlList)
	;   ControlList=Control
	),
	(   ArgumentList=Arguments
	;   ArgumentList=[Arguments]
	),
	fmt_parse(ArgumentList, SpecList, ControlList, []), !,
	current_output(Stream),
	fmt_print(SpecList, 0, 0' , Stream).

fmt_print([], _, _, _).
fmt_print([X|Xs], Tab, Fill, Stream) :- fmt_print(X, Xs, Tab, Fill, Stream).

fmt_print(settab(Arg,Tab0PlusArg,Pos,Tab), Xs, Tab0, Fill, Stream) :- !,
	Tab0PlusArg is Tab0+Arg,
	line_position(Stream, Pos),
	(   Pos>Tab ->
	    nl,
	    putn(Tab, Fill)
	;   Skip is Tab-Pos,
	    putn(Skip, Fill)
	),
	fmt_print(Xs, Tab, Fill, Stream).
fmt_print(fill(Fill), Xs, Tab, _, Stream) :- !,
	fmt_print(Xs, Tab, Fill, Stream).
fmt_print(spec(X,A,N), Xs, Tab, Fill, Stream) :- !,
	line_count(Stream, Lc0),
	fmt_pr(X, A, N),
	line_count(Stream, Lc),
	fmt_print(Lc0, Lc, Xs, Tab, Fill, Stream).
fmt_print(0'
	  , Xs, _, _, Stream) :- !,
	nl,
	fmt_print(Xs, 0, 0' , Stream).
fmt_print(C, Xs, Tab, Fill, Stream) :-
	Char is integer(C),
	put_code(Char),
	fmt_print(Xs, Tab, Fill, Stream).

fmt_print(Lc, Lc, Xs, Tab, Fill, Stream) :- !,
	fmt_print(Xs, Tab, Fill, Stream).
fmt_print(_, _, Xs, _, _, Stream) :- !,
	fmt_print(Xs, 0, 0' , Stream).

fmt_parse([], []) --> [].
fmt_parse(Args, Specs) --> [0'~, C1], !,
	fmt_parse(C1, Args, Specs, 0, D, D).
fmt_parse(Args, Specs) --> [0'\\, 0'c, 0'
                           ], !,
	fmt_parse(Args, Specs).
fmt_parse(Args, [I|Specs]) --> [I],
	{integer(I)},
	fmt_parse(Args, Specs).

fmt_parse(C, Args, Specs, Sofar, _, D) --> {C>=0'0, C=<0'9}, !,
	{N is 10*Sofar+C-0'0},
	[C1], fmt_parse(C1, Args, Specs, N, N, D).
fmt_parse(0'*, [N|Args], Specs, _, _, D) -->
	{integer(N)},
	[C1], fmt_parse(C1, Args, Specs, 0, N, D).
fmt_parse(0'~, Args, [0'~|Specs], _, 1, 1) -->
	fmt_parse(Args, Specs).
fmt_parse(0'n, Args, [spec(0'c, 0'
                          , N)|Specs], _, N, 1) -->
	fmt_parse(Args, Specs).
fmt_parse(0'N, Args, [settab(0,_,_,0)|Specs], _, 1, 1) -->
	fmt_parse(Args, Specs).
fmt_parse(0'|, Args, [Spec|Specs], _, N, current) -->
	(   {current=N} ->
	    {Spec=settab(0,_,Tab,Tab)}
	;   {Spec=settab(N,_,_,N)}
	),
	fmt_parse(Args, Specs).
fmt_parse(0'+, Args, [settab(N,Tab,_,Tab)|Specs], _, N, 8) -->
	fmt_parse(Args, Specs).
fmt_parse(0't, Args, [fill(N)|Specs], _, N, 0' ) --> % faking
	fmt_parse(Args, Specs).
fmt_parse(0'`, Args, [fill(Fill)|Specs], 0, _, _) -->
	[Fill, 0't],
	fmt_parse(Args, Specs).
fmt_parse(0'i, [_|Args], Specs, _, 1, 1) -->
	fmt_parse(Args, Specs).
fmt_parse(0'a, [A|Args], [spec(0'a, A, 1)|Specs], _, 1, 1) -->
	{atom(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'c, [A|Args], [spec(0'c, A, N)|Specs], _, N, 1) -->
	{integer(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'k, [A|Args], [spec(0'k, A, 1)|Specs], _, 1, 1) -->
	fmt_parse(Args, Specs).
fmt_parse(0'p, [A|Args], [spec(0'p, A, 1)|Specs], _, 1, 1) -->
	fmt_parse(Args, Specs).
fmt_parse(0'q, [A|Args], [spec(0'q, A, 1)|Specs], _, 1, 1) -->
	fmt_parse(Args, Specs).
fmt_parse(0'w, [A|Args], [spec(0'w, A, 1)|Specs], _, 1, 1) -->
	fmt_parse(Args, Specs).
fmt_parse(0'e, [A|Args], [spec(0'e, V, N)|Specs], _, N, 6) -->
	{V is float(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'E, [A|Args], [spec(0'E, V, N)|Specs], _, N, 6) -->
	{V is float(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'f, [A|Args], [spec(0'f, V, N)|Specs], _, N, 6) -->
	{V is float(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'g, [A|Args], [spec(0'g, V, N)|Specs], _, N, 6) -->
	{V is float(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'G, [A|Args], [spec(0'G, V, N)|Specs], _, N, 6) -->
	{V is float(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'd, [A|Args], [spec(0'd, V, N)|Specs], _, N, 0) -->
	{V is integer(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'D, [A|Args], [spec(0'D, V, N)|Specs], _, N, 0) -->
	{V is integer(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'r, [A|Args], [spec(0'r, V, N)|Specs], _, N, 8) -->
	{V is integer(A)},
	fmt_parse(Args, Specs).
fmt_parse(0'R, [A|Args], [spec(0'R, V, N)|Specs], _, N, 8) -->
	{V is integer(A)},
	fmt_parse(Args, Specs).
fmt_parse(0's, [A|Args], [spec(0's, A, N)|Specs], _, N, Len) -->
	{is_ascii_list(A, 0, Len)},
	fmt_parse(Args, Specs).

is_ascii_list(X, _, _) :- var(X), !, fail.
is_ascii_list([], N, N).
is_ascii_list([X|Xs], N0, N) :-
	N1 is N0+1,
	integer(X),
	is_ascii_list(Xs, N1, N).

fmt_pr(0'a, Arg, _) :- display(Arg).
fmt_pr(0'k, Arg, _) :- write_canonical(Arg).
fmt_pr(0'p, Arg, _) :- print(Arg).
fmt_pr(0'q, Arg, _) :- writeq(Arg).
fmt_pr(0'w, Arg, _) :- write(Arg).
fmt_pr(0'c, Arg, Number) :-
	putn(Number, Arg).
fmt_pr(0'e, Arg, Number) :-
	'$format_print_float'(0'e, Arg, Number).
fmt_pr(0'E, Arg, Number) :-
	'$format_print_float'(0'E, Arg, Number).
fmt_pr(0'f, Arg, Number) :-
	'$format_print_float'(0'f, Arg, Number).
fmt_pr(0'g, Arg, Number) :-
	'$format_print_float'(0'g, Arg, Number).
fmt_pr(0'G, Arg, Number) :-
	'$format_print_float'(0'G, Arg, Number).
fmt_pr(0'd, Arg, Number) :-
	'$format_print_integer'(0'd, Arg, Number).
fmt_pr(0'D, Arg, Number) :-
	'$format_print_integer'(0'D, Arg, Number).
fmt_pr(0'r, Arg, Number) :-
	'$format_print_integer'(0'r, Arg, Number).
fmt_pr(0'R, Arg, Number) :-
	'$format_print_integer'(0'R, Arg, Number).
fmt_pr(0's, Arg, Number) :-
	putn_list(Number, Arg).

putn(0, _) :- !.
putn(N, C) :-
	N>0, N1 is N-1,
	Char is integer(C),
	put_code(Char),
	putn(N1, C).

putn_list(0, _) :- !.
putn_list(N, []) :- !,
	N1 is N-1,
	put_code(0' ),
	putn_list(N1, []).
putn_list(N, [C|Chars]) :-
	N1 is N-1,
	Char is integer(C),
	put_code(Char),
	putn_list(N1, Chars).

%% ---------------------------------------------------------------------------
:- comment(version_maintenance,dir('../version')).

:- comment(version(1*9+212,2003/12/21,02:18*19+'CET'), "Added comment
   author.  (Edison Mera)").

:- comment(version(1*3+27,1999/07/09,20:25*50+'MEST'), "Changed title,
   as texinfo does not allow ':' in titles.  (Daniel Cabeza Gras)").

:- comment(version(0*4+5,1998/2/24), "Synchronized file versions with
   global Ciao version.  (Manuel Hermenegildo)").

:- comment(version(0*1+0,1997/8/21), "Added basic
   documentation. (Manuel Hermenegildo)").
%% ---------------------------------------------------------------------------

