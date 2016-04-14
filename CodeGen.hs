
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
storeO lvl offs = "STORE_O " ++ (show lvl) ++ (show offs)

addF = "ADD_F"

jump s = "JUMP " ++ s
jumpS = "JUMP_S"

label s = s ++ ":"
alloc n = "ALLOC "  ++ (show n)
allocS = "ALLOC_S"

app s = "APP " ++ s
halt = "HALT"

comment :: String -> String
comment s = "\t%" ++ s ++ "\n"

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
codegen_Fun (IFUN (label, fb, vars, args, arrays, stmts)) = caller ++ init ++ exit
--(String,[I_fbody],Int,Int,[(Int,[I_expr])],[I_stmt])
	where
		caller = [alloc 1, loadR "%fp", loadR "%fp", loadO (-1), loadO (-1), 
			storeR "%cp", jump label]
		init = []--[label, lordR "%sp", storeR "%fp", alloc m, loadI m+3]
		exit = [loadR "%fp", --store.., 
			loadR "%fp", --loadO 0, 
			loadR "%fp", jumpS]

			
codegen_LoadExpr :: I_expr -> [String]
codegen_LoadExpr e = case e of
	IINT x -> [loadI x]
        IREAL x -> [loadF x]
        IBOOL x -> [loadB x]
        IID (0,offs,es) -> [loadI offs, loadR "%sp", loadOS] 
--        IID (lvl,offs,es) -> [loadO]
	         --  identifier (<level>,<offset>,<array indices>)
        IAPP (op,es) -> codegen_LoadExprs es

  --      ISIZE (lvl,offs,dim) -> 
        	

codegen_LoadExprs :: [I_expr] -> [String]
codegen_LoadExprs [] = []
codegen_LoadExprs (e:rest) = (codegen_LoadExpr e)++(codegen_LoadExprs rest)


codegen_Expr :: I_expr -> [String]
codegen_Expr e = case e of
	IINT x -> [show x]
	IREAL x -> [show x]
	IBOOL x -> [show x]
	{-IID       (Int,Int,[I_expr])   
	--  identifier (<level>,<offset>,<array indices>)-}
	IAPP (op, es) -> case op of
--		ICALL (String,Int)
		IADD_F -> load ++ [addF]
			where
				load = codegen_LoadExprs es
		{-IMUL_F 
		ISUB_F 
		IDIV_F 
		INEG_F
		ILT_F  
		ILE_F  
		IGT_F  
		IGE_F  
		IEQ_F          
		IADD 
		IMUL 
		ISUB 
		IDIV 
		INEG
		ILT  
		ILE  
		IGT  
		IGE  
		IEQ            
		INOT 
		IAND 
		IOR 
		IFLOAT 
		ICEIL 
		IFLOOR-}
		
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
			c = [storeO lvl off]
	{-
	IWHILE (e,stmt) -> [label, codegen_LoadExpr e, jumpC, codeGen_Stmt stmt, jump]
	ICOND (e,s1,s2) = [codegen_LoadExpr e, jumpC, codeGen_Stmt s1, label, codeGen_Stmt s2]
	-}
	IREAD_F (lvl,off,es) -> [readF]
	IREAD_I (lvl,off,es) -> [readI]
	IREAD_B (lvl,off,es) -> [readB]
	IPRINT_F x -> (codegen_LoadExpr x) ++ [printF]
	IPRINT_I x -> (codegen_LoadExpr x) ++ [printI]
	IPRINT_B x -> (codegen_LoadExpr x) ++ [printB] 

	--IRETURN e -> [alloc -vars, jump] 	-- .. where to get vars from??
	
	IBLOCK (fbodies,vars,arrs,stmts) -> [pre] ++ enter ++ exit
		where
			pre = comment "Block begin"
			m = vars
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
		prog = init ++ body ++ exit ++ []--funs
				
		init = indent [loadR "%sp", loadR "%sp", storeR "%fp", alloc vars, loadI (vars + 2)]
		body = indent (codegen_Stmts stmts)
		exit = indent [loadR "%fp" , loadO (vars+1), app "NEG", 
			allocS, alloc (-3), halt]
			
stmts = IASS(0,1, [ IAPP(IADD_F,[IINT 1, IINT 2]) ], IINT 0)	
fbody = [] --IFUN ("funky", [], 2, 0, [], [stmts])
prog = IPROG (fbody, 2, [], [stmts])
test = codegen_Prog prog
test2 = codegen_Stmt stmts








