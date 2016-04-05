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
		M_rval v -> IADD_F
		x -> error (show x))
	M_mul    -> (case e of
		M_ival v -> IMUL_I
		M_rval v -> IMUL_F
		M_id v -> IMUL_F		
		x -> error (show x))
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
	x -> error (show x)
	