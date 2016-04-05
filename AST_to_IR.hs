module AST_to_IR where

import SymbolTable
import IR
import AST 

processProg :: M_prog -> I_prog
processProg (M_prog (decls, stmts)) = IPROG (funcs, num_vars, arrays, stmts')
   where
	 st = new_scope L_PROG []
	 (funcs, num_vars, arrays, st') = processDecls decls (1, st)	 
	 stmts' = processStmts stmts st' 

processDecls :: [M_decl] -> (Int, ST) -> ([I_fbody], Int, [(Int, [I_expr])], (Int, ST))
processDecls [] (n,st) = ([], 0, [], (n, st))
processDecls (decl:decls) (n,st) = (funcs, num_vars, arrays, (n'', st''))
     where 
		(funcs1, num_vars1, arrays1, (n', st')) = processDecl decl (n,st)
		(funcs2, num_vars2, arrays2, (n'', st'')) = processDecls decls (n',st')
		funcs = funcs1 ++ funcs2
		num_vars = num_vars1 + num_vars2
		arrays = arrays1 ++ arrays2
		
processDecl :: M_decl -> (Int, ST) -> ([I_fbody], Int, [(Int, [I_expr])], (Int, ST))
processDecl decl (n,st) = case decl of 
	M_var _ -> processVar decl (n,st)
	M_fun _ -> processFun decl (n,st)
	
processVar :: M_decl -> (Int, ST) -> ([I_fbody], Int, [(Int, [I_expr])], (Int, ST))
processVar (M_var (name, arr_exprs, typ)) (n, st) = ([], 1, array, (n', st'))
	where
		dim = length arr_exprs
		(n', st') = insert n st (VARIABLE (name, typ, dim))
		array = case arr_exprs of
			[] -> []
			_ -> [ (offset, arr_exprs')] 
				where 
					(I_VARIABLE (level, offset, _type, dim)) = look_up st' name
					arr_exprs' = transExprs arr_exprs st'
					 
insert_args :: [(String, Int, M_type)] -> (Int, ST) -> (Int, ST)
insert_args [] (n,st) = (n, st)
insert_args (a:rest) (n,st) = (n'', st'')
	where
		(n', st') = insert_arg a (n,st)
		(n'', st'') = insert_args rest (n',st')

insert_arg :: (String, Int, M_type) -> (Int, ST) -> (Int, ST)
insert_arg (name, dim, typ) (n,st) = (n', st')
	where
		(n', st') = insert n st (ARGUMENT (name, typ, dim))

processFun :: M_decl -> (Int, ST) -> ([I_fbody], Int, [(Int, [I_expr])], (Int, ST))
processFun (M_fun (name, args, ret_type, decls, stmts)) (n, st) = ([func], 0, [], (n4, st2))
	where
		sym_args = map (\(nam, dim, typ) -> (typ, dim)) args
		(n2, st2) = insert n st (FUNCTION (name, sym_args, ret_type))
		st3 = new_scope (L_FUN ret_type) st2
		(n3, st4) = insert_args args (n2, st3)
		num_args = length args
		I_FUNCTION (st_level, st_label, st_args, st_type) = look_up st4 name
		(dec_funcs, dec_num_vars, dec_arrays, (n4, st5)) = processDecls decls (n3,st4)
		stmts' = processStmts stmts (n4, st5)
		
		func = IFUN (st_label, dec_funcs, dec_num_vars, length st_args, dec_arrays, stmts')

processStmts :: [M_stmt] -> (Int,ST) -> [I_stmt]
processStmts [] (n,st) = []
processStmts (stmt:rest) (n,st) = st3
	where
		((n', st'), st1) = processStmt stmt (n,st)
		st2 = processStmts rest (n',st')
		st3 = st1:st2
			
processStmt :: M_stmt -> (Int,ST) -> ((Int, ST), I_stmt)
processStmt stmt (n,st) = case stmt of
	M_ass (name, arrs, exp) -> ((n,st), IASS (lvl, off, arrs', exp'))
		where 
			(I_VARIABLE (lvl, off, _, _)) = look_up st name 
			arrs' = transExprs arrs st
			exp' = transExpr exp st	
	M_while (exp, stmt) -> ((n',st'), IWHILE (exp', stmt'))
		where
			exp' = transExpr exp st
			((n',st'),stmt') = processStmt stmt (n,st)	
	M_cond (e, s1, s2) -> ((n'', st''), ICOND (e', s1', s2'))
		where
			e' = transExpr e st
			((n',st'), s1')   = processStmt s1 (n,st)
			((n'', st''), s2') = processStmt s2 (n',st')
	M_read (name, arrs) -> (case typ of
			M_int  -> ((n,st), IREAD_I loc)
			M_bool -> ((n,st), IREAD_B loc)
			M_real -> ((n,st), IREAD_F loc))
		where
			(I_VARIABLE (lvl, off, typ, _)) = look_up st name
			arrs' = transExprs arrs st
			loc = (lvl, off, arrs')
	M_print (e) -> (case e of 
		M_ival v -> ((n,st), IPRINT_I (IINT (fromIntegral v)))
		M_rval v -> ((n,st), IPRINT_F (IREAL v))
		M_bval v -> ((n,st), IPRINT_B (IBOOL v))	 
		M_size v -> ((n,st), IPRINT_I (transExpr e st))
		M_app v  -> ((n,st), IPRINT_I (transExpr e st))
		M_id v -> (case (transId e st) of
			M_int -> ((n,st),IPRINT_I (transExpr e st))
			M_real -> ((n,st),IPRINT_F (transExpr e st)) 
			M_bool -> ((n,st),IPRINT_B (transExpr e st)))
		_ -> error ((show stmt)++(show st)))
	M_block (decls, stmts) -> ((n', st'), IBLOCK (dec_funcs, dec_num_vars, dec_arrays, stmts'))
		where  
			(dec_funcs, dec_num_vars, dec_arrays, (n', st')) = processDecls decls (n,st)
			stmts' = processStmts stmts (n',st')
	M_return e -> ((n,st), IRETURN e')
		where
			e' = transExpr e st
	s -> error (show s)
			
		
				
				