:- use_package([assertions,regtypes]).

:- use_module(library('foreign_interface/foreign_interface_properties')).

:- new_declaration(use_foreign_source/1,on).
:- new_declaration(use_foreign_source/2,on).

:- new_declaration(use_foreign_library/1,on).
:- new_declaration(use_foreign_library/2,on).

:- new_declaration(use_compiler/1, on).
:- new_declaration(use_compiler/2, on).

:- new_declaration(extra_compiler_opts/1,on).
:- new_declaration(extra_compiler_opts/2,on).

:- new_declaration(extra_linker_opts/1,on).
:- new_declaration(extra_linker_opts/2,on).

:- new_declaration(use_linker/1, on).
:- new_declaration(use_linker/2, on).

:- new_declaration(ttr_def/2,on).
:- new_declaration(ttr_match/2,on).

:- use_package(library('foreign_interface/foreign_interface_ttrs')).

