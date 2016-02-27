:- module(persdbrt,
        [passerta_fact/1, 
         passertz_fact/1, 
	 pretract_fact/1, 
         asserta_fact/1, 
         assertz_fact/1, 
	 retract_fact/1, 
         init_persdb/0, 
	 initialize_db/0,
	 make_persistent/2,
	 update_files/0,
	 update_files/1],
        [assertions,regtypes]).

:- use_module(engine(internals), [term_to_meta/2]).
:- use_module(library(lists)).
:- use_module(library(streams)).
:- use_module(library(read)).
:- use_module(library(aggregates), [findall/3]).
:- use_module(library(system)).
:- use_module(library(file_locks)).
%:- use_module(engine(basic_props)).

% Not sure about this (DCG)
% :- comment(bug,"make_persistent/2 should really be persistent/2 (since
%    it doesn't really make a predicate persistent but rather declares
%    it as such, i.e., we do not use make_data/1, we use data/1) ?").

:- comment(bug,"To load in the toplevel a file which uses this package,
   module @tt{library('persdb/persdbrt')} has to be previously loaded.").

%% ---------------------------------------------------------------------------
:- comment(title, "Persistent predicate database").

:- comment(subtitle,"A Generic Database Interface").

:- comment(author, "J.M. Gomez, D. Cabeza, and M. Hermenegildo").
:- comment(author, "@tt{clip@@dia.fi.upm.es}").
:- comment(author, "@tt{http://www.clip.dia.fi.upm.es/}").
:- comment(author, "The CLIP Group").
:- comment(author, "Facultad de Inform@'{a}tica").
:- comment(author, "Universidad Polit@'{e}cnica de Madrid").

:- comment(copyright,"
Copyright @copyright{} 1997-2000 The Clip Group.

@include{Copyright.Manuals}
").

:- comment(summary,"This library provides a means to define and modify
   @em{persistent predicates}. A persistent predicate is a relation
   such that any updates made to it from a program remain even after
   the execution of that program terminates.  Persistent predicates
   appear to a program as ordinary predicates, but their definitions
   are stored in files which are automatically maintained by the
   library. Any changes to the persistent predicates are recorded
   atomically and transactionally in these files. This essentially
   implements a light-weight, simple, and at the same time powerful
   deductive database, which is accessed via a generic data access
   method.  A companion library (@lib{persdb_sql}) provides a similar
   notion of persistence but uses external relational databases as
   storage instead. This essentially provides a high-level programmer
   interface, using the same generic data access method, to relational
   databases.").

:- comment(module,"

   @section{Introduction to persistent predicates}

   This library implements a @em{generic persistent predicate
   database}. The basic notion implemented by the library is that of a
   @concept{persistent predicate}. The persistent predicate concept
   provides a simple, yet powerful generic persistent data access
   method @cite{radioweb-D3.1.M1-A1,radioweb-ta}. A persistent
   predicate is a special kind of dynamic, data predicate that
   ``resides'' in some persistent medium (such as a set of files, a
   database, etc.) that is typically external to the program using
   such predicates. The main effect is that any changes made to to a
   persistent predicate from a program ``survive'' across
   executions. I.e., if the program is halted and restarted the
   predicate that the new process sees is in precisely the same state
   as it was when the old process was halted (provided no change was
   made in the meantime to the storage by other processes or the
   user).

   Persistent predicates appear to a program as ordinary predicates,
   and calls to these predicates can appear in clause bodies in the
   usual way. However, the definitions of these predicates do not
   appear in the program. Instead, the library maintains automatically
   the definitions of predicates which have been declared as
   persistent in the persistent storage. 

   @concept{Updates to persistent predicates} can be made using enhanced
   versions of @pred{asserta_fact/1}, @pred{assertz_fact/1} and
   @pred{retract_fact/1}.  The library makes sure that each update is a
   @concept{transactional update}, in the sense that if the update
   terminates, then the permanent storage has definitely been modified.
   For example, if the program making the updates is halted just after
   the update and then restarted, then the updated state of the
   predicate will be seen. This provides security against possible data
   loss due to, for example, a system crash.  Also, due to the atomicity
   of the transactions, persistent predicates allow @concept{concurrent
   updates} from several programs.

   @section{Persistent predicates, files, and relational databases}

   The concept of persistent predicates provided by this library
   essentially implements a light-weight, simple, and at the same time
   powerful form of relational database (a @concept{deductive
   database}), and which is standalone, in the sense that it does not
   require external support, other than the file management
   capabilities provided by the operating system.  This is due to the
   fact that the persistent predicates are in fact stored in one or
   more auxiliary files below a given directory.

   This type of database is specially useful when building small to
   medium-sized standalone applications in Prolog which require
   persistent storage. In many cases it provides a much easier way of
   implementing such storage than using files under direct program
   control. For example, interactive applications can use persistent
   predicates to represent their internal state in a way that is close
   to the application. The persistence of such predicates then allows
   automatically restoring the state to that at the end of a previous
   session. Using persistent predicates amounts to simply declaring
   some predicates as such and eliminates having to worry about
   opening files, closing them, recovering from system crashes, etc.

   In other cases, however, it may be convenient to use a relational
   database as persistent storage. This may be the case, for example,
   when the data already resides in such a database (where it is
   perhaps accessed also by other applications) or the volume of data
   is very large. @lib{persdb_sql} @cite{radioweb-D3.1.M2-A2} is a
   companion library which implements the same notion of persistent
   predicates used herein, but keeping the storage in a relational
   database. This provides a very natural and transparent way to
   access SQL database relations from a Prolog program. In that
   library, facilities are also provided for reflecting more complex
   @em{views} of the database relations as predicates. Such views can
   be constructed as conjunctions, disjunctions, projections, etc. of
   database relations, and may include SQL-like aggregation
   operations.

   A nice characteristic of the notion of persistent predicates used
   in both of these libraries is that it abstracts away how the
   predicate is actually stored. Thus, a program can use persistent
   predicates stored in files or in external relational databases
   interchangeably, and the type of storage used for a given predicate
   can be changed without having to modify the program (except for
   replacing the corresponding @pred{persistent/2} declarations).

   An example application of the @lib{persdb} and @lib{persdb_sql}
   libraries (and also the @lib{pillow} library @cite{pillow-www6}),
   @comment{should be pillow-ws, but formats weird}is @apl{WebDB}
   @cite{radioweb-D3.1.M2-A3}. @apl{WebDB} is a generic, highly
   customizable @em{deductive database engine} with an @em{html
   interface}. @apl{WebDB} allows creating and maintaining
   Prolog-based databases as well as relational databases (residing in
   conventional relational database engines) using any standard WWW
   browser.

   @section{Using file-based persistent predicates}

   Persistent predicates can be declared statically, using
   @decl{persistent/2} declarations (which is the preferred method,
   when possible), or dynamically via calls to
   @pred{make_persistent/2}.  Currently, persistent predicates may
   only contain facts, i.e., they are @em{dynamic} predicates of type
   @pred{data/1}.

   Predicates declared as persistent are linked to a directory, and
   the persistent state of the predicate will be kept in several files
   below that directory.  The files in which the persistent predicates
   are stored are in readable, plain ASCII format, and in Prolog
   syntax. One advantage of this approach is that such files can also
   be created or edited by hand, in a text editor, or even by other
   applications.

   An example definition of a persistent predicate implemented by files
   follows:

@begin{verbatim}
:- persistent(p/3,dbdir).

persistent_dir(dbdir, '/home/clip/public_html/db').
@end{verbatim}

   The first line declares the predicate @tt{p/3} persistent.  The
   argument @tt{dbdir} is a key used to index into a fact of the
   relation @pred{persistent_dir/2}, which specifies the directory
   where the corresponding files will be kept.  The effect of the
   declaration, together with the @pred{persistent_dir/2} fact, is
   that, although the predicate is handled in the same way as a normal
   data predicate, in addition the system will create and maintain
   efficiently a persistent version of @tt{p/3} via files in the
   directory @tt{/home/clip/public_html/db}.

   The level of indirection provided by the @tt{dbdir} argument makes
   it easy to place the storage of several persistent predicates in a
   common directory, by specifying the same key for all of them.  It
   also allows changing the directory for several such persistent
   predicates by modifying only one fact in the program. Furthermore,
   the @pred{persistent_dir/2} predicate can even be dynamic and
   specified at run-time.

   @section{Implementation Issues}

   We outline the current implementation approach.  This
   implementation attempts to provide at the same time efficiency and
   security. To this end, up to three files are used for each
   predicate (the @concept{persistence set}): the @concept{data file},
   the @concept{operations file}, and the @concept{backup file}. In
   the @concept{updated state} the facts (tuples) that define the
   predicate are stored in the data file and the operations file is
   empty (the backup file, which contains a security copy of the data
   file, may or may not exist).

   While a program using a persistent predicate is running, any
   insertion (assert) or deletion (retract) operations on the
   predicate are performed on both the program memory and on the
   persistence set. However, in order to incurr only a small overhead
   in the execution, rather than changing the data file directly, a
   record of each of the insertion and deletion operations is
   @em{appended} to the operations file. The predicate is then in a
   @concept{transient state}, in that the contents of the data file do
   not reflect exactly the current state of the corresponding
   predicate. However, the complete persistence set does.

   When a program starts, all pending operations in the operations file
   are performed on the data file. A backup of the data file is created
   first to prevent data loss if the system crashes during this
   operation.  The order in which this updating of files is done ensures
   that, if at any point the process dies, on restart the data will be
   completely recovered. This process of updating the persistence set
   can also be triggered at any point in the execution of the program
   (for example, when halting) by calling @pred{update_files}.

   @section{Defining an initial database}

   It is possible to define an initial database by simply including in
   the program code facts of persistent predicates.  They will be
   included in the persistent database when it is created.  They are
   ignored in successive executions.

   @section{Using persistent predicates from the top level}

   Special care must be taken when loading into the top level modules or
   user files which use persistent predicates.  Beforehand, a goal
   @tt{use_module(library('persdb/persdbrt'))} must be issued.
   Furthermore, since persistent predicates defined by the loaded files
   are in this way defined dynamically, a call to @pred{initialize_db/0}
   is commonly needed after loading and before calling predicates of
   these files.
").

:- comment(usage, "There are two packages which implement persistence:
   @lib{persdb} and @lib{'persdb/ll'} (for low level).  In the first,
   the standard builtins @pred{asserta_fact/1}, @pred{assertz_fact/1},
   and @pred{retract_fact/1} are replaced by new versions which handle
   persistent data predicates, behaving as usual for normal data
   predicates.  In the second package, predicates with names starting
   with @tt{p} are defined, so that there is not overhead in calling the
   standard builtins.  In any case, each package is used as usual:
   including it in the package list of the module, or using the
   @decl{use_package/1} declaration.").

:- comment(doinclude,persistent/2).
:- decl persistent(PredDesc,Keyword) => predname * keyword

# "Declares the predicate @var{PredDesc} as persistent. @var{Keyword} is
   the @concept{identifier of a location} where the persistent storage
   for the predicate is kept. The location @var{Keyword} is described in
   the @pred{persistent_dir} predicate, which must contain a fact in
   which the first argument unifies with @var{Keyword}.".
%% This declaration is expanded in persdbtr 

:- data persistent/5. % F/A (modulo expanded) is persistent and uses files
                      % FILE_OPS, FILE and FILE_BAK

:- pred persistent_dir(Keyword,Location_Path) :  keyword * directoryname

# "Relates identifiers of locations (the @var{Keyword}s) with
   descriptions of such locations (@var{Location_Path}s).
   @var{Location_Path} is @bf{a directory} and it means that the
   definition for the persistent predicates associated with
   @var{Keyword} is kept in files below that directory (which must
   exist). These files, in the updated state, contain the actual
   definition of the predicate in Prolog syntax (but with module names
   resolved).".

%% Note: declared by package persdb as multifile and data
:- multifile persistent_dir/2.
:- data persistent_dir/2.

:- meta_predicate passerta_fact(fact).

% passerta_fact(P, D) asserts a predicate in both the dynamic and the
% persistent databases.  
:- pred passerta_fact(Fact) : callable
# "Persistent version of @pred{asserta_fact/1}: the current instance of
   @var{Fact} is interpreted as a fact (i.e., a relation tuple) and is
   added at the beginning of the definition of the corresponding
   predicate.  The predicate concerned must be declared
   @decl{persistent}.  Any uninstantiated variables in the @var{Fact}
   will be replaced by new, private variables.  Defined in the
   @lib{'persdb/ll'} package.".

passerta_fact(MPred):-
        term_to_meta(Pred, MPred),
        functor(Pred, F, N),
        current_fact(persistent(F, N, File_ops, _, File_bak)), !,
        delete_bak_if_no_ops(File_ops, File_bak),
        add_term_to_file(a(Pred), File_ops),
        data_facts:asserta_fact(MPred).
passerta_fact(MPred):-
        term_to_meta(Pred, MPred),
        throw(error(type_error(persistent_data,Pred), passerta_fact/2-1)).

:- meta_predicate asserta_fact(fact).

:- pred asserta_fact(Fact) : callable
# "Same as @pred{passerta_fact/1}, but if the predicate concerned is not
   persistent then behaves as the builtin of the same name.  Defined in the
   @lib{persdb} package.".

asserta_fact(MPred):-
        term_to_meta(Pred, MPred),
        functor(Pred, F, N),
        ( current_fact(persistent(F, N, File_ops, _, File_bak)) ->
            delete_bak_if_no_ops(File_ops, File_bak),
            add_term_to_file(a(Pred), File_ops)
        ; true),
        data_facts:asserta_fact(MPred).

:- meta_predicate passertz_fact(fact).

% passertz_fact(P, D) asserts a predicate in both the dynamic and the
% persistent databases.  
:- pred passertz_fact(Fact) : callable
# "Persistent version of @pred{assertz_fact/1}: the current instance of
   @var{Fact} is interpreted as a fact (i.e., a relation tuple) and is
   added at the end of the definition of the corresponding predicate.
   The predicate concerned must be declared @decl{persistent}.  Any
   uninstantiated variables in the @var{Fact} will be replaced by new,
   private variables.  Defined in the @lib{'persdb/ll'} package.".

passertz_fact(MPred):-
        term_to_meta(Pred, MPred),
        functor(Pred, F, N),
        current_fact(persistent(F, N, File_ops, _, File_bak)), !,
        delete_bak_if_no_ops(File_ops, File_bak),
        add_term_to_file(z(Pred), File_ops),
        data_facts:assertz_fact(MPred).
passertz_fact(MPred):-
        term_to_meta(Pred, MPred),
        throw(error(type_error(persistent_data,Pred), passertz_fact/2-1)).

:- meta_predicate assertz_fact(fact).

:- pred assertz_fact(Fact) : callable
# "Same as @pred{passertz_fact/1}, but if the predicate concerned is not
   persistent then behaves as the builtin of the same name.  Defined in the
   @lib{persdb} package.".

assertz_fact(MPred):-
        term_to_meta(Pred, MPred),
        functor(Pred, F, N),
        ( current_fact(persistent(F, N, File_ops, _, File_bak)) ->
            delete_bak_if_no_ops(File_ops, File_bak),
            add_term_to_file(z(Pred), File_ops)
        ; true),
        data_facts:assertz_fact(MPred).

:- pred pretract_fact(Fact) : callable
# "Persistent version of @pred{retract_fact/1}: deletes on backtracking
   all the facts which unify with @var{Fact}.  The predicate concerned
   must be declared @decl{persistent}.  Defined in the @lib{'persdb/ll'}
   package.".

:- meta_predicate pretract_fact(fact).

% pretract_fact(P) retracts a predicate in both, the dynamic and the 
% persistent databases.
pretract_fact(MPred):-
        term_to_meta(Pred, MPred),
        functor(Pred, F, N),
        current_fact(persistent(F, N, File_ops, _, File_bak)), !,
        delete_bak_if_no_ops(File_ops, File_bak),
        data_facts:retract_fact(MPred),
        add_term_to_file(r(Pred), File_ops).
pretract_fact(MPred):-
        term_to_meta(Pred, MPred),
        throw(error(type_error(persistent_data,Pred), pretract_fact/2-1)).

:- pred retract_fact(Fact) : callable
# "Same as @pred{pretract_fact/1}, but if the predicate concerned is not
   persistent then behaves as the builtin of the same name.  Defined in the
   @lib{persdb} package.".

:- meta_predicate retract_fact(fact).

retract_fact(MPred):-
        term_to_meta(Pred, MPred),
        functor(Pred, F, N),
        ( current_fact(persistent(F, N, File_ops, _, File_bak)) ->
            delete_bak_if_no_ops(File_ops, File_bak),
            data_facts:retract_fact(MPred),
            add_term_to_file(r(Pred), File_ops)
        ; data_facts:retract_fact(MPred)
        ).

:- data db_initialized/0.

:- comment(hide, init_persdb/0).

:- pred init_persdb # "Executes @pred{initialize_db/0} if no
   initialization has been done yet.  Invoked by a @tt{initialization/1}
   directive in the package code.  Not meant to be explicitly used in
   user code.".

init_persdb :-
        current_fact(db_initialized), !.
init_persdb :-
        initialize_db,
        data_facts:assertz_fact(db_initialized).

:- comment(hide, '$is_persistent'/2).

:- multifile '$is_persistent'/2.
:- data '$is_persistent'/2.

:- pred initialize_db # "@cindex{database initialization} Initializes
   the whole database, updating the state of the declared persistent
   predicates.  Must be called explicitly after dynamically defining
   clauses for @pred{persistent_dir/2}.".

% Note: not using current_fact/2 and erase/1 because does not work in toplevel
initialize_db :-
        '$is_persistent'(Spec, Key),
        make_persistent(Spec, Key),
        data_facts:retract_fact('$is_persistent'(Spec, Key)),
        fail.
initialize_db.

:- pred make_persistent(PredDesc,Keyword) : predname * keyword
# "Dynamic version of the @decl{persistent} declaration.".

:- meta_predicate make_persistent(spec, ?).

make_persistent(Spec, Key) :-
        persistent_dir(Key, Dir),
        term_to_meta(F/A, Spec),
        get_pred_files(Dir, F, A, File, File_ops, File_bak),
        data_facts:assertz_fact(persistent(F, A, File_ops, File, File_bak)),
        functor(P, F, A),
        ini_persistent(P, File_ops, File, File_bak).

ini_persistent(P, File_ops, File, File_bak):- 
        term_to_meta(P, Pred),
        lock_file(File, Fd1, _),        
        lock_file(File_ops, Fd2, _),    
        lock_file(File_bak, Fd3, _),
        ( file_exists(File) ->
            ( file_exists(File_bak) ->
                ( file_exists(File_ops) ->  % Operations maybe not concluded
                    delete_file1(File),
                    mv(File_bak, File),
                    secure_update(File, File_ops, File_bak, NewTerms)
                ; delete_file1(File_bak), % operations done
                  file_to_term_list(File, NewTerms, [])
                )
            ; secure_update(File, File_ops, File_bak, NewTerms)
            ),
            retractall_fact(Pred)
        ; file_exists(File_bak) -> % System crash
            mv(File_bak, File),
            secure_update(File, File_ops, File_bak, NewTerms),
            retractall_fact(Pred)
        ; % Files not created yet
          findall(P, current_fact(Pred), Facts),
          term_list_to_file(Facts, File),
          NewTerms = []
        ),
        unlock_file(Fd1, _),
        unlock_file(Fd2, _),
        unlock_file(Fd3, _),
        process_terms(NewTerms).

% Steps in the process of updating:
%  f  o
%     o  b
%  f+ o  b
%  f+    b
%  f+

secure_update(File, File_ops, File_bak, NewTerms):-
        file_to_term_list(File, Terms, Terms_),
        ( file_exists(File_ops) ->
            file_to_term_list(File_ops, Lops, []),
            make_operations(Lops, Terms, Terms_, NewTerms),
            mv(File, File_bak),
            term_list_to_file(NewTerms, File),
            delete_file1(File_ops),
            delete_file1(File_bak)
        ; Terms_ = [],
          NewTerms = Terms
        ).

make_operations([], Terms, [], Terms).
make_operations([Operation|Operations], Terms, Terms_, NewTerms):-
        make_operation(Operation, Terms, Terms_, NTerms, NTerms_),
        make_operations(Operations, NTerms, NTerms_, NewTerms).

% Adds a fact to the head of the list
make_operation(a(Pred), Terms, Terms_, [Pred|Terms], Terms_).
% Adds a fact to the tail of the list
make_operation(z(Pred), Terms, [Pred|Terms_], Terms, Terms_).
% Removes the first fact which unify (exists)
make_operation(r(Pred), Terms, Terms_, NTerms, Terms_) :-
        select(Pred, Terms, NTerms), !.

% process_terms(Facts) asserts the data contained in Facts into the
%  dynamic database

process_terms([]).
process_terms([Fact|Facts]) :-
        term_to_meta(Fact, MFact),
        data_facts:assertz_fact(MFact),
        process_terms(Facts).

:- pred update_files # "Updates the files comprising the persistence set
   of all persistent predicates defined in the application.".

update_files :- update_files_of(_, _).

:- pred update_files(PredSpecList) :: list(predname)
# "Updates the files comprising the persistence set of the persistent
   predicates in @var{PredSpecList}.".

:- meta_predicate update_files(list(spec)).

update_files([]) :- !.
update_files([Spec|SpecL]) :-
        term_to_meta(F/A, Spec),
        update_files_of(F, A), !,
        update_files(SpecL).
update_files(Bad) :-
        throw(error(type_error(list(predname), Bad), update_files/1-1)).

update_files_of(Pred, Arity) :-
        current_fact(persistent(Pred, Arity, File_ops, File, File_bak)),
        lock_file(File, Fd1, _),        
        lock_file(File_ops, Fd2, _),    
        lock_file(File_bak, Fd3, _),
        ( file_exists(File) ->
            ( file_exists(File_bak) ->
                ( file_exists(File_ops) ->  % Operations maybe not concluded
                    delete_file1(File),
                    mv(File_bak, File),
                    secure_update(File, File_ops, File_bak, _)
                ; delete_file1(File_bak) % operations done
                )
            ; secure_update(File, File_ops, File_bak, _)
            )
        ; mv(File_bak, File), % System crash
          secure_update(File, File_ops, File_bak, _)
        ),
        unlock_file(Fd1, _),
        unlock_file(Fd2, _),
        unlock_file(Fd3, _),
        fail.
update_files_of(_, _).
       

% file_to_term_list(File, Terms, Terms_) reads a list of terms Terms from a
%  file File, Terms_ is the tail of the list
file_to_term_list(File, Terms, Terms_) :-
        file_exists(File, 6), !,
        current_input(OldInput),
        open(File, read, Stream),
        set_input(Stream),
        read(T),
        read_terms(T, Terms, Terms_),
        set_input(OldInput),
        close(Stream).
file_to_term_list(_File, Terms, Terms).

read_terms(end_of_file, Ts, Ts) :- !.
read_terms(T, [T|Ts], Ts_) :-
        read(T1),
        read_terms(T1, Ts, Ts_).

% term_list_to_file(Terms, File) writes a list of terms Terms onto a file
%  File
term_list_to_file(Terms, File) :-
        current_output(OldOutput),
        open(File, write, Stream),
        set_output(Stream),
        display_term_list(Terms),
        close(Stream),
        set_output(OldOutput).    

display_term_list([]).
display_term_list([T|Ts]) :-
        display_term(T),
        display_term_list(Ts).

% This ensure that we not create an operations file in a transient state
delete_bak_if_no_ops(File_ops, File_bak) :-
        ( file_exists(File_ops) -> true
	; file_exists(File_bak) -> delete_file1(File_bak)
	; true).

% add_term_to_file(Term,File) adds the term Term to a file File
add_term_to_file(Term,File) :-
        current_output(OldOutput),
        lock_file(File, FD, _),
        open(File,append,Stream),
        set_output(Stream),
        display_term(Term),
        close(Stream),
        unlock_file(FD, _),
        set_output(OldOutput).        

get_pred_files(Dir, Name, Arity, File, File_ops, File_bak):-
        add_final_slash(Dir, DIR),
        atom_codes(Name, NameString),
        append(Module,":"||PredName,NameString),
        atom_codes(Mod, Module),
        atom_concat(DIR, Mod, DirMod),
        create_dir(DirMod),
        number_codes(Arity, AS),
        append("/"||PredName, "_"||AS, FilePrefS),
        atom_codes(FilePref, FilePrefS),
        atom_concat(DirMod, FilePref, PathName),
        atom_concat(PathName, '.pl', File),
        atom_concat(PathName, '_ops.pl', File_ops),
        atom_concat(PathName, '_bak.pl', File_bak).

create_dir(Dir) :-
        file_exists(Dir), !.  % Supposing it's a directory
create_dir(Dir) :-
        make_directory(Dir, 0xfff).

delete_file1(File):-
	(file_exists(File)->
	 delete_file(File)
	;
	 true).

% :- pred mv(Path1, Path2) ; "Rename a file, or create target.".
mv(Source, Target):-
        file_exists(Source), !,
        rename_file(Source, Target).
mv(_Source, Target):-
        create(Target).


% :- pred create(Path) ; "Creates a file.".
create(Path):-
        umask(OldUmask, 0),
        open(Path, write, S),
        close(S),
        umask(_, OldUmask).

add_final_slash(Dir, DIR) :-
        atom_concat(_,'/',Dir) -> DIR = Dir ; atom_concat(Dir, '/', DIR).

:- comment(doinclude, keyword/1).

:- comment(keyword/1,"An atom which identifies a fact of the
   @pred{persistent_dir/2} relation. This fact relates this atom to a
   directory in which the persistent storage for one or more
   persistent predicates is kept.").

:- prop keyword(X) + regtype 
# "@var{X} is an atom corresponding to a directory identifier.".

keyword(X) :- atm(X).

:- comment(doinclude, directoryname/1).

:- prop directoryname(X) + regtype 
# "@var{X} is an atom, the name of a directory.".

directoryname(X) :- atm(X).

%% ---------------------------------------------------------------------------
:- comment(version_maintenance,dir('../../version')).

:- comment(version(1*7+96,2001/05/02,12:29*31+'CEST'), "Documentation
   on the @dec{persistent/2} declaration now appears in manuals.
   (Manuel Hermenegildo)").

:- comment(version(1*7+62,2001/03/02,23:00*48+'CET'), "Replaced
   update_files/2 with update_files/1, which handles lists of specs, and
   update_files/0.  (Daniel Cabeza Gras)").

:- comment(version(1*7+31,2000/11/10,17:33*31+'CET'), "Eliminated direct
   uses of UNIX shell commands in /bin (Daniel Cabeza Gras)").

:- comment(version(1*7+20,2000/09/13,17:28*41+'CEST'), "Many improvements:
   @begin{itemize}

   @item Implemented passerta_fact/1 (asserta_fact/1).

   @item Now it is never necessary to explicitly call init_persdb, a call
         to initialize_db is only needed after dynamically defining facts
         of persistent_dir/2.  Thus, pcurrent_fact/1 predicate eliminated.

   @item Facts of persistent predicates included in the program code are
         now included in the persistent database when it is created.
         They are ignored in successive executions.

   @item Files where persistent predicates reside are now created inside
         a directory named as the module where the persistent predicates
         are defined, and are named as F_A* for predicate F/A.

   @item Now there are two packages: persdb and 'persdb/ll' (for low
         level).  In the first, the standard builtins asserta_fact/1,
         assertz_fact/1, and retract_fact/1 are replaced by new versions
         which handle persistent data predicates, behaving as usual for
         normal data predicates.  In the second package, predicates with
         names starting with 'p' are defined, so that there is not
         overhead in calling the standard builtins.

   @item Needed declarations for persistent_dir/2 are now included in
         the packages.

   @end{itemize}
   (Daniel Cabeza Gras)").

:- comment(version(0*8+31,1998/12/27,19:17*20+'MET'), "Localized most
   of the documentation in this file. Updated documentation.  (Manuel
   Hermenegildo)").
%% ---------------------------------------------------------------------------
