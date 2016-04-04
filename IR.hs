module IR where

import AST
import SymbolTable


data I_prog  = IPROG    ([I_fbody],Int,[(Int,[I_expr])],[I_stmt])
           deriving (Eq,Show)
    -- a program node consists of 
    --   (a) the list of functions declared
    --   (b) the number of local variables
    --   (c) a list of array specifications (<offset>,<list of bounds>)
    --   (d) the body: a list of statements
data I_fbody = IFUN     (String,[I_fbody],Int,Int,[(Int,[I_expr])],[I_stmt])
           deriving (Eq,Show)
    -- a function node consists of 
    --   (a) the label given to the function
    --   (b) the list of local functions declared
    --   (c) the number of local variables
    --   (d) the number of arguments
    --   (c) a list of array specifications (<offset>,<list of bounds>)
    --   (d) the body: a list of statements
data I_stmt = IASS      (Int,Int,[I_expr],I_expr)
                 -- and assignment has argments (<level>,<offset>,<array indices>,expr)
            | IWHILE    (I_expr,I_stmt)
            | ICOND     (I_expr,I_stmt,I_stmt)
            | IREAD_F   (Int,Int,[I_expr])
            | IREAD_I   (Int,Int,[I_expr])
            | IREAD_B   (Int,Int,[I_expr])
            | IPRINT_F  I_expr
            | IPRINT_I  I_expr
            | IPRINT_B  I_expr
            | IRETURN   I_expr
            | IBLOCK    ([I_fbody],Int,[(Int,[I_expr])],[I_stmt])
           deriving (Eq,Show)
	         -- a block consists of 
		 -- (a) a list of local functions
		 -- (b) the number of local varibles declared
		 -- (c) a list of array declarations
		 -- (d) the body: a lst of statements
data I_expr = IINT      Int
            | IREAL     Float
            | IBOOL     Bool
            | IID       (Int,Int,[I_expr])   
	         --  identifier (<level>,<offset>,<array indices>)
            | IAPP      (I_opn,[I_expr])
            | ISIZE     (Int,Int,Int)
           deriving (Eq,Show)
	         --   isize(<level>,<offset>,<which dimension>)
		 --   level and offset identify which array the last integer 
		 --   tells you which dimension you want to look at!!
data I_opn = ICALL      (String,Int)
           | IADD_F | IMUL_F | ISUB_F | IDIV_F | INEG_F
           | ILT_F  | ILE_F  | IGT_F  | IGE_F  | IEQ_F   -- operations for floats
           | IADD_I | IMUL_I | ISUB_I | IDIV_I | INEG_I
           | ILT_I  | ILE_I  | IGT_I  | IGE_I  | IEQ_I   -- operations for floats
           | IADD | IMUL | ISUB | IDIV | INEG
           | ILT  | ILE  | IGT  | IGE  | IEQ 
           | INOT | IAND | IOR | IFLOAT | ICEIL |IFLOOR
           deriving (Eq,Show)		
		 
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

					
transStmts :: [M_stmt] -> ST -> [I_stmt]
transStmts [] st = []
transStmts (stmt:stmts) st = v
	where  
		stmt' = transStmt stmt st
		stmts' = transStmts stmts st
		v = stmt':stmts'
	 
		 
