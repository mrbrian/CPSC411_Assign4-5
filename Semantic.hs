module Semantic where

import AST
import SymbolTable
import IR

valid_input_type :: M_operation -> M_expr -> ST -> Bool
valid_input_type op e st = (case op of
	M_add -> elem e_type [M_int, M_real]
	M_mul -> elem e_type [M_int, M_real]
	M_sub -> elem e_type [M_int, M_real]
	M_div -> elem e_type [M_int, M_real]
	M_neg -> elem e_type [M_int, M_real]
	M_lt -> elem e_type [M_int, M_real]
	M_le -> elem e_type [M_int, M_real]
	M_gt -> elem e_type [M_int, M_real]
	M_ge -> elem e_type [M_int, M_real]
	M_eq -> elem e_type [M_int, M_real]
	M_not -> e_type == M_bool
	M_and -> e_type == M_bool
	M_or -> e_type == M_bool
	M_float -> e_type == M_int
	M_floor -> e_type == M_real 
	M_ceil -> e_type == M_real)
		where
			e_type = get_type e st

same_type :: ST -> String -> M_expr -> Bool
same_type st name expr = v
	where
		sym_i_desc1 = look_up st name
		type1 = get_type_sid sym_i_desc1		
		type2 = get_type_expr st expr
		
		v1 = checkExpr expr st
		v2 = type1 == type2
		v = v1 && v2

get_type :: M_expr -> ST -> M_type
get_type e st = case e of
	M_ival _ -> M_int
	M_rval _ -> M_real
	M_bval _ -> M_bool
	M_size (str, x) -> M_int
	M_id (str,exs) -> t
		where
			I_VARIABLE (_,_,t,_) = look_up st str
	M_app (op, e:exs) -> case op of 
		M_fn str -> t
			where 
			I_FUNCTION (_,_,_,t) = look_up st str
		M_add -> get_type e st
		M_mul -> get_type e st
		M_sub -> get_type e st
		M_div -> get_type e st
		M_neg -> get_type e st
		M_lt -> M_bool
		M_le -> M_bool
		M_gt -> M_bool
		M_ge -> M_bool
		M_eq -> M_bool
		M_not -> M_bool
		M_and -> M_bool
		M_or -> M_bool
		M_float -> M_real
		M_floor -> M_int 
		M_ceil -> M_int

all_same_type :: ST -> [M_expr] -> Bool
all_same_type st [] = True
all_same_type st (e:exs) = (case not_same of
		[] -> True
		_ -> False)
	where
		t1 = get_type e st
		not_same = [x | x <- exs, not ((get_type x st) == t1)]		
		
are_ints :: ST -> [M_expr] -> Bool
are_ints st exs = (case not_ints of
	[] -> True
	_ -> False)
	where
		not_ints = [ x | x <- exs, not (is_int st x)]
		
is_int :: ST -> M_expr -> Bool
is_int st e = case e of
	M_ival _ -> True
	M_rval _ -> False
	M_bval _ -> False
	M_size (str, x) -> True
	M_id (str,exs) -> are_ints st exs 
	M_app (_, exs) -> are_ints st exs	

checkExpr :: M_expr -> ST -> Bool
checkExpr exp st = case exp of 
			M_ival _ -> True
			M_rval _ -> True
			M_bval _ -> True
			M_size (str, x) -> True
			M_id (str,exs) -> are_ints st exs					
			M_app (op, exs) -> (case op of
				M_fn str -> v
					where
					  --  I_FUNCTION (Int,String,[(M_type,Int)],M_type)
						I_FUNCTION (_,_,f_args,_) = look_up st str
						f_types = map (\(a_type, _) -> a_type) f_args
						in_args = exs
						in_types = map (\a -> get_type a st) in_args 
						v = in_types == f_types
						e:rest = exs
				_ -> v
					where
						e:rest = exs
						v1 = all_same_type st exs
						v2 = valid_input_type op e st
						v = v1 && v2)
					
checkProg :: M_prog -> Bool
checkProg (M_prog (decls, stmts)) = v
   where
	 st = new_scope L_PROG []
	 (n, st1, v1) = checkDecls decls (1, st)	
	 v2 = checkStmts stmts (n,st1)
	 v = v1 && v2

