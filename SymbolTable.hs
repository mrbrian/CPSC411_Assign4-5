module SymbolTable where --(ST,empty,new_scope,insert,lookup,return)

import AST

data SYM_DESC = ARGUMENT (String, M_type, Int)
              | VARIABLE (String, M_type, Int)
              | FUNCTION (String, [(M_type,Int)], M_type)
              deriving (Eq, Show)

data SYM_I_DESC = I_VARIABLE (Int,Int,M_type,Int)
              | I_FUNCTION (Int,String,[(M_type,Int)],M_type)
              deriving (Eq, Show)

data ScopeType = L_PROG | L_FUN M_type | L_BLK | L_CASE 
              deriving (Eq, Show)

--Var_attr (offset, M_type, dim)               
data SYM_VALUE = Var_attr (Int, M_type, Int)
              | Fun_attr (String,[(M_type,Int)],M_type)
              deriving (Eq, Show)

-- Symbol_table (scopetype, #localvars, #args, [(String,SYM_VALUE)])
data SYM_TABLE = Symbol_table (ScopeType, Int, Int, [(String,SYM_VALUE)])
              deriving (Eq, Show)

type ST = [SYM_TABLE]

empty:: ST
empty = []

new_scope :: ScopeType -> ST -> ST
new_scope t s = (Symbol_table(t,0,0,[])) : s


look_up :: ST -> String -> SYM_I_DESC 
look_up s x = find 0 s 
   where
      found level (Var_attr(offset,type_,dim)) 
                    =  I_VARIABLE(level,offset,type_,dim)
      found level (Fun_attr(label,arg_Type,type_)) 
                    = I_FUNCTION(level,label,arg_Type,type_)
      find_level ((str,v):rest)|x== str = Just v
                               |otherwise =  find_level rest
      find_level [] = Nothing

      find n [] = error ("Could not find "++ x)
      find n (Symbol_table(_,_,_,vs):rest) = 
             (case find_level vs of         
               Just v -> found n v         	
               Nothing -> find (n+1) rest) 	

insert :: Int -> ST -> SYM_DESC -> (Int,ST) 
insert n [] d = error "Symbol table error: insertion before defining scope."

insert n ((Symbol_table(sT, nL,nA,sL)):rest) (ARGUMENT(str,t,dim)) 								
	   | (in_index_list str sL) = error ("Symbol table error: " ++ str ++"is already defined.")
	   | otherwise = (n, Symbol_table(sT, nL,nA+1,(str,Var_attr(negate(nA + 4),t,dim)) : sL) : rest)	

insert n ((Symbol_table(sT, nL,nA,sL)):rest) (VARIABLE (str,t,dim)) 
	   | (in_index_list str sL) = error ("Symbol table error: "++ str ++"is already defined.")
	   | otherwise = (n,Symbol_table(sT, nL+1,nA,(str,Var_attr(nL+1,t,dim)):sL) : rest)
	   
insert n ((Symbol_table(sT, nL,nA,sL)):rest) (FUNCTION (str,ts,t))
	   | in_index_list str sL = error ("Symbol table error: "++str++"is already defined.")
	   | otherwise = (n+1,(Symbol_table(sT, nL,nA,(str,Fun_attr(get_label n "fn",ts,t)):sL)):rest)

in_index_list :: String -> [(String, SYM_VALUE)] -> Bool
in_index_list str [] = False
in_index_list str ((x,_):xs)
	  | str == x = True
	  | otherwise = in_index_list str xs

get_label :: Int -> String -> String
get_label n str = str ++ (show n) 

remove_scope :: ST -> (Int, ST)
remove_scope [] = (0, [])
remove_scope (s:rest) = (nL, rest)
	where
		Symbol_table (_, nL, _, _) = s

return :: ST -> M_type
return [] = error "no return type"
return (s:rest) = case sT of
	L_FUN t -> t
	x -> error "no return type"
	where 
		Symbol_table (sT,_,_,_) = s

