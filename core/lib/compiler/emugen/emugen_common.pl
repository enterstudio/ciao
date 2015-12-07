:- module(emugen_common, [], [dcg, fsyntax, assertions]).

:- doc(title, "Auxiliary for Emulator Generation").
:- doc(author, "Jose F. Morales").

:- doc(module, "Auxiliary definitions for emulator code generation and
   build.").

:- use_module(library(pathnames), [path_concat/3]).
:- use_module(ciaobld(config_common), % TODO: Move to paths_extra?
	[bld_eng_path/4,
	 eng_h_alias/2]).

:- export(emugen_code_dir/3).
% Directory where autogenerated File goes in the build area of EngMainMod
emugen_code_dir(EngMainMod, File, DestDir) :-
	( atom_concat(_, '.h', File) ->
	    eng_h_alias(EngMainMod, HAlias),
	    DestDir = ~path_concat(~bld_eng_path(hdir, build, EngMainMod), HAlias)
	; DestDir = ~bld_eng_path(cdir, build, EngMainMod)
	).

