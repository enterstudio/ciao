:- load_compilation_module(library(argnames_trans)).
:- add_sentence_trans(argnames_def/3).
:- add_term_trans(argnames_use/3).
:- op(150, xfx, [$]).
:- op(950, xfx, (=>)).
:- op(1150, fx, [argnames]).

% to do: portray of terms with argnames!

%% Version comment prompting control for this file.
%% Local Variables: 
%% mode: CIAO
%% update-version-comments: "off"
%% End:


