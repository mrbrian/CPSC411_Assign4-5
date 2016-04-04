-------------------------------------------------
--
--      Type checking  and evaluating let expressions using a symbol table:
--         using a higher-order and first-order style
--
-------------------------------------------------

--  Success or fail datatype
data SF a = FF | SS a
     deriving (Show,Eq)


-- Let expression datatype
data LetExp a b = Var b
                          | Opn a [LetExp a b]
                          | Let [(b,LetExp a  b)] (LetExp a b)
     deriving (Show,Eq)

-- The fold function for expressions
foldletexp:: (b -> c) -> (a -> [c] -> c) -> ([(b,c)] -> c -> c) -> (LetExp a b) -> c
foldletexp f g h (Var b) = f b
foldletexp f g h (Opn a as) = g a (map (foldletexp f g h) as) 
foldletexp f g h (Let dcls exp) = h (map (\(b,e) -> (b,foldletexp  f g h e)) dcls) (foldletexp  f g h exp)


-- Basic operations which are available
data Opn = AND|ADD|OR|MUL|GEQ                 -- arity 2
                |TRUE|FALSE|NUM Int                       -- constants arity 0
     deriving (Show,Eq)

-- Basic types
data TYPE = INT|BOOL
     deriving (Show,Eq)

-- Basic values
data VALUE = VBOOL Bool
           | VINT Int
     deriving (Show,Eq)

-- Symbol table type
type ST = [(String,(TYPE,VALUE))]

--------------------------------------------------------------
--
-- typing a let expression (and returning its value)
--            (higher-order fold version)
--
--------------------------------------------------------------
type_letexp1:: (LetExp Opn String) -> (ST -> (SF (TYPE,VALUE)))
type_letexp1 = foldletexp f g h 
      where 
            -- look up variable in symbol table
            f name = look_up name 
            -- splits operations into none and two argument operations
            g opn [f1,f2] st = g2 opn [f1 st,f2 st]  
            g opn [] st = g1 opn []
            g _ _ _ = FF
            
            -- types and evaluates two argument operations
            g2  ADD [SS(INT,VINT(n1)),SS(INT,VINT(n2))] = SS(INT,VINT(n1+n2))
            g2  MUL [SS(INT,VINT(n1)),SS(INT,VINT(n2))] = SS(INT,VINT(n1*n2))
            g2  AND [SS(BOOL,VBOOL(n1)),SS(BOOL,VBOOL(n2))] = SS(BOOL,VBOOL(n1 && n2))
            g2  OR  [SS(BOOL,VBOOL(n1)),SS(BOOL,VBOOL(n2))] = SS(BOOL,VBOOL(n1 || n2))
            g2  GEQ [SS(INT,VINT(n1)),SS(INT,VINT(n2))] = SS(BOOL,VBOOL(n1 <= n2))
            g2 _ _= FF

            -- types and evaluates constants 
            g1  TRUE [] = SS(BOOL,VBOOL(True))
            g1  FALSE [] = SS(BOOL,VBOOL(False))
            g1  (NUM n) [] = SS(INT,VINT(n))
            g1 _ _ = FF

            -- processes let declaration sequences (sequential declaration semantics!)
            h [] e st = e st
            h ((n,tf):tfs) e st = case tf st of 
                                   SS tv -> h tfs e ((n,tv):st)
                                   --- pushes stuff into symbol table here!
                                   FF -> FF

--------------------------------------------------------------
--
-- typing a let expression (and returning its value)
--        (first-order version -- added later!)
--
--------------------------------------------------------------
type_letexp2:: (LetExp Opn String) -> ST -> (SF (TYPE,VALUE))
-- processes variabless
type_letexp2 (Var name) st = look_up name st
-- processes operations applied to arguments
-- types and evaluate two argument operations
type_letexp2 (Opn opn [t1,t2]) st = g2 opn [type_letexp2 t1 st,type_letexp2 t2 st] 
     where              
            g2  ADD [SS(INT,VINT(n1)),SS(INT,VINT(n2))] = SS(INT,VINT(n1+n2))
            g2  MUL [SS(INT,VINT(n1)),SS(INT,VINT(n2))] = SS(INT,VINT(n1*n2))
            g2  AND [SS(BOOL,VBOOL(n1)),SS(BOOL,VBOOL(n2))] = SS(BOOL,VBOOL(n1 && n2))
            g2  OR  [SS(BOOL,VBOOL(n1)),SS(BOOL,VBOOL(n2))] = SS(BOOL,VBOOL(n1 || n2))
            g2  GEQ [SS(INT,VINT(n1)),SS(INT,VINT(n2))] = SS(BOOL,VBOOL(n1 <= n2))
            g2 _ _= FF
-- types and evaluates constants 
type_letexp2 (Opn opn []) st = g1 opn []
      where            
            g1  TRUE [] = SS(BOOL,VBOOL(True))
            g1  FALSE [] = SS(BOOL,VBOOL(False))
            g1  (NUM n) [] = SS(INT,VINT(n))
            g1 _ _ = FF
-- processes let expressions
type_letexp2 (Let [] exp) st = type_letexp2 exp st
type_letexp2 (Let ((name,exp1):rest) exp) st = 
                case (type_letexp2 exp1 st) of 
                     SS tv -> type_letexp2 (Let rest exp) ((name,tv):st)  
                                    --- pushes stuff into symbol table here!
                     FF -> FF
type_letexp2  _ _ = FF

          

-- Symbol table look up
look_up:: String -> ST -> (SF (TYPE,VALUE))
look_up name [] = FF
look_up name ((n,tv):rest)| n==name = SS tv
                          | otherwise = look_up name rest


----------------------------------------------------------------------------
--
--  Test starting with empty symbol table
--
----------------------------------------------------------------------------

test1 = type_letexp1 (Opn AND [Let [("x", Opn (NUM 2) [])
                                   ,("y", Opn (NUM 3) [])
                                   ,("x", Opn ADD [Var "x",Var "x"])
                                   ,("z", Opn TRUE [])]
                                   (Opn AND [Opn GEQ [Var "x",Var "y"]
                                            ,Var "z"])
                              ,Let [("x", Opn (NUM 2) [])
                                   ,("y", Opn (NUM 1) [])]
                                   (Opn GEQ [Var "y"
                                            ,Var "x"])
                              ]) 
                     [] --- the starting symbol table

test2 = type_letexp2 (Opn AND [Let [("x", Opn (NUM 2) [])
                                   ,("y", Opn (NUM 3) [])
                                   ,("x", Opn ADD [Var "x",Var "x"])
                                   ,("z", Opn TRUE [])]
                                   (Opn AND [Opn GEQ [Var "x",Var "y"]
                                            ,Var "z"])
                              ,Let [("x", Opn (NUM 2) [])
                                   ,("y", Opn (NUM 1) [])]
                                   (Opn GEQ [Var "y"
                                            ,Var "x"])
                              ]) 
                     [] --- the starting symbol table