
module CodeGen where
import IR
import Text.PrettyPrint
import Text.PrettyPrint.GenericPretty

indent = "\t\t"
neg 	= "NEG"
mul 	= "MUL"
add 	= "ADD"
loadI n = indent ++ "LOAD_I " ++ (show n)
loadR s = indent ++ "LOAD_R " ++ s
loadF s = indent ++ "LOAD_F " ++ (show s)
loadB n = indent ++ "LOAD_B " ++ (show n)
loadO n = indent ++ "LOAD_O " ++ (show n)
loadOS = indent ++ "LOAD_OS"

readI = indent ++ "READ_I"
readF = indent ++ "READ_F"
readB = indent ++ "READ_B"

printI = indent ++ "PRINT_I"
printF = indent ++ "PRINT_F"
printB = indent ++ "PRINT_B"

storeI s = indent ++ "STORE_I "  ++ s
storeR s = indent ++ "STORE_R "  ++ s
storeB s = indent ++ "STORE_B "  ++ s
storeO n = indent ++ "STORE_O " ++ (show n) 

jump s = indent ++ "JUMP " ++ s
jumpS = indent ++ "JUMP_S"
jumpC s = indent ++ "JUMP_C " ++ s

label s = "label" ++ (show s)
label_colon s = (label s) ++ ":"

alloc n = indent ++ "ALLOC "  ++ (show n)
allocS = indent ++ "ALLOC_S"

app s = indent ++ "APP " ++ s
halt = indent ++ "HALT"

comment :: String -> String
comment s = "%" ++ s
	
codegen_Array :: Int -> Int -> (Int,[I_expr]) -> [String]
codegen_Array _ 0 _ = error "codegen_Array: dont use zero here"
codegen_Array m dims (m_a,e:[]) = s1 ++ s2 ++ s3
	where
		s1 = codegen_Expr e		-- put on stack
		s2 = [loadR "%fp", loadO m_a, 
			loadO 1, loadR "%fp", 
			loadO m_a, loadO dims,
			app mul, loadR "%fp",
			loadO (m+1), loadI dims,
			loadR "%fp", --loadO wtf is a_I,
			loadO 3, app add, app add,
			loadR "%fp", storeO (m+1)]
		s3 = [allocS]
codegen_Array m dims (m_a,(e:es)) = s1 ++ s2 ++ (codegen_Array m (dims+1) (m_a,es))
	where
		s1 = codegen_Expr e 	-- first dimension on stack
		s2 = [loadR "%sp", loadR "%fp", storeO m_a]  -- make array pointer
		
		
codegen_Arrays :: Int -> [(Int,[I_expr])] -> [String]
codegen_Arrays m [] = []
codegen_Arrays m (a:rest) = (codegen_Array m 1 a)++(codegen_Arrays m rest)

