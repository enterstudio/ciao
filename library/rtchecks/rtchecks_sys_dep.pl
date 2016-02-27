%% system_dependent_compatible(Prop):-
%% 	fail.
% Next definition requires the system to be "quick rejecting". 
% I. e., those states which are inconsistent should always be rejected.
system_dependent_compatible(Prop):-
	\+ \+ callme(Prop).

% This definition works in any system
system_dependent_incompatible(Prop):-
	\+ callme(Prop).

%% system_dependent_entailed(Prop):-
%% 	fail.
% This is correct everywhere, but only useful if Prop does not contain dvars
system_dependent_entailed(Prop):-
	copy_term(Prop,NProp),
	callme(NProp),!,  
	instance(Prop,NProp).

% This is correct and useful in any system
system_dependent_disentailed(Prop):-
	system_dependent_incompatible(Prop),!.
% This is only correct for complete solvers (such as herbrand)
system_dependent_disentailed(Prop):-
	copy_term(Prop,NProp),
	callme(NProp),!, 
	\+ instance(Prop,NProp),
	instance(NProp,Prop).
