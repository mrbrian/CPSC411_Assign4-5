module Semantic where

import AST
import SymbolTable
import IR

exist :: Int -> ST -> String -> Bool
exist n st name = v
	where
		sym = look_up st name		
		v = case sym of
			I_VARIABLE (0,_,_,_) -> True
			I_FUNCTION (0,_,_,_) -> True
			_ -> False
			
checkProg :: M_prog -> Bool
checkProg (M_prog (decls, stmts)) = v
   where
	 st = new_scope L_PROG []
	 (n, st1, v1) = checkDecls decls (1, st)	
	 v2 = checkStmts stmts st1
	 v = v1 && v2

checkDecls :: [M_decl] -> (Int, ST) -> (Int, ST, Bool)
checkDecls [] (n,st) = (n, st, True)
checkDecls (decl:decls) (n,st) = (n2,st2,v)
     where 
		(n1,st1,v1) = checkDecl decl (n,st)
		(n2,st2,v2) = checkDecls decls (n1,st1)
		v = v1 && v2
		
checkDecl :: M_decl -> (Int, ST) -> (Int, ST, Bool)
checkDecl decl (n,st) = case decl of 
	M_var _ -> checkVar decl (n,st)
	M_fun _ -> checkFun decl (n,st)
	
checkVar :: M_decl -> (Int, ST) -> (Int, ST, Bool)
checkVar (M_var (name, arr_exprs, typ)) (n, st) = v
	where
		dim = length arr_exprs
		v = not (exist n st name)
		(n', st') = insert n st (VARIABLE (name, typ, dim))		
					 
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

checkFun :: M_decl -> (Int, ST) -> (Int, ST, Bool)
checkFun (M_fun (name, args, ret_type, decls, stmts)) (n, st) = v
	where
		v1 = not (exist n st name)
		
		sym_args = map (\(nam, dim, typ) -> (typ, dim)) args
		(n1, st1) = insert n st (FUNCTION (name, sym_args, ret_type))
		
		st2 = new_scope (L_FUN ret_type) st1
		
		(st3,v2) = checkArgs n1 st2 args
		(n2, st4, v3) = checkDecls n1 st3 decls
		(n3, st5, v4) = checkStmts n2 st4 stmts
		v = v1 && v2 && v3 && v4
		
	
checkArgs :: Int -> ST -> [(String,Int,M_type)] -> (ST, Bool)
checkArgs n st [] = (st, True)
checkArgs n st (arg:rest) = (st'',v)
	where
		(st',v1) = checkArg n st arg
		(st'',v2) = checkArgs n st' rest
		v = v1 && v2
		
checkArg :: Int -> ST -> (String,Int,M_type) -> (ST, Bool)
checkArg n st (name, dim, typ) = (st', v)
	where
		v = not (exist n st name)
		(n, st') = insert n st ARGUMENT (name, typ, dim)
		
checkStmts :: [M_stmt] -> (Int,ST) -> Bool
checkStmts [] (n,st) = []
checkStmts (stmt:rest) (n,st) = v
	where
		(n1, st1, v1) = checkStmt stmt (n,st)
		v2 = checkStmts rest (n1,st1)
		v = v1 && v2
			
checkStmt :: M_stmt -> (Int,ST) -> (Int, ST, Bool)
checkStmt stmt (n,st) = case stmt of
	M_ass (name, arrs, exp) -> (n,st, IASS (lvl, off, arrs', exp'))
		where 
			(I_VARIABLE (lvl, off, _, _)) = look_up st name 
			arrs' = transExprs arrs st
			exp' = transExpr exp st	
	M_while (exp, stmt) -> (n',st', IWHILE (exp', stmt'))
		where
			exp' = transExpr exp st
			((n',st'),stmt') = checkStmt stmt (n,st)	
	M_cond (e, s1, s2) -> (n'', st'', ICOND (e', s1', s2'))
		where
			e' = transExpr e st
			((n',st'), s1')   = checkStmt s1 (n,st)
			((n'', st''), s2') = checkStmt s2 (n',st')
	M_read (name, arrs) -> (case typ of
			M_int  -> (n,st, True)
			M_bool -> (n,st, True)
			M_real -> (n,st, True))
		where
			(I_VARIABLE (lvl, off, typ, _)) = look_up st name
			arrs' = transExprs arrs st
			loc = (lvl, off, arrs')
	M_print (e) -> (case e of 
		M_ival v -> (n,st, IPRINT_I (IINT (fromIntegral v)))
		M_rval v -> (n,st, IPRINT_F (IREAL v))
		M_bval v -> (n,st, IPRINT_B (IBOOL v))	 -- ... expression????
		M_app v  -> (n,st, IPRINT_I (transExpr e st)))
	M_block (decls, stmts) -> (n', st', v)
		where  
			(n', st', v1) = checkDecls decls (n,st)
			v2 = checkStmts stmts (n',st')
			v = v1 && v2
	M_return e -> (n,st, IRETURN e')
		where
			e' = transExpr e st
	s -> error (show s)
			
		
				
				