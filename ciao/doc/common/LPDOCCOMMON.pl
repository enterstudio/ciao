:- module(_, _, [ciaopaths, fsyntax, assertions]).

:- use_module(library(system)).
:- use_module(library(terms), [atom_concat/2]).
:- use_module(library(component_registry), [component_src/2, component_ins/2]).
:- use_module(ciaodesrc(makedir('ConfigValues'))).

:- reexport(ciaodesrc(makedir('DOCCOMMON'))).

% the component that contains this manual
:- export(parent_component/1).
parent_component := 'ciao'.

% ----------------------------------------------------------------------------
% Paths and options for components

% filepath   := ~atom_concat(~component_ins(ciao), ~ciaofilepath   ).
systempath := ~atom_concat(~component_ins(ciao),   ~ciaosystempath).
systempath := ~atom_concat(~component_ins(ciaopp), '/doc/readmes').

ciaofilepath_common :=
	''|
	'/doc/common'|
	'/doc/readmes'.

ciaosystempath := '/lib'|'/library'|'/contrib'.

index := concept|lib|pred|prop|regtype|decl|author|global.
% index := prop.
% index := modedef.

infodir_headfile := ~atom_concat([~component_ins(ciao),
		'/doc/common/CiaoHead.info']).
infodir_tailfile := ~atom_concat([~component_ins(ciao),
		'/doc/common/CiaoTail.info']).

% commonopts     := '-v'.
% commonopts     := '-nobugs'.
commonopts :=
	'-modes'|
	'-nopatches'|
	'-noisoline'|
	'-noengmods'|
	'-propmods'|
	'-nochangelog'.
doc_mainopts := ~commonopts.
doc_compopts := ~commonopts.

pathsfile := ~atom_concat(~component_ins(ciao), '/doc/common/doc_ops.pl').

startpage := 1.
papertype := afourpaper.

perms := perm(rwX, rwX, rX).

owner := ~get_pwnam.
group := ~get_grnam.

docformat := texi|ps|pdf|manl|info|html.

