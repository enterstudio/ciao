:- module(builtin_directives, [], [assertions]).

% ----------------------------------------------------------------------------
:- comment(title, "Basic builtin directives").

:- comment(author, "Daniel Cabeza").

:- comment(usage, "These directives are builtin in CIAO, so nothing special
   has to be done to use them.").

:- comment(module, "This chapter documents the basic @concept{builtin
   directives} in CIAO, additional to the documented in other chapters.
   These @concept{directives} are natively interpreted by the CIAO
   compiler (@apl{ciaoc}).

   Unlike in other Prolog systems, directives in CIAO are not goals to
   be @em{executed} by the compiler or top level. Instead, they are
   @em{read} and acted upon by these programs. The advantage of this
   is that the effect of the directives is consistent for executables,
   code loaded in the top level, code analyzed by the preprocessor,
   etc. 

   As a result, by default only the builtin directives or declarations
   defined in this manual can be used in user programs. However, it is
   possible to define new declarations @cindex{declarations, user
   defined} by using the @decl{new_declaration/1} and
   @decl{new_declaration/2} directives documented in @ref{Extending the
   syntax}.").

%  ----------------------------------------------------------------------------

:- comment(doinclude,multifile/1).
:- decl multifile(Predicates) : sequence_or_list(predname) + iso
        # "Specifies that each predicate in @var{Predicates} may have
          clauses in more than one file.  Each file that contains
          clauses for a @concept{multifile predicate} must contain a
          directive multifile for the predicate.  The directive should
          precede all clauses of the affected predicates.  This directive
          is defined as a prefix operator in the compiler.".

:- comment(doinclude,discontiguous/1).
:- decl discontiguous(Predicates) : sequence_or_list(predname) + iso
        # "Specifies that each predicate in @var{Predicates} may be
          defined in this file by clauses which are not in consecutive
          order.  Otherwise, a warning is signaled by the compiler when
          clauses of a predicate are not consecutive (this behavior is
          controllable by the @concept{prolog flag}
          @em{discontiguous_warnings}).  The directive should
          precede all clauses of the affected predicates.  This
          directive is defined as a prefix operator in the compiler.".

:- comment(doinclude,impl_defined/1).
:- decl impl_defined(Predicates) : sequence_or_list(predname)
        # "Specifies that each predicate in @var{Predicates} is
          @em{impl}icitly @em{defined} in the current prolog source,
          either because it is a builtin predicate or because it is
          defined in a C file.  Otherwise, a warning is signaled by
          the compiler when an exported predicate is not defined in
          the module or imported from other module.".

:- comment(doinclude,redefining/1).
:- decl redefining(Predicate) : compat(predname)
        # "Specifies that this module redefines predicate
          @var{Predicate}, also imported from other module, or imports
          it from more than one module.  This prevents the compiler
          giving warnings about redefinitions of that predicate.
          @var{Predicate} can be partially (or totally) uninstantiated,
          to allow disabling those warnings for several (or all) predicates at
          once.".

:- comment(doinclude,initialization/1).
:- decl initialization(Goal) : callable + iso
        # "@var{Goal} will be executed at the start of the execution of
          any program containing the current code.".

:- comment(doinclude,on_abort/1).
:- decl on_abort(Goal) : callable
        # "@var{Goal} will be executed after an abort of the execution of
          any program containing the current code.".

% ----------------------------------------------------------------------------
:- comment(version_maintenance,dir('../../version')).

:- comment(version(0*9+11,1999/03/18,21:28*24+'MET'), "Distributed
   documentation of some directives in several modules.  (Daniel Cabeza
   Gras)").

:- comment(version(0*9+6,1999/03/12,18:32*43+'MET'), "Changed syntax/1
   declaration to use_package/1, updated documentation (Daniel Cabeza Gras)").

:- comment(version(0*9+3,1999/03/10,21:37*04+'MET'), "Added
   add_clause_trans/1 declaration (Daniel Cabeza Gras)").
% ----------------------------------------------------------------------------

