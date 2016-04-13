
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
loadB n = "LOAD_B " ++ (show n)
loadO n = "LOAD_O " ++ (show n)

readI = "READ_I"
readR = "READ_R"
readB = "READ_B"

storeI s = "STORE_I "  ++ s
storeR s = "STORE_R "  ++ s
storeB s = "STORE_B "  ++ s

jump s = "JUMP " ++ s
jumpS = "JUMP_S"

alloc n = "ALLOC "  ++ (show n)

{-
codegen_function :: I_fbody -> String
IFUN (String,[I_fbody],vars,Int,[(Int,[I_expr])],[I_stmt]) = 
	where
		init = [loadR "%sp", storeR "%fp", alloc vars]
		
		exit = indent [loadI "vars"]
	-}	
	
codeGen_Fun :: I_fbody -> [String]
codeGen_Fun (IFUN (label, fb, vars, args, arrays, stmts)) = caller ++ init ++ exit
--(String,[I_fbody],Int,Int,[(Int,[I_expr])],[I_stmt])
	where
		caller = [alloc 1, loadR "%fp", loadR "%fp", loadO (-1), loadO (-1), storeR "%cp", jump label]
		init = []--[label, lordR "%sp", storeR "%fp", alloc m, loadI m+3]
		exit = [loadR "%fp", --store.., 
			loadR "%fp", --loadO 0, 
			loadR "%fp", jumpS]

codegen_Expr :: I_expr -> [String]
codegen_Expr e = case e of
	IINT x -> [show x]
	IREAL x -> [show x]
	IBOOL x -> [show x]
	{-IID       (Int,Int,[I_expr])   
	--  identifier (<level>,<offset>,<array indices>)
	IAPP      (I_opn,[I_expr])
	ISIZE     (Int,Int,Int)-}
				   
codegen_Stmt :: I_stmt -> [String]
codegen_Stmt s = case s of
	IASS (lvl,off,es,e) -> [loadI ""]
		{-where
			codegen_Expr e
	IWHILE (I_expr,I_stmt)
	ICOND (I_expr,I_stmt,I_stmt)-}
	IREAD_F (lvl,off,es) -> [readR]
	IREAD_I (lvl,off,es) -> [readI]
	IREAD_B (lvl,off,es) -> [readB]
{-	IPRINT_F e -> [printF ]
	IPRINT_I e -> [printI ]
	IPRINT_B e -> [printB ] -}

	--IRETURN e -> [alloc -vars, jump] 	-- .. where to get vars from??
	--IBLOCK (f,vars,arrs,stmts) -> 
	
	
codegen_Stmts :: [I_stmt] -> [String]
codegen_Stmts [] = []
codegen_Stmts (s:rest) = first++next
	where
		first = codegen_Stmt s
		next = codegen_Stmts rest
		
		
printlist :: [String] -> String
printlist [] = ""
printlist (s:rest) = s ++ "\n" ++ (printlist rest)


codegen_Prog :: I_prog -> String
codegen_Prog (IPROG (fbs,vars,c,stmts)) = printlist prog
	where
		prog = init ++ body ++ exit ++ []--funs
				
		init = [loadR "%sp", loadR "%sp", storeR "%fp", alloc vars, loadI (vars + 2)]
		body = codegen_Stmts stmts
		exit = []--indent [loadR "%fp" , load0 (vars+1), app "NEG" , allocS
			--, alloc -3, halt]
		
test = codeGen_Fun (IFUN ("funky", [], 1, 0, [], [])) 