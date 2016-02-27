:- package('CCall').

:- use_package(assertions).

:- doc(nodoc, assertions).

:- doc(filetype, package).

:- doc(title,"Support for Tabled Execution").
:- doc(subtitle,"(Using the Continuation Call technique)").

:- doc(author,"Pablo Chico de Guzm�n Huerta").
:- doc(author,"The CLIP Group").

:- doc(usage, "The TABLED_EXECUTION flag must be set to \"yes\"
     in order to compile the engine with support for the tabling
     execution of goals.").

:- doc(module, "This module defines primitives to control tabling
     execution (or SLG execution). By declaring a predicated as
     tabled, a program translation is done to abstract the use of
     these primitives for the user. The implementation tabling
     technique follows the approach of Continuation Calls without
     changing the compiler.

     Adding the @tt{:- tabled} declaration forces the compiler and
     runtime system to distinguish the first occurrence of a tabled
     goal (the @tt{generator}) and subsequent calls which are
     identical up to variable renaming (the @tt{consumers}).  The
     generator applies resolution using the program clauses to derive
     answers for the goal.  Consumers @tt{suspend} the current
     execution path (using implementation-dependent means) and move to
     a different branch.  When such an alternative branch finally
     succeeds, the answer generated for the initial query is inserted
     in a table associated with the original goal. This makes it
     possible to reactivate suspended calls and to continue execution
     at the point where it was stopped. Thus, consumers do not use
     @tt{SLD resolution}, but obtain instead the answers from the
     table where they have been previously inserted by the producer.

     Predicates not marked as tabled are executed following SLD
     resolution, hopefully with (minimal or no) overhead due to the
     availability of tabling in the system.").

:- op(1150, fx, [ table ]).
:- op(1150, fx, [ bridge ]).

:- load_compilation_module(library(tabling('CCall'(tabling_tr_CCall)))).

:- add_sentence_trans(do_term_expansion/3).

:- use_module(library(tabling('CCall'(tabling_rt_CCall)))).

:- use_module(engine(hiord_rt), 
	[
	    '$meta_call'/1
	]).

:- doc(doinclude,tablegoal/1).
:- doc(tablegoal/1,"Represents a predicate daclared as tabled.").

:- doc(doinclude,goal/1).
:- doc(goal/1,"Defines a Prolog goal to be called which is
   generated by @pred{tabled_call/5} primitive. ").

:- doc(doinclude,id/1).
:- doc(id/1,"Defines a table entry identifier for a tabled
   call.").

:- doc(doinclude,pred_name/1).
:- doc(pred_name/1,"Defines the name of a Prolog
   predicate.").

:- doc(doinclude,cont/1).
:- doc(cont/1,"Defines a Prolog goal which represents the
   continuation call of a consumer. ").

:- doc(doinclude,dummy/1).
:- doc(dummy/1,"Defines a dummy argument used to change the general
   structure of a choice point. ").

:- doc(doinclude,bindings/1).
:- doc(bindings/1,"Defines a list of bindings to recover a consumer
   environment. ").

:- doc(doinclude,answer/1).
:- doc(answer/1,"Defines answers for tabled predicates. ").  

:- doc(doinclude,abolish_all_tables/0).
:- doc(doinclude,tabled_call/5).
:- doc(doinclude,resume_ccalls/5).
:- doc(doinclude,new_ccall/6).
:- doc(doinclude,new_answer/2).
:- doc(doinclude,consume_answer/2).
