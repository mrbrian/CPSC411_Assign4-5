-------------------------------------------------
--
--      Type checking pure expressions using a symbol table:
--         using a higher-order and first-order style
--
-------------------------------------------------

--  Success or fail datatype
data SF a = FF | SS a
     deriving (Show,Eq)


-- Expression datatype
data Exp a b = Var b
             | Opn a [Exp a b]
     deriving (Show,Eq)

-- Basic operations which are available
data Opn = AND|ADD|OR|MUL|GEQ
     deriving (Show,Eq)

-- Basic types
data TYPE = INT|BOOL
     deriving (Show,Eq)

-- Symbol table type
type ST = [(String,TYPE)]


-- The fold function for expressions
foldexp:: (b -> c) -> (a -> [c] -> c) -> (Exp a b) -> c
foldexp f g (Var b) = f b
foldexp f g (Opn a as) = g a (map (foldexp f g) as) 


-- code for type checking an expression 

--
-- first version uses a higher-order fold
--
type_exp1:: (Exp Opn String) -> (ST -> (SF TYPE))
type_exp1 e = foldexp look_up type_opn e where
      look_up str = \st -> case st of
                               [] -> FF
                               ((s,t):sts) | s==str -> SS t
                                              | otherwise -> look_up str sts
      type_opn op [f1,f2] 
           = \s -> case (op,[f1 s,f2 s]) of 
               (AND,[SS BOOL,SS BOOL]) -> SS BOOL
               (OR, [SS BOOL,SS BOOL]) -> SS BOOL
               (ADD, [SS INT,SS INT]) -> SS INT
               (MUL, [SS INT,SS INT]) -> SS INT
               (GEQ, [SS INT,SS INT]) -> SS BOOL
               _ -> FF

--
-- second version uses first-order code
--
type_exp2::  (Exp Opn String) -> ST -> (SF TYPE)
type_exp2 (Var name) st = look_up name st
     where
           look_up name [] = FF
           look_up name ((v,t):vs)| name==v = SS t
                                              | otherwise = look_up name vs
type_exp2 (Opn f args) st
     = case (f,(map (\e -> type_exp2 e st) args)) of
               (AND,[SS BOOL,SS BOOL]) -> SS BOOL
               (OR, [SS BOOL,SS BOOL]) -> SS BOOL
               (ADD, [SS INT,SS INT]) -> SS INT
               (MUL, [SS INT,SS INT]) -> SS INT
               (GEQ, [SS INT,SS INT]) -> SS BOOL
               _ -> FF

-- simple tests
test1 = type_exp1 (Opn AND [Var "x",Opn GEQ [Var "y",Var "z"]]) [("x",BOOL),("y",INT),("z",INT)]
test2 = type_exp2 (Opn AND [Var "x",Opn GEQ [Var "y",Var "z"]]) [("x",BOOL),("y",INT),("z",INT)]
test3 = type_exp1 (Opn MUL [Var "y",Opn GEQ [Var "y",Var "z"]]) [("y",INT),("z",INT)]
test4 = type_exp1 (Opn MUL [Var "y",Opn GEQ [Var "y",Var "z"]]) [("y",INT),("z",INT)]