codegen_Fun :: Int -> I_fbody -> (Int, [String])
codegen_Fun x (IFUN (label, fb, vars, args, arrays, stmts)) = 
		(x1, com ++ lbl ++ (init ++ array ++ stmts' ++ret_val ++ ret_ptr ++ exit ++ restore))		
	where
		(x1, stmts') = codegen_Stmts x stmts
		n = args
		m = vars
		com 	= [comment "func start"]
		lbl 	= [label++":"]
		init 	= [loadR "%sp", storeR "%fp", alloc n]
		array	= codegen_Arrays m arrays
		ret_val = [loadR "%fp", storeO (-(n+3))]
		ret_ptr = [loadR "%fp", loadO 0, loadR "%fp", storeO (-(n+2))]
		exit 	= [alloc (-(m+1))]
		restore = [storeR "%fp", alloc (-n), jumpS]

codegen_Funs :: Int -> [I_fbody] -> (Int, [String])
codegen_Funs n [] = (n, [])
codegen_Funs n (f:fs) = (n2, s1 ++ s2)
	where 
		(n1, s1) = codegen_Fun n f
		(n2, s2) = codegen_Funs n1 fs						

codegen_Exprs :: [I_expr] -> [String]
codegen_Exprs [] = []
codegen_Exprs (e:rest) = (codegen_Expr e)++(codegen_Exprs rest)

get_static_link :: Int -> [String] 
get_static_link 0 = [loadR "%fp"]
get_static_link n = (get_static_link (n-1))++[loadO (-2)]
		

codegen_Expr :: I_expr -> [String]
codegen_Expr e = case e of
	IINT x -> [loadI x]
	IREAL x -> [loadF x]
	IBOOL x -> [loadB x]
	IID (lvls,offs,es) -> get_static_link lvls ++ [loadO offs] 
	ISIZE (lvl,off,dim)	-> fp++ld
		where
			fp = get_static_link lvl
			ld = [loadO off]
			
	IAPP (op, es) -> (case op of
		ICALL (label,lvls) -> [cmt] ++ init ++ before ++ static ++ call
			where
				cmt = comment "call"
				m = length es
				init 	= codegen_Exprs es
				before 	= [alloc 1] 
				static 	= get_static_link lvls
				call 	= [loadR "%fp", loadR "%cp", jump label]
		IADD_F -> load ++ [app "ADD_F"]
		IMUL_F -> load ++ [app "MUL_F"]
		ISUB_F -> load ++ [app "SUB_F"]
		IDIV_F -> load ++ [app "DIV_F"]
		INEG_F -> load ++ [app "NEG_F"]
		ILT_F  -> load ++ [app "LT_F" ]
		ILE_F  -> load ++ [app "LE_F" ]
		IGT_F  -> load ++ [app "GT_F" ]
		IGE_F  -> load ++ [app "GE_F" ]
		IEQ_F  -> load ++ [app "EQ_F" ]
		IADD   -> load ++ [app "ADD" ]
		IMUL   -> load ++ [app "MUL"]
		ISUB   -> load ++ [app "SUB"]
		IDIV   -> load ++ [app "DIV"]
		INEG   -> load ++ [app "NEG"]
		ILT    -> load ++ [app "LT"]
		ILE    -> load ++ [app "LE"]
		IGT    -> load ++ [app "GT"]
		IGE    -> load ++ [app "GE"]
		IEQ    -> load ++ [app "EQ"]
		INOT   -> load ++ [app "NOT"]
		IOR    -> load ++ [app "OR"]
		IAND   -> load ++ [app "AND"]
		IFLOAT -> load ++ [app "FLOAT"]
		ICEIL  -> load ++ [app "CEIL"]
		IFLOOR -> load ++ [app "FLOOR"]
		)
			where
				load = codegen_Exprs es
		
			
codegen_Stmt :: Int -> I_stmt -> (Int, [String])
codegen_Stmt n s = case s of
	IASS (lvl,off,es,e) -> (n, a ++ fp ++ b ++ c)
		where
			fp = get_static_link lvl
			a = codegen_Expr e 
			b = codegen_Exprs es
			c = [storeO off]
	IWHILE (e,stmt) -> (n1, [label_colon n] ++ (codegen_Expr e) ++ [jumpC (label n)] ++
			exp ++ [jump (label n)])
		where
			(n1,exp) = codegen_Stmt (n+1) stmt
	ICOND (e,s1,s2) -> (n2, (codegen_Expr e) ++ [jumpC (label n)] ++ exp1 ++ 
			[jump (label (n+1))] ++
			[label_colon n] ++ exp2 ++ [label_colon (n+1)])	
		where
			(n1,exp1) 	= codegen_Stmt (n+1) s1
			(n2,exp2) 	= codegen_Stmt n1 s2
	IREAD_F (lvl,off,es) -> (n, [readF, loadR "%fp", storeO off])
	IREAD_I (lvl,off,es) -> (n, [readI, loadR "%fp", storeO off])
	IREAD_B (lvl,off,es) -> (n, [readB, loadR "%fp", storeO off])
	IPRINT_F x -> (n, (codegen_Expr x) ++ [printF])
	IPRINT_I x -> (n, (codegen_Expr x) ++ [printI])
	IPRINT_B x -> (n, (codegen_Expr x) ++ [printB])
	IRETURN e -> (n, codegen_Expr e)		-- just put return value on stack	
	IBLOCK (fbodies,vars,arrs,stmts) -> (n1,[pre] ++ enter ++ body ++ exit)
		where
			m = vars
			pre = comment "Block begin"
			--arr_exps = map (\(n, es) -> es) arrs
			enter = [loadR "%fp", alloc 1, loadR "%sp", storeR "%fp", 
				alloc m, loadI (m+2), --codegen_Exprs arr_exps, 
				allocS]
			(n1,body) = codegen_Stmts n stmts
			exit = [loadR "%fp", loadO (m+1), app neg, allocS]
	
codegen_Stmts :: Int -> [I_stmt] -> (Int,[String])
codegen_Stmts n [] = (n, [])
codegen_Stmts n (s:rest) = (n2, first++next)
	where
		(n1,first) = codegen_Stmt n s
		(n2, next) = codegen_Stmts n1 rest
				
		
printlist :: [String] -> String
printlist [] = ""
printlist (s:rest) = s ++ "\n" ++ (printlist rest)


codegen_Prog :: I_prog -> String
codegen_Prog (IPROG (fbs,vars,arrays,stmts)) = printlist prog
	where
		prog = init ++ array ++ body ++ exit ++ funs
				
		init = [loadR "%sp", loadR "%sp", storeR "%fp", alloc vars]
		array = codegen_Arrays vars arrays
		body = (comment "body begin"):sts
		(n1, sts) = codegen_Stmts 1 stmts
		(n2, funs) = codegen_Funs n1 fbs
		exit = [alloc (-(vars+1)), halt]
			
stmts = IASS(0,1, [ IAPP(IADD_F,[IINT 1, IINT 2]) ], IINT 0)	
fbody = [] --IFUN ("funky", [], 2, 0, [], [stmts])
prog = IPROG (fbody, 2, [], [stmts])
test = codegen_Prog prog
test2 = codegen_Stmt 0 stmts








