module Semantic where

import AST
import SymbolTable
	
exist :: ST -> String -> Bool
exist s x = find 0 s 
   where
      found level (Var_attr(offset,type_,dim)) 
                    =  True
      found level (Fun_attr(label,arg_Type,type_)) 
                    = True
      found level (Typ_attr cL) 
                    = True
					
      find_level ((str,v):rest)|x== str = Just v
                               |otherwise =  find_level rest
      find_level [] = Nothing

      find n [] = False
      find n (Symbol_table(_,_,_,vs):rest) =  -- what is vs... variables?  so get the vars of the first ST
             (case find_level vs of         -- does this ST have the var in it?
               Just v -> found n v         	-- return as an IVAR or IFUN.
               Nothing -> find (n+1) rest) 		-- look at next ST.

			 
collect_decl :: M_decl -> ST -> ST
collect_decl (M_var (name, es, typ)) st = st'
  where 
    (n, st') = insert 0 st (VARIABLE (name, typ, dim)) 
    dim = length es
	
	
collect_decl (M_fun (name, args, rt, ds, sts)) st = st'
  where 
    (n, st') = insert 0 st (VARIABLE (name, typ, dim)) 
    dim = length es
	
check_decl :: M_decl -> ST -> Bool
check_decl (M_var (name, es, t)) st = v
  where
    v1 = exist st name
    v2 = wf_exprs es st
    v = v1 && v2
	
{-check_decl (M_fun ) st = v
  where 
    v1 = 
    v2 = 
    v = -}
	
wf_exprs :: [M_expr] -> ST -> Bool
wf_exprs [] st = True
wf_exprs (e:es) st = v
  where
    v1 = wf_expr e st
    v2 = wf_exprs es st
    v = v1 && v2

get_dim :: String -> ST -> Int
get_dim str st = dim
  where 
    (I_VARIABLE (lvl, off, typ, dim)) = look_up st str
     
--  so.. i can check if msize is wellformed..  
-- but. should i be thinking about sending an error back someday?
-- that would seem more helpful?  and what about actually sending the value back?  
-- that must be from the stack machine code.

-- i will be able to check if something is well formed.. so.  how is that used in doing the IR?
-- prashant says it can be done separate.


wf_expr :: M_expr -> ST -> Bool
wf_expr (M_ival v) _ = True
wf_expr (M_rval v) _ = True
wf_expr (M_bval v) _ = True
wf_expr (M_size (str, n)) st = v
  where
    v1 = exist st str
    dim = get_dim str st
    v  = v1 && (n < dim) && (dim >= 0)	
wf_expr (M_id (str, es)) st = v
  where 
    v1 = exist st str
    v2 = wf_exprs es st
    v = v1 && v2
wf_exp (M_app (_, e)) st = v
  where
	v = wf_exprs e st
wf_exp _  _ = False

{-
            | M_rval Float
            | M_bval Bool
            | M_size (String,Int)
            | M_id (String,[M_expr])
            | M_app (M_operation,[M_expr])-}