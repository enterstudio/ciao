
BOOL bu1_atom(Argdecl, register TAGGED x0);
BOOL bu1_atomic(Argdecl, register TAGGED x0);
BOOL bu1_float(Argdecl, register TAGGED x0);
BOOL bu1_if(Argdecl, register TAGGED x0);
BOOL bu1_integer(Argdecl, register TAGGED x0);
BOOL bu1_nonvar(Argdecl, register TAGGED x0);
BOOL bu1_number(Argdecl, register TAGGED x0);
BOOL bu1_var(Argdecl, register TAGGED x0);
BOOL bu2_lexeq(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_lexge(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_lexgt(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_lexle(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_lexlt(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_lexne(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_numeq(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_numge(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_numgt(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_numle(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_numlt(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_numne(Argdecl, TAGGED x0, TAGGED x1);
BOOL bu2_univ(Argdecl, register TAGGED term, TAGGED list);
BOOL bu3_functor(Argdecl, register TAGGED term, register TAGGED name, register TAGGED arity);
TAGGED fu2_arg(Argdecl, register TAGGED number, register TAGGED complex);
TAGGED fu2_compare(Argdecl, TAGGED x1, TAGGED x2);