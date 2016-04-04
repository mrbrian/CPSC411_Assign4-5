--TypeCheck.hs

typeProg :: M_prog -> Bool
typeProg (M_prog (decls, stmts)) = cstmts && cdecls
	where cstmts = checkStmtS stmts (n,st)
		cdecls = checkDecls decls (n,st)
		(n,st) = genSymTabBlock 0 L_PROG decls []


checkDecls -> [M_decl] -> (Int, ST) -> Bool
checkDecls [] (n,st) = True
checkDecls (d:ds) st = bool && (transDecls ds (n,st))
	where bool checkDecl d (n,st)

check :: M_decl -> (Int, ST) -> Bool
checkDecl decl sym = case decl of 
	M_fun (name, ars, autT, decls, stmts) -> bool1 && bool2
		where (n, stm2) = genSymTabFun decl sym
			bool1 = checkDecls decls (n, sym2)
			bool2 = checkStmts stmts (n sym2)
	_ -> True
			
			
checkStmtS :: [M_stmt] -> (Int, ST) -> Bool
checkStmts [] (n,st)	= True
checkStmts () () = bool && (transSmts  ())
			
checkStmt :: M_stmt -> (Int, ST) -> Bool
checkStmt stmt sym@(n,st) = case stmt of
	M_ass (s, inds, val) -> t1 && t1 == t2
		where 
			t1 = 
			t2
			