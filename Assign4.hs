module Main where

-- Haskell module generated by the BNF converter

import Text.Show.Pretty 
import LexMp
import ParMp
import ErrM
import System.Environment
import AbsMp
import SkelMp
import AST
import SymbolTable
--import Semantic
import IR

transFuns :: [M_decl] -> ST -> [I_fbody]
transFuns [] st = []
transFuns (d:ds) st = (transFun d st):(transFuns ds st)

transFun :: M_decl -> ST -> I_fbody
transFun (M_fun (fn, fas, frt, fds, fsts)) st =  I_FUN (fL, fbs', fnv, fna, farrs, fstmts)
	where
		I_FUNCTION (flvl, fL, fargs, frt) = look_up st fn
		fbs = filter isFun fds   				-- look for funs inside..
		fbs' = transFuns fbs st
		fvs = filter isVar fds
		fnv = length fvs
		fna = length fas
		fstmts = transStmts fsts
		farrs = []
		
gen_ST_Prog :: M_prog -> I_prog
gen_ST_Prog (M_prog (ds, sts)) = I_PROG (fs', nv, [], [])
   where
     st  = new_scope L_PROG empty
     st'  = gen_ST_Decls 0 st ds
	 
     vs = filter isVar ds
	 
     nv = length vs
     --arrs = isArray vs
	 
     fs = filter isFun ds
     fs' = transFuns fs st'
     st'' = gen_ST_Stmts 0 st' sts
    

gen_ST_Decls :: Int -> ST -> [M_decl] -> ST
gen_ST_Decls n st [] = st
gen_ST_Decls n st decls = st''
     where 
        vs = filter isVar decls
        fs = filter isFun decls
        (d:rest) = vs++fs
        st'    = gen_ST_Decl n st d
        st''   = gen_ST_Decls n st' rest

--   M_fun (String,[(String,Int,M_type)],M_type,[M_decl],[M_stmt]) ->
--   M_data (String,[(String,[M_type])]) ->
--   ARGUMENT (name, ty, val) -> insert n? (gen_ST_Decl st d) : (gen_ST_Decls rest)


gen_ST_Decl :: Int -> ST -> M_decl -> ST
gen_ST_Decl n st d = proc_d n st d
   where
     add_args n st [] = st
     add_args n st ((name, dim, typ):ps) = add_args n' st' ps
       where (n', st') = insert n st (ARGUMENT (name, typ, dim)) 
	 
     proc_d n st d = case d of
       M_var (name, arrSize, typ) -> st'
	     where (fn, st') = insert n st (VARIABLE (name, typ, length arrSize))     
       M_fun (name,pL,rT,ds,_) -> st''''
         where 
           (n', st') = insert (n+1) st (FUNCTION (name, [], rT))
           st'' = new_scope (L_FUN rT) st'
           st''' = add_args n' st'' pL
           st'''' = gen_ST_Decls n' st''' ds
		   --I_FUN ("fn"++(show (n+1)), locfuns, nv, na, arrs, body)
		   --locfuns = filter funs.
		   
gen_ST_Stmts :: Int -> ST -> [M_stmt] -> ST
gen_ST_Stmts n st [] = st 
gen_ST_Stmts n st (s:rest) = st''
    where
       st'  = gen_ST_Stmt n st s
       st'' = gen_ST_Stmts n st' rest

gen_ST_Stmt :: Int -> ST -> M_stmt -> ST
gen_ST_Stmt n st d = case d of
--M_cond (M_expr, M_stmt,M_stmt) 
	M_cond (e, s1, s2) -> st''
           where 
              st' = gen_ST_Stmt n st s1
              st'' = gen_ST_Stmt n st' s2
	M_block (decls, stmts) -> st''
           where 
              st' = new_scope L_BLK st
              st''= gen_ST_Decls n st' decls
	x -> st

{-	data M_stmt = M_ass (String,[M_expr], M_expr)
            | M_while (M_expr, M_stmt)
            | M_cond (M_expr, M_stmt,M_stmt) 
            | M_read (String, [M_expr])
            | M_print (M_expr)
            | M_return (M_expr)
            | M_block ([M_decl],[M_stmt])
-}
			
main = do
    args <- getArgs
    conts <- readFile (args !! 0)
    let tok = tokens conts
    let ptree = pProg tok       
    putStrLn "The AST Tree:\n"
    case ptree of
        Ok  tree -> do
            let ast = transProg tree
            let st = gen_ST_Prog ast 
            putStrLn $ ((ppShow ast) ++ "\n\n" ++ (ppShow st))
        Bad msg-> putStrLn msg
