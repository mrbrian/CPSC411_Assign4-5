module SymbolTable where --(ST,empty,new_scope,insert,lookup,return)

import AST

data SYM_DESC = ARGUMENT (String, M_type, Int)
              | VARIABLE (String, M_type, Int)
              | FUNCTION (String, [(M_type,Int)], M_type)
              | DATATYPE String 
              | CONSTRUCTOR (String, [M_type], String)
              deriving (Eq, Show)
-- I_VARIABLE (level, offset, type, dimension)
-- I_FUNCTION (level, label, [arguments], return type)
-- I_CONSTRUCTOR (constructor#, [type], datatype name)
-- I_TYPE (name);

data SYM_I_DESC = I_VARIABLE (Int,Int,M_type,Int)
                    | I_FUNCTION (Int,String,[(M_type,Int)],M_type)
                    | I_CONSTRUCTOR (Int,[M_type],String)
                    | I_TYPE [String]
                    deriving (Eq, Show)

data ScopeType = L_PROG | L_FUN M_type | L_BLK | L_CASE 
                 deriving (Eq, Show)

--Var_attr (offset, M_type, dim)               
data SYM_VALUE = Var_attr (Int, M_type, Int)
                  | Fun_attr (String,[(M_type,Int)],M_type)
                  | Con_attr (Int, [M_type], String)
                  | Typ_attr [String]
                  deriving (Eq, Show)

-- Symbol_table (scopetype, #localvars, #args, [(String,SYM_VALUE)])
data SYM_TABLE = Symbol_table (ScopeType, Int, Int, [(String,SYM_VALUE)])
                 deriving (Eq, Show)

type ST = [SYM_TABLE]

test_st :: ST
test_st = 
    [ Symbol_table(L_FUN M_int, 1,2,[ ("a",Var_attr(-5,M_int,0))
                       , ("b",Var_attr(-4,M_int,0))
                       , ("y",Var_attr(1,M_int,0))])
    , Symbol_table(L_FUN M_int, 1,2,[ ("y",Var_attr(-5,M_int,0))
                       , ("z",Var_attr(-4,M_int,0))
                       , ("x",Var_attr(1,M_int,0))
                       , ("a",Var_attr(2,M_int,2))
                       , ("g",Fun_attr("code_label_g",[(M_int,0),(M_int,2)],M_int))])
    , Symbol_table(L_PROG, 2,0,[ ("x",Var_attr(1,M_int,0))
                       , ("f",Fun_attr("code_label_f",[(M_int,0),(M_int,0)],M_int))
                       , ("v",Var_attr(2,M_int,0))])
    ]	

empty:: ST
empty = []

-- what does this do    add a symbol table to the stack?  yes   why diff types?  
new_scope :: ScopeType -> ST -> ST
new_scope t s = (Symbol_table(t,0,0,[])) : s

look_up :: ST -> String -> SYM_I_DESC 
look_up s x = find 0 s 
   where
      found level (Var_attr(offset,type_,dim)) 
                    =  I_VARIABLE(level,offset,type_,dim)
      found level (Fun_attr(label,arg_Type,type_)) 
                    = I_FUNCTION(level,label,arg_Type,type_)
      found level (Typ_attr cL) 
                    = I_TYPE cL
		{-
                    | I_CONSTRUCTOR (Int,[M_type],String)
                    | I_TYPE [String]
-}
      find_level ((str,v):rest)|x== str = Just v
                               |otherwise =  find_level rest
      find_level [] = Nothing

      find n [] = error ("Could not find "++ x)
      find n (Symbol_table(_,_,_,vs):rest) =  -- what is vs... variables?  so get the vars of the first ST
             (case find_level vs of         -- does this ST have the var in it?
	          Just v -> found n v         	-- return as an IVAR or IFUN.
		  Nothing -> find (n+1) rest) 		-- look at next ST.

-- so.  its not a new scope!   so ok yes  inserting a var symbol or something.
-- n = current function label # ??
insert :: Int -> ST -> SYM_DESC -> (Int,ST) 
insert n [] d = error "Symbol table error: insertion before defining scope."

-- sT = scope type, nL = level, nA = numArgs, str = ?, sL = symbolList?
insert n ((Symbol_table(sT, nL,nA,sL)):rest) (ARGUMENT(str,t,dim)) 								-- adding an arg..
	   | (in_index_list str sL) = error ("Symbol table error: " ++ str ++"is already defined.")
	   | otherwise = (n, Symbol_table(sT, nL,nA+1,(str,Var_attr(negate(nA + 4),t,dim)) : sL) : rest)	-- what is ~(nA+4)?  offset..  why + 4?  am I inserting a variable??  why nA + 1

insert n ((Symbol_table(sT, nL,nA,sL)):rest) (VARIABLE (str,t,dim)) 
	   | (in_index_list str sL) = error ("Symbol table error: "++ str ++"is already defined.")
	   | otherwise = (n,Symbol_table(sT, nL+1,nA,(str,Var_attr(nL+1,t,dim)):sL) : rest)
	   
insert n ((Symbol_table(sT, nL,nA,sL)):rest) (FUNCTION (str,ts,t))
	   | in_index_list str sL = error ("Symbol table error: "++str++"is already defined.")
	   | otherwise = (n+1,(Symbol_table(sT, nL,nA,(str,Fun_attr(get_label n "label_fn_",ts,t)):sL)):rest)
	   
insert n ((Symbol_table(sT, nL,nA,sL)):rest) (DATATYPE str)			
	   | in_index_list str sL = error ("Symbol table error: "++str++"is already defined.")
	   | otherwise = (n,(Symbol_table(sT, nL+1, nA,(str, Typ_attr []):sL)):rest)
	   
	   -- constructor#  const type   const Datatype
insert n symTab (CONSTRUCTOR (cName,cInput,cType))
	   | in_index_list cName sL = error ("Symbol table error: "++cName++"is already defined.")	   
	   | otherwise = (n,(Symbol_table(sT, nL,nA,newHead:newSymList)):rest)
	   where 
	   ((Symbol_table(sT, nL,nA,sL)) : rest) = symTab  	-- deconstruct
	   ((sN, sV) : sLrest) = sL				-- get symbol list
	   I_TYPE (cL) = look_up symTab cType 			-- get contructor name list
           newSymList = addCons cName [] sL			-- insert constructor name
           cNum = (length cL) + 1				-- constructor num
           newHead = (cName, Con_attr(cNum,cInput,cType))	-- make new symbol
           -- insert constructor into Typ_attr's list
	   addCons c preL [] = preL
	   addCons c preL ((typName, Typ_attr cL):rest) = (preL++[(typName, Typ_attr (c:cL))]++rest)
	   addCons c preL (a:rest) = addCons c (preL++[a]) rest

-- checks if var is in a symbol table's list
in_index_list :: String -> [(String, SYM_VALUE)] -> Bool
in_index_list str [] = False
in_index_list str ((x,_):xs)
	  | str == x = True
	  | otherwise = in_index_list str xs


-- whats the number for?
get_label :: Int -> String -> String
get_label n str = str ++ (show n) --error "not implemented"

-- just popping off the top scope?   
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

