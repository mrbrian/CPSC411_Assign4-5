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

transId :: M_expr -> ST -> M_type
transId (M_id (name, arr_exps)) st = typ
	where
		I_VARIABLE (lvl, off, typ, dim) = look_up st name

get_type_sid :: SYM_I_DESC -> M_type
get_type_sid sym = case sym of
	I_VARIABLE (_,_,t,_) -> t
	I_FUNCTION (_,_,_,t) -> t

get_type_expr :: ST -> M_expr -> M_type
get_type_expr st exp = case exp of
			M_ival _ -> M_int
			M_rval _ -> M_real
			M_bval _ -> M_bool
			M_size _ -> M_int
			M_id (str,exs) -> type'
				where 
					desc = look_up st str
					type' = get_type_sid desc
			M_app (_, e:exs) -> get_type_expr st e
			
transOper :: M_operation -> M_expr -> ST -> I_opn
transOper op e st = case op of
	M_fn str ->  ICALL	(label, lvl)
		where 
			(I_FUNCTION (lvl, label, _, _)) = look_up st str
	M_add    -> (case e of
		M_ival v -> IADD
		M_rval v -> IADD_F
		M_size v -> IADD
		M_id v -> (case (transId e st) of
			M_int -> IADD
			M_real -> IADD_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> IADD
			M_real -> IADD_F))
	M_mul    -> (case e of
		M_ival v -> IMUL
		M_rval v -> IMUL_F
		M_size v -> IMUL
		M_id v -> (case (transId e st) of
			M_int -> IMUL
			M_real -> IMUL_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> IMUL
			M_real -> IMUL_F))
	M_sub    -> (case e of 
		M_ival v -> ISUB
		M_rval v -> ISUB_F
		M_size v -> ISUB
		M_id v -> (case (transId e st) of
			M_int -> ISUB
			M_real -> ISUB_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> ISUB
			M_real -> ISUB_F))	
	M_div    -> (case e of 
		M_ival v -> IDIV
		M_rval v -> IDIV_F
		M_size v -> IDIV
		M_id v -> (case (transId e st) of
			M_int -> IDIV
			M_real -> IDIV_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> IDIV
			M_real -> IDIV_F))
	M_neg    -> (case e of 
		M_ival v -> INEG
		M_rval v -> INEG_F
		M_size v -> INEG
		M_id v -> (case (transId e st) of
			M_int -> INEG
			M_real -> INEG_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> INEG
			M_real -> INEG_F))
	M_lt     -> (case e of 
		M_ival v -> ILT
		M_rval v -> ILT_F
		M_size v -> ILT
		M_id v -> (case (transId e st) of
			M_int -> ILT
			M_real -> ILT_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> ILT
			M_real -> ILT_F))
	M_le     -> (case e of 
		M_ival v -> ILE
		M_rval v -> ILE_F
		M_size v -> ILE
		M_id v -> (case (transId e st) of
			M_int -> ILE
			M_real -> ILE_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> ILE
			M_real -> ILE_F))
	M_gt     -> (case e of 
		M_ival v -> IGT
		M_rval v -> IGT_F
		M_size v -> IGT
		M_id v -> (case (transId e st) of
			M_int -> IGT
			M_real -> IGT_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> IGT
			M_real -> IGT_F))
	M_ge     -> (case e of 
		M_ival v -> IGE
		M_rval v -> IGE_F
		M_size v -> IGE
		M_id v -> (case (transId e st) of
			M_int -> IGE
			M_real -> IGE_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> IGE
			M_real -> IGE_F))
	M_eq     -> (case e of 
		M_ival v -> IEQ
		M_rval v -> IEQ_F
		M_size v -> IEQ
		M_id v -> (case (transId e st) of
			M_int -> IEQ
			M_real -> IEQ_F)
		M_app (op, e:exs) -> (case (get_type_expr st e) of
			M_int -> IEQ
			M_real -> IEQ_F))
	M_not    -> INOT
	M_and    -> IAND
	M_or     -> IOR
	M_float  -> IFLOAT
	M_floor  -> IFLOOR
	M_ceil   -> ICEIL
	x -> error (show x)
	