checkDecls :: [M_decl] -> (Int, ST) -> (Int, ST, Bool)
checkDecls [] (n,st) = (n, st, True)
checkDecls d_list@(decl:decls) (n,st) = (n2,st2,v)
     where 
		v_list = filter (\a -> is_var a) d_list
		f_list = filter (\a -> not (is_var a)) d_list 		
		(decl':decls') = v_list ++ f_list
		(n1,st1,v1) = checkDecl decl' (n,st)
		(n2,st2,v2) = checkDecls decls' (n1,st1)
		v = v1 && v2
		
checkDecl :: M_decl -> (Int, ST) -> (Int, ST, Bool)
checkDecl decl (n,st) = case decl of 
	M_var _ -> checkVar decl (n,st)
	M_fun _ -> checkFun decl (n,st)
	
checkVar :: M_decl -> (Int, ST) -> (Int, ST, Bool)
checkVar (M_var (name, arr_exprs, typ)) (n, st) = (n', st', v)
	where		
		v = are_ints st arr_exprs
		dim = length arr_exprs
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
checkFun (M_fun (name, args, ret_type, decls, stmts)) (n, st) = (n2, st1, v)
	where		
		sym_args = map (\(nam, dim, typ) -> (typ, dim)) args
		(n1, st1) = insert n st (FUNCTION (name, sym_args, ret_type))
		
		st2 = new_scope (L_FUN ret_type) st1
		
		(st3,v1) = checkArgs n1 st2 args
		(n2, st4, v2) = checkDecls decls (n1,st3) 
		v3 = checkStmts stmts (n2,st4) 
		v = v1 && v2 && v3 
		
	
checkArgs :: Int -> ST -> [(String,Int,M_type)] -> (ST, Bool)
checkArgs n st [] = (st, True)
checkArgs n st (arg:rest) = (st'',v)
	where
		(st',v1) = checkArg n st arg
		(st'',v2) = checkArgs n st' rest
		v = v1 && v2
		
checkArg :: Int -> ST -> (String,Int,M_type) -> (ST, Bool)
checkArg n st (name, dim, typ) = (st', True)
	where
		(n, st') = insert n st (ARGUMENT (name, typ, dim))
		
checkStmts :: [M_stmt] -> (Int,ST) -> Bool
checkStmts [] (n,st) = True
checkStmts (stmt:rest) (n,st) = v
	where
		(n1, st1, v1) = checkStmt stmt (n,st)
		v2 = checkStmts rest (n1,st1)
		v = v1 && v2
			
checkStmt :: M_stmt -> (Int,ST) -> (Int, ST, Bool)
checkStmt stmt (n,st) = case stmt of
	M_ass (name, arrs, exp) -> (case (look_up st name) of
		I_VARIABLE (_,_,v_type,_) -> (n,st,v)
		I_FUNCTION _ -> (n,st,False))
		where 	
			I_VARIABLE (_,_,v_type,_) = look_up st name 
			v1 = checkExpr exp st
			e_type = get_type exp st
			v2 = v_type == e_type 
			v = v1 && v2
	M_while (exp, stmt) -> (n',st', exp' && stmt')
		where
			exp' = checkExpr exp st
			(n',st',stmt') = checkStmt stmt (n,st)	
	M_cond (e, s1, s2) -> (n'', st'', (e_type == M_bool) && e' && s1' && s2')
		where
			e_type = get_type e st
			e' = checkExpr e st
			(n',st', s1')   = checkStmt s1 (n,st)
			(n'', st'', s2') = checkStmt s2 (n',st')
	M_read (name, arrs) -> (case typ of
			M_int  -> (n,st, True)
			M_bool -> (n,st, True)
			M_real -> (n,st, True))
		where
			(I_VARIABLE (lvl, off, typ, _)) = look_up st name
			arrs' = transExprs arrs st
			loc = (lvl, off, arrs')
	M_print (e) -> (case e of 
		M_ival v -> (n,st, True)
		M_rval v -> (n,st, True)
		M_bval v -> (n,st, True)	 
		M_size v -> (n,st, True)	 
		M_app v  -> (n,st, (checkExpr e st))
		M_id (v, exs)  -> (n,st, (are_ints st exs)))
	M_block (decls, stmts) -> (n', st, v)
		where  
			st' = new_scope L_BLK st
			(n', st'', v1) = checkDecls decls (n,st')
			v2 = checkStmts stmts (n',st'')
			v = v1 && v2
	M_return e -> (n,st,v)
		where
			r_type = return_type st --get of return type the symbol table on stack
			e_type = get_type e st
			e' = checkExpr e st
			v = e' && (e_type == r_type)
			
				
				