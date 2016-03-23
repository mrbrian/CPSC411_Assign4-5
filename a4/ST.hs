module ST where

import AST

data SYM_DESC = ARGUMENT (String,M_type,Int)
              | VARIABLE (String,M_type,Int)
              | FUNCTION (String,[(M_type,Int)],M_type)
              | DATATYPE String 
              | CONSTRUCTOR (String, [M_type], String)

data SYM_I_DESC = I_VARIABLE (Int,Int,M_type,Int)
                    | I_FUNCTION (Int,String,[(M_type,Int)],M_type)
                    | I_CONSTRUCTOR (Int,[M_type],String)
                    | I_TYPE [String];

data ScopeType = L_PROG | L_FUN M_Type | L_BLK | L_CASE


empty:: ST
empty = []

new_scope :: ScopeType -> ST -> ST
   newscope s = (Symbol_table(0,0,[])):s

lookup :: ST -> String -> SYM_I_DESC 
lookup s x = find 0 s 
   where
      found level (Var_attr(offset,type_,dim)) 
                    =  I_VARIABLE(level,offset,type_,dim)
      found level (Fun_attr(label,arg_Type,type_)) 
                    = I_FUNCTION(level,label,arg_Type,type_)

      find_level ((str,v):rest)|x== str = Just v
                               |otherwise =  find_level rest
      find_level [] = Nothing

      find n [] = error ("Could not find "++ str)
      find n (Symbol_table(_,_,vs)::rest) = 
             (case find_level vs of 
	          Just v -> found n v
		  Nothing -> find (n+1) rest)

insert :: Int -> ST -> SYM_DESC -> (Int,ST) 
insert n [] d =  error "Symbol table error: insertion before defining scope."
insert n ((Symbol_table(nL,nA,sL)):rest) (ARGUMENT(str,t,dim)) 
           | (in_index_list str sL) = error
                ("Symbol table error: " ++ str ++"is already defined.")
           | otherwise = (n,Symbol_table(nL,nA+1
                             ,(str,Var_attr(~(nA+4),T,dim))::sL))
insert n ((Symbol_table(nL,nA,sL)):rest) (VARIABLE (str,T,dim)) 
           | (in_index_list str sL) 
	       = error ("Symbol table error: "++ str ++"is already defined.")
           | otherwise = (n,Symbol_table(nL+1,nA
                             ,(str,Var_attr(nL+1,T,dim))::sL))
insert n ((Symbol_table(nL,nA,sL)):rest) FUNCTION (str,Ts,T)
           | in_index_list str sL 
	       = error ("Symbol table error: "++str++"is already defined.")
           | otherwise = (n+1,(Symbol_table(nL,nA,(str,Fun_attr(getlabel n "fn",Ts,T)):sL)
                              ):rest)
	where in_index_list str [] = False
              in_index_list str ((x,_):xs)| str==x = True
                                          | otherwise = in_index_list str xs
