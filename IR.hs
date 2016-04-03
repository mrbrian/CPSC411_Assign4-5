module IR where

import AST
import SymbolTable

data I_prog = I_PROG ([I_fbody],Int,[(Int,[I_expr])],[I_stmt])
           deriving (Eq,Show)
		-- functions, number of local variables, array descriptions, body.
data I_fbody = I_FUN (String,[I_fbody],Int,Int,[(Int,[I_expr])],[I_stmt])
           deriving (Eq,Show)
		-- functions, number of local variables, number of arguments
		-- array descriptions, body
data I_stmt = I_ASS (Int,Int,[I_expr],I_expr)
		-- level, offset, array indexes, expressions
		| I_WHILE (I_expr,I_stmt)
		| I_COND (I_expr,I_stmt,I_stmt)
		-- | I_CASE (I_expr,[(Int,Int,I_stmt)])
		-- each case branch has a constructor number, a number of arguments,
		-- and the code statements
		| I_READ_B (Int,Int,[I_expr])
		-- level, offset, array indexes
		| I_PRINT_B I_expr
		| I_READ_I (Int,Int,[I_expr])
		| I_PRINT_I I_expr
		| I_READ_F (Int,Int,[I_expr])
		| I_PRINT_F I_expr
{-  M++
		| I_READ_C (Int,Int,[I_expr])
		| I_PRINT_C I_expr   -} 
		| I_RETURN I_expr
		| I_BLOCK ([I_fbody],Int,[(Int,[I_expr])],[I_stmt])
           deriving (Eq,Show)
		-- functions, number of local variables, array descriptions, body.
data I_expr = I_IVAL Int
		| I_RVAL Float
		| I_BVAL Bool
		| I_CVAL Char
		| I_ID (Int,Int,[I_expr])
		-- level, offset, array indices
		| I_APP (I_opn,[I_expr])
		| I_REF (Int,Int)
		-- for passing an array reference as an argument
		-- of a function: level, offset
		| I_SIZE (Int,Int,Int)
           deriving (Eq,Show)
		-- for retrieving the dimension of an array: level,offset,dimension
data I_opn = I_CALL (String,Int)
		-- label and level
		| I_CONS (Int,Int)
		-- constructor number and number of arguments
		| I_ADD_I | I_MUL_I | I_SUB_I | I_DIV_I | I_NEG_I
		| I_ADD_F | I_MUL_F | I_SUB_F | I_DIV_F | I_NEG_F
		| I_LT_I  | I_LE_I  | I_GT_I  | I_GE_I  | I_EQ_I
		| I_LT_F  | I_LE_F  | I_GT_F  | I_GE_F  | I_EQ_F
		| I_LT_C  | I_LE_C  | I_GT_C  | I_GE_C  | I_EQ_C
		| I_NOT | I_AND | I_OR | I_FLOAT | I_FLOOR | I_CEIL
           deriving (Eq,Show)
		
--([I_fbody],Int,[(Int,[I_expr])],[I_stmt])

