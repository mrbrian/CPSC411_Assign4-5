module AST_to_IR where

import SymbolTable
import IR
import AST 

processProg :: M_prog -> I_prog
processProg (M_prog (decls, stmts)) = IPROG (funcs, num_vars, arrays, stmts')
   where
	 st = new_scope L_PROG []
	 (funcs, num_vars, arrays, st') = processDecls decls (0, st)	 
	 stmts' = [] --processStmts stmts st' 

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
		
		func = IFUN (st_label, dec_funcs, dec_num_vars, 0, dec_arrays, stmts')

processStmts :: [M_stmt] -> (Int,ST) -> [I_stmt]
processStmts [] (n,st) = []
processStmts (stmt:rest) (n,st) = st3
	where
		((n', st'), st1) = processStmt_Block stmt (n,st)
		st2 = processStmts rest (n',st')
		st3 = st1:st2
			
processStmt_Block :: M_stmt -> (Int,ST) -> ((Int, ST), I_stmt)
processStmt_Block stmt (n,st) = case stmt of
	M_block (decls, stmts) -> ((n', st'), IBLOCK (dec_funcs, dec_num_vars, dec_arrays, stmts'))
		where  
			(dec_funcs, dec_num_vars, dec_arrays, (n', st')) = processDecls decls (n,st)
			stmts' = processStmts stmts (n',st')
	M_return e -> ((n,st), IRETURN e')
		where
			e' = transExpr e st
		
			
		
				
				