:- module(old_database, [
        recorda/3, recordz/3, recorded/3, current_key/2
			],[assertions,isomodes]).

:- comment(title,"Quintus-like internal database").

:- comment(author,"The CLIP Group").

:- comment(module," The predicates described in this section were
   introduced in early implementations of Prolog to provide efficient
   means of performing operations on large quantities of data.  The
   introduction of indexed dynamic predicates have rendered these
   predicates obsolete, and the sole purpose of providing them is to
   support existing code.  There is no reason whatsoever to use them
   in new code.

   These predicates store arbitrary terms in the database without
   interfering with the clauses which make up the program.  The terms
   which are stored in this way can subsequently be retrieved via the
   key on which they were stored.  Many terms may be stored on the
   same key, and they can be individually accessed by pattern
   matching.  Alternatively, access can be achieved via a special
   identifier which uniquely identifies each recorded term and which
   is returned when the term is stored.  ").

:- data '$current instance'/2.

:- comment(recorda(Key,Term,Ref), "The term @var{Term} is recorded
	in the internal database as the first item for the key
	@var{Key}, where @var{Ref} is its implementation-defined
	identifier.  The key must be given, and only its principal
	functor is significant.  Any uninstantiated variables in the
	@var{Term} will be replaced by new private variables, along
	with copies of any subgoals blocked on these
	variables.").

:- true pred recorda(+Key,?Term,-Ref) + native.

recorda(Key, Term, Ref) :-
        nonvar(Key),
	copy_functor(Key, Key0),
	asserta_fact('$current instance'(Key0, Term), Ref).
	
:- comment(recordz(Key,Term,Ref),"Like @tt{recorda/3}, except that
        the new term becomes the @em{last} item for the key @var{Key}.").

:- true pred recordz(+Key,?Term,-Ref) + native.

recordz(Key, Term, Ref) :-
        nonvar(Key),
	copy_functor(Key, Key0),
	assertz_fact('$current instance'(Key0, Term), Ref).

:- comment(recorded(Key,Term,Ref), "The internal database is
	searched for terms recorded under the key @var{Key}.  These
	terms are successively unified with @var{Term} in the order
	they occur in the database.  At the same time, @var{Ref} is
	unified with the implementation-defined identifier uniquely
	identifying the recorded item.  If the key is instantiated to
	a compound term, only its principal functor is significant.
	If the key is uninstantiated, all terms in the database are
	successively unified with @var{Term} in the order they
	occur.").

:- true pred recorded(?Key,?Term,?Ref) + native.

recorded(Key, Term, Ref) :-
        current_fact('$current instance'(Key, Term), Ref).

:- comment(current_key(KeyName,KeyTerm),"@var{KeyTerm} is the most
	general form of the key for a currently recorded term, and
	@var{KeyName} is the name of that key.  This predicate can be
	used to enumerate in undefined order all keys for currently
	recorded terms through backtracking.").

:- true pred current_key(?Name,?Key) + native.

current_key(Name, Key) :-
        current_fact('$current instance'(Key, _)),
	functor(Key, Name, _).

copy_functor(From, To) :-
	functor(From, N, A),
	functor(To, N, A).

:- comment(version(1*9+213,2003/12/21,02:20*13+'CET'), "Added comment
   author.  (Edison Mera)").

:- comment(version(1*9+110,2003/09/25,21:32*13+'CEST'), "Changed comp
   to pred, moved modes there from the comment directives.  (Francisco
   Bueno Carrillo)").

:- comment(version(1*9+100,2003/08/28,20:45*58+'CEST'), "Added
   assertions for analysis. (German Puebla)").

:- comment(version(0*4+5,1998/2/24), "Synchronized file versions with
   global CIAO version.  (Manuel Hermenegildo)").

%% Version comment prompting control for this file.
%% Local Variables: 
%% mode: CIAO
%% update-version-comments: "../version"
%% End: