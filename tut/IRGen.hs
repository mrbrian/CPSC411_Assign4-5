--IRGen.hs

import IRDataType
import SymbolTable as S
		
transProg :: M_prog -> I_prog
transProg (M_prog (decls, stmts)) = I_PROG(fbodies, length localvars, tsmts)
where
	tstmts = transStmtS stmts (n,st)
	fbodies = transDecl FUNS decls (n,st)
	(n,st) = genSymTabBlock 0 L_PROG decls []
	localvars = filter (\x -> isM_var x) decls
	funs = filter (\x -> (not.isM_var x) decls
	
transDecl_FUNS :: [M_decl] -> (Int, ST) -> [I_fbody]
transDecl_FUNS [] (n,st) = []
transDecl_FUNS (d:ds) st = f:(transDecl_FUNS ds (n,st))
	where f = transDecl_FUN d (n,st)
	
transDecl_FUN :: M_decl -> (Int, ST) -> I_fbody
transDecl_FUN decl (n,st) = 
	case decl of
		M_fun(fname, args_triple, otype, decls, stmts) ->
				I_FUN (fname, fbodies, length localvars, length args, ...)
			where
				tstmts = transStmts stmts (n,st_fun)
				I_FUNCTION(level, label, arg_Type, typef) = lookup fname st
				fbodies = transDecl_FUNS decls st_fun
				st_fun = genSymTabFun n decl st
				nargs = length args_triple
				localvars = filter (\x -> isM_var x) decls

transStmt stmt (n,st) = case stmt of
	M_ass (str,expr) -> I_ASS (level,offset,texpr)
		where
			texpr = transExpr (expr (n,st)
			I_VARIABLE(level,offset,typev,dim)= lookupstr st
	M_while (expr,stmt) -> I_WHILE (texpr,tstmt)
		where
			texpr = transExpr expr (n,st)
			tstmt = transStmt stmt (n,st)
	M_cond (expr, stmt1, stmt2) -> I_COND (transExpr expr (n,st),
											transStmt stmt1 (n,st),
											transStmt stmt2 (n,st))
	M_read str -> case typev of
		Int -> I_READ_I (level, offset)
		Bool -> I_READ_B (level, offset)
		Float -> I_READ_F (level, offset)
		where
			I_VARIABLE(level, offset, typev, dim) = lookup st str
			
			