{-
		
isArg_arg :: (M_type, Int) -> Bool
isArg_arg (_, n) = n < 0

isVar_arg :: (M_type, Int) -> Bool
isVar_arg (_, n) = n > 0

isArray_sym :: (String, SYM_VALUE) -> Bool
isArray_sym (str, Var_attr (off, typ, dim)) = dim > 0

isFun_sym :: (String, SYM_VALUE) -> Bool
isFun_sym (str, Fun_attr _) = True
isFun_sym _ = False

transProg :: M_prog -> I_prog
transProg p = I_PROG (fs, nv, arrs, body)
	where
		M_prog (ds, stmts) = p
		((Symbol_table (sctyp, nv, na, syms)) : []) = gen_ST_prog p
		
		body = transStmts stmts
		arrs = transStmts stmts
		
		fs = filter isFun_sym syms          -- get SYM_VALUES
		
		(n', fs') = transFuns fs    -- get main level functions from the st.
		
		arrs = filter isArray_sym syms
		body = transStmts n stmts st

transFuns :: [SYM_DESC] -> [I_fbody]
transFuns [] st = []
transFuns (f:fs) st = f':fs'
	where
		f' = transFun f st
		fs' = transFuns fs st
	
transFun :: SYM_DESC -> ST -> I_fbody
transFun (FUNCTION (label, args, rt)) st = I_FUN (label, locfuns, nv, na, args, stmts)
	where
		-- Fun_attr (String,[(M_type,Int)],M_type)
		
		-- I_FUN (String,[I_fbody],Int,Int,[(Int,[I_expr])],[I_stmt])
		nv = length (filter isVar_arg args)
		na = length (filter isArg_arg args)
		--locfuns = length (filter isFun args)   -- how to find???
		
		(Symbol_table (sctyp, nv', na', syms):rest) = st
		locfuns = filter isFun_sym syms 
		stmts = transStmts st  -- .. stmts of the function.  ARE NOT IN SYMBOL TABLE.
		
transStmts :: Int -> [M_stmt] -> ST -> (Int, [I_stmt], ST)
transStmts n [] st = (n, [], st)
transStmts n (stmt:stmts) st = v
	where  
		(n', stmt', st') = transStmt n stmt st
		(n'', stmts', st'') = transStmts n' stmts st'
		v = (n'', stmt':stmts', st'')

transStmt :: Int -> M_stmt -> ST -> (Int, I_stmt, ST)
transStmt n stmt st = case stmt of
	M_ass (name, arrs, exp) -> (n, I_ASS (lvl, off, arrs', exp'), st)
		where 
			(I_VARIABLE (lvl, off, _, _)) = look_up st name 
			arrs' = transExprs arrs st
			exp' = transExpr exp st	
	M_while (exp, stmt) -> (n', I_WHILE (exp', stmt'), st')
		where
			exp' = transExpr exp st
			(n', stmt', st') = transStmt n stmt st	
	M_cond (e, s1, s2) -> (n'', I_COND (e', s1', s2'), st'')
		where
			e' = transExpr e st
			(n', s1', st') = transStmt n s1 st
			(n'', s2', st'') = transStmt n' s2 st'
	M_read (name, arrs) -> (case typ of
			M_int  -> (n, I_READ_I loc, st)
			M_bool -> (n, I_READ_B loc, st)
			M_real -> (n, I_READ_F loc, st))
		where
			(I_VARIABLE (lvl, off, typ, _)) = look_up st name
			arrs' = transExprs arrs st
			loc = (lvl, off, arrs')
	M_print (e) -> (case e of 
		M_ival v -> (n, I_PRINT_I (I_IVAL (fromIntegral v)), st)
		M_rval v -> (n, I_PRINT_F (I_RVAL v), st)
		M_bval v -> (n, I_PRINT_B (I_BVAL v), st))	 -- ... expression???? 
	M_return (e) -> (n, I_RETURN e', st)
		where
			e' = transExpr e st
			{-
	M_block (decls, stmts) -> (n''', I_BLOCK (fs', nv, vars', stmts'))
		where  
			vs = filter isVar decls
			--nv = length vs
			(n', st') = transDecls n vs st
			(st1':strest') = st'
			Symbol_table (sc, nv, na, syms) = st1'
			vars' = map (\(M_var (name, es, typ)) -> (, transExprs es st')) vs
			fs = filter isFun decls
			(n'', fs') = transDecls n' fs st
			(n''', stmts') = transStmts n'' stmts st
			-}
transDecls :: Int -> [M_decl] -> ST -> (Int, ST)
transDecls n [] st = (n, st)
transDecls n (d:ds) st = (n'', st'')
	where
		(n', st')   = transDecl n d st
		(n'', st'') = transDecls n' ds st'

transDecl :: Int -> M_decl -> ST -> (Int, ST)
transDecl n d st = (n', st')
	where
		(n', st') = case d of 
			M_var (vn, vd, vt) -> insert n st (VARIABLE (vn, vt, vd'))
				where 
					vd' = length vd
			M_fun (fn, fps, frt, fds, fstmts) -> insert (n+1) st (FUNCTION (fn, fps', frt))
				where 
					fps' = map (\(aN, aD, aT) -> (aT, aD)) fps

transExprs :: [M_expr] -> ST -> [I_expr]
transExprs (e:es) st = ies
	where		
		ies = (transExpr e st):(transExprs es st)

transExpr :: M_expr -> ST -> I_expr
transExpr e st = case e of
	M_ival v -> I_IVAL (fromIntegral v) 
	M_rval v -> I_RVAL v 
	M_bval v -> I_BVAL v 
	M_size (str, dim) -> I_SIZE (lvl, off, dim)
		where 
			(I_VARIABLE (lvl, off, _, dim)) = look_up st str
	M_id (str, es) -> I_ID (lvl, off, es')
		where
			(I_VARIABLE (lvl, off, _, dim)) = look_up st str
			es' = transExprs es st
	--M_app (op, es)  -> I_REF (op', es')   what about this one
	M_app (op, ess) -> I_APP (op', ess')
		where
			(e:es) = ess
			op' = transOper op e st
			ess' = transExprs (ess) st

transOper :: M_operation -> M_expr -> ST -> I_opn
transOper op e st = case op of
	M_fn str ->  I_CALL	(label, lvl)
		where (I_FUNCTION (lvl, label, _, _)) = look_up st str
		--  | I_CONS (Int,Int)  m++
	M_add    -> (case e of 
		M_ival v -> I_ADD_I
		M_rval v -> I_ADD_F)
	M_mul    -> (case e of 
		M_ival v -> I_MUL_I
		M_rval v -> I_MUL_F)
	M_sub    -> (case e of
		M_ival v -> I_SUB_I
		M_rval v -> I_SUB_F)
	M_div    -> (case e of
		M_ival v -> I_DIV_I
		M_rval v -> I_DIV_F)
	M_neg    -> (case e of
		M_ival v -> I_DIV_I
		M_rval v -> I_DIV_F)
	M_lt     -> (case e of
		M_ival v -> I_LT_I
		M_rval v -> I_LT_F)
	M_le     -> (case e of
		M_ival v -> I_LE_I
		M_rval v -> I_LE_F)
	M_gt     -> (case e of
		M_ival v -> I_GT_I
		M_rval v -> I_GT_F)
	M_ge     -> (case e of
		M_ival v -> I_GE_I
		M_rval v -> I_GE_F)
	M_eq     -> (case e of
		M_ival v -> I_EQ_I
		M_rval v -> I_EQ_F)
	M_not    -> I_NOT
	M_and    -> I_AND
	M_or     -> I_OR
	M_float  -> I_FLOAT
	M_floor  -> I_FLOOR
	M_ceil   -> I_CEIL
				 
		 -}