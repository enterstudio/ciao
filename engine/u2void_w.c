/* Copyright (C) 1996,1997,1998, UPM-CLIP */

	case U2_VOID_XVAR:
		U1_VOID_W(SP1);
		U1_XVAR_W(P2);
		DISPATCH_W(2);

	case U2_VOID_YFVAR:
		ComputeE;
	case U2_VOID_YVAR:
		U1_VOID_W(SP1);
		U1_YVAR_W(P2);
		DISPATCH_W(2);

	case U2_VOID_XVAL:
		U1_VOID_W(SP1);
		U1_XVAL_W(P2);
		DISPATCH_W(2);

	case U2_VOID_XLVAL:
		U1_VOID_W(SP1);
		U1_XLVAL_W(P2);
		DISPATCH_W(2);

	case U2_VOID_YFVAL:
		U1_VOID_W(SP1);
		U1_YFVAL_W(P2);
		DISPATCH_W(2);

	case U2_VOID_YVAL:
		U1_VOID_W(SP1);
		U1_YVAL_W(P2);
		DISPATCH_W(2);

	case U2_VOID_YLVAL:
		U1_VOID_W(SP1);
		U1_YLVAL_W(P2);
		DISPATCH_W(2);

