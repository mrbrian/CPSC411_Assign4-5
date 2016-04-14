
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
init =[comment (loadR sp) "\t\tFunc initiation",
storeR "%fp",
]

loop
break
indent
stmt
-}

loadI n = "LOAD_I " ++ (show n)
loadR s = "LOAD_R " ++ s
loadF s = "LOAD_F " ++ (show s)
loadB n = "LOAD_B " ++ (show n)
loadO n = "LOAD_O " ++ (show n)
loadOS = "LOAD_OS"

readI = "READ_I"
readF = "READ_F"
readB = "READ_B"

printI = "PRINT_I"
printF = "PRINT_F"
printB = "PRINT_B"

storeI s = "STORE_I "  ++ s
storeR s = "STORE_R "  ++ s
storeB s = "STORE_B "  ++ s
storeO n = "STORE_O " ++ (show n) 


jump s = "JUMP " ++ s
jumpS = "JUMP_S"

label s = s ++ ":"
alloc n = "ALLOC "  ++ (show n)
allocS = "ALLOC_S"

app s = "APP " ++ s
halt = "HALT"

comment :: String -> String
comment s = "%" ++ s ++ "\n"

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
codegen_Fun :: I_fbody -> [String]
codegen_Fun (IFUN (label, fb, vars, args, arrays, stmts)) = 
		(indent (com ++ caller ++ init ++ array ++ ret_val ++ ret_ptr ++ exit ++ restore))
--(String,[I_fbody],Int,Int,[(Int,[I_expr])],[I_stmt])
	where
		n = args
		m = vars
		com 	= [comment "func start"]
		caller 	= [loadR "%sp", storeR "%fp", alloc 1, loadR "%fp", loadO (-args), loadI 0, 
				storeR "%cp", jump label]
		init 	= (label++":"):[loadR "%sp", storeR "%fp", alloc n, loadI (n+2)]
		array 	= []
		ret_val = [loadR "%fp", storeO (-(n+3))]
		ret_ptr = [loadR "%fp", loadO 0, loadR "%fp", storeO (-(n+2))]
		exit 	= [loadR "%fp", loadO (m+1), app "NEG", allocS]
		restore = [storeR "%fp", alloc (-n), jumpS]

codegen_Funs :: [I_fbody] -> [String]
codegen_Funs [] = []
codegen_Funs (f:fs) = (codegen_Fun f)++(codegen_Funs fs)
			
			
codegen_LoadExpr :: I_expr -> [String]
codegen_LoadExpr e = case e of
	IINT x -> [loadI x]
        IREAL x -> [loadF x]
        IBOOL x -> [loadB x]
        IID (0,offs,es) -> [loadR "%fp", loadO offs] 
--        IID (lvl,offs,es) -> [loadO]
	         --  identifier (<level>,<offset>,<array indices>)
        IAPP (op,es) -> codegen_LoadExprs es

  --      ISIZE (lvl,offs,dim) -> 
        	

codegen_LoadExprs :: [I_expr] -> [String]
codegen_LoadExprs [] = []
codegen_LoadExprs (e:rest) = (codegen_LoadExpr e)++(codegen_LoadExprs rest)

get_static_link :: Int -> [String] 
get_static_link 0 = [loadR "%fp"]
get_static_link n = (loadO (-2)) : (get_static_link (n-1))
		

codegen_Expr :: I_expr -> [String]
codegen_Expr e = case e of
	IINT x 	-> [show x]
	IREAL x -> [show x]
	IBOOL x -> [show x]
	{-IID       (Int,Int,[I_expr])   
	--  identifier (<level>,<offset>,<array indices>)-}
	IAPP (op, es) -> (case op of
		ICALL (label,lvls) -> before ++ static ++ after
			where
				m = length es
				before = [alloc 1, loadR "%fp"] 
				static = get_static_link lvls
				after = [loadR "%fp", storeR "%cp", jump label,
					loadR "%sp", storeR "%fp", alloc m, loadI (m+1)]
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
			
codegen_Stmt :: I_stmt -> [String]
codegen_Stmt s = case s of
	IASS (lvl,off,es,e) -> fp ++ a ++ b ++ c
		where
			fp = []--[get_level_offset (loadR "%fp")] 
			a = codegen_LoadExprs es
			b = codegen_LoadExpr e 
			c = [storeO off]
	{-
	IWHILE (e,stmt) -> [label, codegen_LoadExpr e, jumpC, codeGen_Stmt stmt, jump]
	ICOND (e,s1,s2) = [codegen_LoadExpr e, jumpC, codeGen_Stmt s1, label, codeGen_Stmt s2]
	-}
	IREAD_F (lvl,off,es) -> [readF, loadR "%fp", storeO off]
	IREAD_I (lvl,off,es) -> [readI, loadR "%fp", storeO off]
	IREAD_B (lvl,off,es) -> [readB, loadR "%fp", storeO off]
	IPRINT_F x -> (codegen_LoadExpr x) ++ [printF]
	IPRINT_I x -> (codegen_LoadExpr x) ++ [printI]
	IPRINT_B x -> (codegen_LoadExpr x) ++ [printB] 

	--IRETURN e -> [alloc -vars, jump] 	-- .. where to get vars from??
	
	IBLOCK (fbodies,vars,arrs,stmts) -> [pre] ++ enter ++ exit
		where
			m = vars
			pre = comment "Block begin"
			--arr_exps = map (\(n, es) -> es) arrs
			enter = [loadR "%fp", alloc 1, loadR "%sp", storeR "%fp", 
				alloc m, loadI (m+2), --codegen_LoadExprs arr_exps, 
				allocS]
			body = ["body here"]
			exit = [loadR "%fp", loadO (m+1), app "NEG", allocS]
	
codegen_Stmts :: [I_stmt] -> [String]
codegen_Stmts [] = []
codegen_Stmts (s:rest) = first++next
	where
		first = codegen_Stmt s
		next = codegen_Stmts rest
		
indent :: [String] -> [String]
indent strs = map (\a -> "\t" ++ a) strs
		
		
printlist :: [String] -> String
printlist [] = ""
printlist (s:rest) = s ++ "\n" ++ (printlist rest)


codegen_Prog :: I_prog -> String
codegen_Prog (IPROG (fbs,vars,c,stmts)) = printlist prog
	where
		prog = init ++ body ++ exit ++ funs
				
		init = indent [loadR "%sp", loadR "%sp", storeR "%fp", alloc vars, loadI (vars + 2)]
		body = (comment "body begin"):(indent (codegen_Stmts stmts))
		funs = codegen_Funs fbs
		exit = indent [loadR "%fp" , loadO (vars+1), app "NEG", 
			allocS, alloc (-3), halt]
			
stmts = IASS(0,1, [ IAPP(IADD_F,[IINT 1, IINT 2]) ], IINT 0)	
fbody = [] --IFUN ("funky", [], 2, 0, [], [stmts])
prog = IPROG (fbody, 2, [], [stmts])
test = codegen_Prog prog
test2 = codegen_Stmt stmts








