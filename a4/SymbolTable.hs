module SymbolTable where --(ST,empty,new_scope,insert,lookup,return)

import AST

data SYM_DESC = ARGUMENT (String,M_type,Int)
              | VARIABLE (String,M_type,Int)
              | FUNCTION (String,[(M_type,Int)],M_type)
              | DATATYPE String 
              | CONSTRUCTOR (String, [M_type], String)
              deriving (Eq, Show)
-- I_VARIABLE (level, offset, type, dimension)
-- I_FUNCTION (level, label, [arguments], return type)
-- I_CONSTRUCTOR (int, [type], datatype name)
-- I_TYPE (name);
data SYM_I_DESC = I_VARIABLE (Int,Int,M_type,Int)
                    | I_FUNCTION (Int,String,[(M_type,Int)],M_type)
                    | I_CONSTRUCTOR (Int,[M_type],String)
                    | I_TYPE [String]
                    deriving (Eq, Show)

data ScopeType = L_PROG | L_FUN M_type | L_BLK | L_CASE 
                 deriving (Eq, Show)

--Var_attr (offset, M_type, dim)               
data SYM_VALUE = Var_attr (Int,M_type,Int)
                  | Fun_attr (String,[(M_type,Int)],M_type)
                  | Con_attr (Int, [M_type], String)
                  | Typ_attr [String]
                  deriving (Eq, Show)

-- Symbol_table (leve, offset, [(String,SYM_VALUE)])
data SYM_TABLE = Symbol_table (Int,Int,[(String,SYM_VALUE)])
                 deriving (Eq, Show)

type ST = [SYM_TABLE]

empty:: ST
empty = []

new_scope :: ScopeType -> ST -> ST
new_scope t s = (Symbol_table(0,0,[])) : s

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

      find n [] = error ("Could not find "++ x)
      find n (Symbol_table(_,_,vs):rest) =   -- what is vs... variables?  so get the vars of the first ST
             (case find_level vs of           -- does this ST have the var in it?
	          Just v -> found n v         -- return as an IVAR or IFUN.
		  Nothing -> find (n+1) rest) -- look at next ST.

-- so.  its not a new scope!   so ok yes  inserting a var symbol or something.
insert :: Int -> ST -> SYM_DESC -> (Int,ST) 
insert n [] d = error "Symbol table error: insertion before defining scope."

-- nL = level, nA = numArgs, str = ?, sL = symbolList?
insert n ((Symbol_table(nL,nA,sL)):rest) (ARGUMENT(str,t,dim)) 
	   | (in_index_list str sL) = error ("Symbol table error: " ++ str ++"is already defined.")
	   | otherwise = (n, Symbol_table(nL,nA+1,(str,Var_attr(nA+4,t,dim)) : sL) : rest)	-- what is ~(nA+4)?  offset..  why + 4?  am I inserting a variable??  why nA + 1

insert n ((Symbol_table(nL,nA,sL)):rest) (VARIABLE (str,t,dim)) 
	   | (in_index_list str sL) = error ("Symbol table error: "++ str ++"is already defined.")
	   | otherwise = (n,Symbol_table(nL+1,nA,(str,Var_attr(nL+1,t,dim)):sL) : rest)
	   
insert n ((Symbol_table(nL,nA,sL)):rest) (FUNCTION (str,ts,t))
	   | in_index_list str sL = error ("Symbol table error: "++str++"is already defined.")
	   | otherwise = (n+1,(Symbol_table(nL,nA,(str,Fun_attr(getlabel n "fn",ts,t)):sL)):rest)

in_index_list :: String -> [(String, SYM_VALUE)] -> Bool
in_index_list str [] = False
in_index_list str ((x,_):xs)
	  | str == x = True
	  | otherwise = in_index_list str xs

getlabel :: Int -> String -> String
getlabel n str = ""

--	  | 
--return:: ST -> M_type

--process :: M_prog -> ST
-- every M_decl node 
