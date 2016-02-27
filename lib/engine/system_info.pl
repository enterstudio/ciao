%%---------------------------------------------------------------------

:- module(system_info, [
        get_arch/1,
        get_os/1,
        this_module/1,
        current_module/1,
        ciaolibdir/1],
        [assertions, isomodes]).

%%---------------------------------------------------------------------

:- comment(title,"Gathering some basic internal info").

:- comment(author,"Daniel Cabeza, Manuel Carro").

:- comment(usage, "These predicates are builtin in CIAO, so nothing special
   has to be done to use them.").

:- comment(module,"............... In development ...............").

%%---------------------------------------------------------------------

:- impl_defined([
        get_arch/1,
        get_os/1,
        this_module/1,
        current_module/1,
        ciaolibdir/1]).

%%---------------------------------------------------------------------

:- comment(internal_module_id/1, "For a user file it is a term user/1
	with an argument different for each user file, for
	other modules is just the name of the module (as an atom).").

:- prop internal_module_id(M) #
	"@var{M} is an internal module identifier".

internal_module_id(user(M)) :-
	atm(M).
internal_module_id(M) :- 
	atm(M).

:- comment(doinclude,internal_module_id/1).

%%---------------------------------------------------------------------

:- true pred get_arch(?ArchDescriptor) :: atm #
	"Unifies @var{ArchDescriptor} with a simple atom which describes
         the computer architecture currently executing the predicate.".

:- comment(get_arch/1,
	"This predicate will describe the computer architecture wich
         is currently executing the predicate.

         Computer architectures are identified by a simple atom.
         This atom is implementation-defined, and may suffer any change
         from one CIAO Prolog version to another.

         For example,CIAO Prolog running on an Intel-based machine 
         will retrieve:
@begin{verbatim}
?- get_arch(I).

I = i86 ? ;

no
?- 
@end{verbatim}
	").


%%---------------------------------------------------------------------

:- true pred get_os(?OsDescriptor) :: atm #
	"Unifies @var{OsDescriptor} with a simple atom which describes
         the running Operating System when predicate was called.".

:- comment(get_os/1,
	"This predicate will describe the Operating System which 
         is running on the machine currently executing the Prolog program.

         Operating Systems are identified by a simple atom.
         This atom is implementation-defined, and may suffer any change
         from one CIAO Prolog version to another.

         For example,CIAO Prolog running on Linux will retrieve:
@begin{verbatim}
?- get_os(I).

I = 'LINUX' ? ;

no
?- 
@end{verbatim}
	").

%%---------------------------------------------------------------------

:- pred current_module(Module) :: atm #
	"Retrieves (on backtracking) all currently loaded modules into
         your application.".

:- comment(current_module/1,
	"This predicate will successively unify its argument with all
	 module names currently loaded. Module names will be simple atoms.

         When called using a free variable as argument, it will
         retrieve on backtracking all modules currently loaded. This is 
         usefull when called from the CIAO @apl{toplevel}.

         When called using a module name as argument it will check whether
         the given module is loaded or not. This is usefull when called
         from user programs.
        ").

%%---------------------------------------------------------------------

:- pred ciaolibdir(CiaoPath) :: atm(CiaoPath) #
	"@var{CiaoPath} is the path to the root of the Ciao
	libraries. Inside this directory, there are the directories
	'lib', 'library' and 'contrib', which contain library modules.".

%%---------------------------------------------------------------------

:- meta_predicate this_module(addmodule).

this_module(M, M).

:- pred this_module(internal_module_id) #
	"@var{Module} is the internal module identifier for current module.".

:- comment(version_maintenance,dir('../../version')).

:- comment(version(1*3+13,1999/07/02,18:49*49+'MEST'), "Updated
   documentation (Daniel Cabeza Gras)").

:- comment(version(0*9+92,1999/05/14,20:58*45+'MEST'), "Changed
   this_module/1 to be as before. (Daniel Cabeza Gras)").

:- comment(version(0*9+88,1999/05/10,20:48*42+'MEST'), "Added documentation
   on predicates (Angel Fernandez Pineda)").

:- comment(version(0*9+87,1999/05/10,20:46*28+'MEST'), "Changed
   this_module/1 to return 'user' instead of user(...).
   (Daniel Cabeza Gras)").

:- comment(version(0*9+71,1999/04/30,11:41*22+'MEST'), "Added get_os/1.(MCL)").

