/* Copyright (C) 1996,1997,1998, UPM-CLIP */

				/* XVAR + ... */

	case U2_XVAR_VOID:
		U1_XVAR_R(P1);
		U1_VOID_R(P2);
		DISPATCH_R(2);

	case U2_XVAR_XVAR:
		U1_XVAR_R(P1);
		U1_XVAR_R(P2);
		DISPATCH_R(2);

	case U2_XVAR_YFVAR:
		ComputeE;
	case U2_XVAR_YVAR:
		U1_XVAR_R(P1);
		U1_YVAR_R(P2);
		DISPATCH_R(2);

	case U2_XVAR_XVAL:
	case U2_XVAR_XLVAL:
		U1_XVAR_R(P1);
		U1_XVAL_R3(P2);

	case U2_XVAR_YFVAL:
		U1_XVAR_R(P1);
		U1_YFVAL_R(P2);
		DISPATCH_R(2);

	case U2_XVAR_YVAL:
	case U2_XVAR_YLVAL:
		U1_XVAR_R(P1);
		U1_YVAL_R3(P2);

