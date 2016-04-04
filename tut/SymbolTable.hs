		
typeProg :: M_prog -> Bool
typeProg (M_prog (decls, stmts)) = cstmts && cdecls
	where
		cstmts = checkStmtS stmts (n,st)
		cdecls = checkDecls decls (n,st)
		(n,st) = SymTabBlock 0 L_PROG decls[]
		
checkStmt :: M_stmt -> (Int, ST) -> Bool
checkStmt stmt sym@(n,st) = case stmt of 
	M_ass (s, inds, val) -> t1 && t1 == t2
		where
			t1 = getExprType (M_id (s, inds
	M_while (expr, dostmt) -> cond && loop
		where
			cond = isBool expr st
			loop = checkStmt stmt sym
	M_cond (expr, then', else') -> cond && gt && ge
		where cond isBool expr st
		gt = checkStmt then' sym
		ge = checkStmt then' sym
	M_print expr ->
	M_return expr -> 
		where
			isBool x st = M_bool == getExprType x st
			
generate_sym_decl n scope decl stabs = 
	case decl of 
		M_var (vname, exprs, vtype) -> (n', st')
			where
				sym_desc = VARIABLE (vname, vtype, length exprs)
				(n', st') = insert n scope stabs sym_desc
				
		M_fun (fname, args_triple,otype, decls,stmts) -> (n', new_st)
			where
				(n', new_st) = insert n scope stabs sym_desc
				sym_desc = FUNCTION (fname, args_pair, otype)
				args_pair = map (\(name,dim,typea) -> (typea,dim)) args_triple
					
genSymTabBlock :: Int -> ScopeType -> [M_decl] -> ST -> (Int, ST)
genSymTabBlock n scope decls st = case scope 'elem' [L_PROG, L_BLK] of 
	True -> generate_sym_decls n scope decls st'
		where
			st' = new_scope scope st
	False --> error "wrong func"
				
genSymTabFun :: Int -> M_decl -> ST -> (Int, ST)
genSymTabFun n (M_fun (str, args_triple, otype, decls, stmts)) st = generate_sym_decls n' scope decls st2 

getExprType :: M_expr -> ST -> M_type
getExprType x st = case x of 
	M_ival _ -> M_int
	M_rval _ -> M_real
	M_bval _ -> M_bool
	M_cval _ -> M_int
	M_size _ -> M_int
	M_id _ -> M_int