transStmt :: M_stmt -> ST -> I_stmt
transStmt stmt st = case stmt of
	M_ass (name, arrs, exp) -> IASS (lvl, off, arrs', exp')
		where 
			(I_VARIABLE (lvl, off, _, _)) = look_up st name 
			arrs' = transExprs arrs st
			exp' = transExpr exp st	
	M_while (exp, stmt) -> IWHILE (exp', stmt')
		where
			exp' = transExpr exp st
			stmt' = transStmt stmt st	
	M_cond (e, s1, s2) -> ICOND (e', s1', s2')
		where
			e' = transExpr e st
			s1' = transStmt s1 st
			s2' = transStmt s2 st
	M_read (name, arrs) -> (case typ of
			M_int  -> IREAD_I loc
			M_bool -> IREAD_B loc
			M_real -> IREAD_F loc)
		where
			(I_VARIABLE (lvl, off, typ, _)) = look_up st name
			arrs' = transExprs arrs st
			loc = (lvl, off, arrs')
	M_print (e) -> (case e of 
		M_ival v -> IPRINT_I (IINT (fromIntegral v))
		M_rval v -> IPRINT_F (IREAL v)
		M_bval v -> IPRINT_B (IBOOL v)	 -- ... expression????
		M_app v -> IPRINT_I (transExpr e st))
	M_return (e) -> IRETURN e'
		where
			e' = transExpr e st
	M_block (decls, stmts) -> IBLOCK (fs', nv, arrs', stmts')
		where  
			vs = filter isVar decls
			--nv = length vs
			(n, st') = transDecls 0 vs st
			(st1':strest') = st'
			Symbol_table (sc, nv, na, syms) = st1'
			arrs' = [] --map (transArray ) (\(M_var (name, es, typ)) -> (transExprs es st')) vs
			fs = filter isFun decls
			fs' = transFuns fs st
			stmts' = transStmts stmts st
			
		
transFuns :: [M_decl] -> ST -> [I_fbody]
transFuns [] st = []
transFuns (d:ds) st = (transFun d st):(transFuns ds st)

transFun :: M_decl -> ST -> I_fbody
transFun (M_fun (fn, fas, frt, fds, fsts)) st =  IFUN (fL, fbs', fnv, fna, farrs, fstmts)
	where
		I_FUNCTION (flvl, fL, fargs, frt) = look_up st fn
		fbs = filter isFun fds   				-- look for funs inside..
		fbs' = transFuns fbs st
		fvs = filter isVar fds
		fnv = length fvs
		fna = length fas
		fstmts = transStmts fsts st
		farrs = []
		
transArray :: M_decl -> ST -> (Int, [I_expr])
transArray (M_var (name, es, typ)) st = v
	where
		I_VARIABLE (lvl,off,typ,dim) = look_up st name   --I_VARIABLE (Int,Int,M_type,Int)
		es' = transExprs es st
		v = (off, es')
	 
	
transExprs :: [M_expr] -> ST -> [I_expr]
transExprs [] st = []
transExprs (e:es) st = ies
	where		
		ies = (transExpr e st):(transExprs es st)

transExpr :: M_expr -> ST -> I_expr
transExpr e st = case e of
	M_ival v -> IINT (fromIntegral v) 
	M_rval v -> IREAL v 
	M_bval v -> IBOOL v 
	M_size (str, dim) -> ISIZE (lvl, off, dim)
		where 
			(I_VARIABLE (lvl, off, _, dim)) = look_up st str
	M_id (str, es) -> IID (lvl, off, es')
		where
			(I_VARIABLE (lvl, off, _, dim)) = look_up st str
			es' = transExprs es st
	M_app (op, ess) -> IAPP (op', ess')
		where
			(e:es) = ess
			op' = transOper op e st
			ess' = transExprs (ess) st

			
transOper :: M_operation -> M_expr -> ST -> I_opn
transOper op e st = case op of
	M_fn str ->  ICALL	(label, lvl)
		where 
			(I_FUNCTION (lvl, label, _, _)) = look_up st str
	M_add    -> (case e of
		M_ival v -> IADD_I
		M_rval v -> IADD_F)
	M_mul    -> (case e of
		M_ival v -> IMUL_I
		M_rval v -> IMUL_F)
	M_sub    -> ISUB_F
	M_div    -> IDIV_F
	M_neg    -> INEG
	M_lt     -> ILT
	M_le     -> ILE
	M_gt     -> IGT
	M_ge     -> IGE
	M_eq     -> IEQ
	M_not    -> INOT
	M_and    -> IAND
	M_or     -> IOR
	M_float  -> IFLOAT
	M_floor  -> IFLOOR
	M_ceil   -> ICEIL
	 
	