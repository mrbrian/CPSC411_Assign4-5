
module CodeGen where
import IR
import Text.PrettyPrint
import Text.PrettyPrint.GenericPretty


{-
genProg_Code :: I_prog -> String
genProg_Code (IPROG(funs, nloc, stmts))=
	where 
	prog = init ++ body ++ exit ++ fbody
			
	init = [loadR "%sp", loadR "%sp", storeR "%fp"
			,alloc vars, loadI (vars + 2)]
	body = compileStmts stmts
	exit = indent [loadR "%fp" , load0 (vars+1), app "NEG" , allocS
	
	
compileFunction (I_FUN (name, funs , lvar, args, body)) = concat {
lbl
, indent init
, functionBody,
end,
function]
where
lbl = [label name
init =[comment (loadR sp) indent ++ "\tFunc initiation",
storeR "%fp",
]

loop
break
indent
stmt
-}

indent = "\t\t"
neg 	= "NEG"
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
jumpC = indent ++ "JUMP_C"

label s = "label" ++ (show s) ++ ":"
alloc n = indent ++ "ALLOC "  ++ (show n)
allocS = indent ++ "ALLOC_S"

app s = indent ++ "APP " ++ s
halt = indent ++ "HALT"

comment :: String -> String
comment s = "%" ++ s

{-
codegen_function :: I_fbody -> String
IFUN (String,[I_fbody],vars,Int,[(Int,[I_expr])],[I_stmt]) = 
	where
		init = [loadR "%sp", storeR "%fp", alloc vars]
		
		exit = indent [loadI "vars"]
		
	
codegen_Array :: (Int, [I_expr]) -> [String]
codegen_Array (n, s:rest) = 
	[loadI s, loadR "%sp", loadR "%fp", storeO]
	loadI 20
-}
codegen_Fun :: Int -> I_fbody -> (Int, [String])
codegen_Fun x (IFUN (label, fb, vars, args, arrays, stmts)) = 
		(x1, com ++ lbl ++ (init ++ array ++ stmts' ++ret_val ++ ret_ptr ++ exit ++ restore))
		
--(String,[I_fbody],Int,Int,[(Int,[I_expr])],[I_stmt])
	where
		(x1, stmts') = codegen_Stmts x stmts
		n = args
		m = vars
		com 	= [comment "func start"]
		lbl 	= [label++":"]
		init 	= [loadR "%sp", storeR "%fp", alloc n, loadI (n+2)]
		array 	= []
		ret_val = [loadR "%fp", storeO (-(n+3))]
		ret_ptr = [loadR "%fp", loadO 0, loadR "%fp", storeO (-(n+2))]
		exit 	= [loadR "%fp", loadO (m+1), app neg, allocS]
		restore = [storeR "%fp", alloc (-n), jumpS]

codegen_Funs :: Int -> [I_fbody] -> (Int, [String])
codegen_Funs n [] = (n, [])
codegen_Funs n (f:fs) = (n2, s1 ++ s2)
	where 
		(n1, s1) = codegen_Fun n f
		(n2, s2) = codegen_Funs n1 fs
			
			
codegen_LoadExpr :: I_expr -> [String]
codegen_LoadExpr e = case e of
	IINT x -> [loadI x]
        IREAL x -> [loadF x]
        IBOOL x -> [loadB x]
        IID (lvls,offs,es) -> get_static_link lvls ++ [loadO offs] 
        IAPP (op,es) -> codegen_LoadExprs es

  --      ISIZE (lvl,offs,dim) -> 
        	

codegen_LoadExprs :: [I_expr] -> [String]
codegen_LoadExprs [] = []
codegen_LoadExprs (e:rest) = (codegen_LoadExpr e)++(codegen_LoadExprs rest)

get_static_link :: Int -> [String] 
get_static_link 0 = [loadR "%fp"]
get_static_link n = (get_static_link (n-1))++[loadO (-2)]
		

codegen_Expr :: I_expr -> [String]
codegen_Expr e = case e of
	IINT x 	-> [show x]
	IREAL x -> [show x]
	IBOOL x -> [show x]
	{-IID       (Int,Int,[I_expr])   
	--  identifier (<level>,<offset>,<array indices>)-}
	IAPP (op, es) -> (case op of
		ICALL (label,lvls) -> [cmt] ++ init ++ before ++ static ++ call
			where
				cmt = comment "call"
				m = length es
				init 	= codegen_LoadExprs es
				before 	= [alloc 1, loadR "%fp"] 
				static 	= get_static_link lvls
				call 	= [loadR "%cp", jump label]

					--loadR "%sp", storeR "%fp", alloc m, loadI (m+1)]
					-- how to get the number of variables from here?
		IADD_F -> load ++ ["APP ADD_F"]
		IMUL_F -> load ++ ["APP MUL_F"]
		ISUB_F -> load ++ ["APP SUB_F"]
		IDIV_F -> load ++ ["APP DIV_F"]
		INEG_F -> load ++ ["APP NEG_F"]
		ILT_F  -> load ++ ["APP LT_F" ]
		ILE_F  -> load ++ ["APP LE_F" ]
		IGT_F  -> load ++ ["APP GT_F" ]
		IGE_F  -> load ++ ["APP GE_F" ]
		IEQ_F  -> load ++ ["APP EQ_F" ]
		IADD   -> load ++ ["APP ADD" ]
		IMUL   -> load ++ ["APP MUL"]
		ISUB   -> load ++ ["APP SUB"]
		IDIV   -> load ++ ["APP DIV"]
		INEG   -> load ++ ["APP NEG"]
		ILT    -> load ++ ["APP LT"]
		ILE    -> load ++ ["APP LE"]
		IGT    -> load ++ ["APP GT"]
		IGE    -> load ++ ["APP GE"]
		IEQ    -> load ++ ["APP EQ"]
		INOT   -> load ++ ["APP NOT"]
		IOR    -> load ++ ["APP OR"]
		IAND   -> load ++ ["APP AND"]
		IFLOAT -> load ++ ["APP FLOAT"]
		ICEIL  -> load ++ ["APP CEIL"]
		IFLOOR -> load ++ ["APP FLOOR"]
		)
			where
				load = codegen_LoadExprs es
		
--	ISIZE     (Int,Int,Int)
				
get_level_offset :: Int -> Int
get_level_offset 0 = 0
get_level_offset n = 0  --(get_level_offset n - 1) + (loadO nkd)
			
codegen_Stmt :: Int -> I_stmt -> (Int, [String])
codegen_Stmt n s = case s of
	IASS (lvl,off,es,e) -> (n, fp ++ a ++ b ++ c)
		where
			fp = []--[get_level_offset (loadR "%fp")] 
			a = codegen_LoadExprs es
			b = codegen_LoadExpr e 
			c = [storeO off]
	IWHILE (e,stmt) -> (n1, [label n] ++ (codegen_LoadExpr e) ++ [jumpC] ++
			exp ++ [jump (label n)])
		where
			(n1,exp) = codegen_Stmt (n+1) stmt
	ICOND (e,s1,s2) 	-> (n2, (codegen_LoadExpr e) ++ [jumpC] ++ exp1 ++
			[label n] ++ exp2)	
		where
			(n1,exp1) 	= codegen_Stmt (n+1) s1
			(n2,exp2) 	= codegen_Stmt n1 s2
	IREAD_F (lvl,off,es) -> (n, [readF, loadR "%fp", storeO off])
	IREAD_I (lvl,off,es) -> (n, [readI, loadR "%fp", storeO off])
	IREAD_B (lvl,off,es) -> (n, [readB, loadR "%fp", storeO off])
	IPRINT_F x -> (n, (codegen_Expr x) ++ [printF])
	IPRINT_I x -> (n, (codegen_Expr x) ++ [printI])
	IPRINT_B x -> (n, (codegen_Expr x) ++ [printB])

	IRETURN e -> (n, [loadR "%fp", loadO (-1), app "NEG", allocS, jumpS])
	
	IBLOCK (fbodies,vars,arrs,stmts) -> (n1,[pre] ++ enter ++ body ++ exit)
		where
			m = vars
			pre = comment "Block begin"
			--arr_exps = map (\(n, es) -> es) arrs
			enter = [loadR "%fp", alloc 1, loadR "%sp", storeR "%fp", 
				alloc m, loadI (m+2), --codegen_LoadExprs arr_exps, 
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
codegen_Prog (IPROG (fbs,vars,c,stmts)) = printlist prog
	where
		prog = init ++ body ++ exit ++ funs
				
		init = [loadR "%sp", loadR "%sp", storeR "%fp", alloc vars]
		body = (comment "body begin"):sts
		(n1, sts) = codegen_Stmts 0 stmts
		(n2, funs) = codegen_Funs n1 fbs
		exit = [alloc (-(vars+1)), halt]
			
stmts = IASS(0,1, [ IAPP(IADD_F,[IINT 1, IINT 2]) ], IINT 0)	
fbody = [] --IFUN ("funky", [], 2, 0, [], [stmts])
prog = IPROG (fbody, 2, [], [stmts])
test = codegen_Prog prog
test2 = codegen_Stmt 0 stmts








