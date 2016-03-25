module SkelMpp where

-- Haskell module generated by the BNF converter

import AbsMpp
import ErrM
import AST

type Result = Err String

failure :: Show a => a -> Result
failure x = Bad $ "Undefined case: " ++ show x

transIdent :: Ident -> String
transIdent x = case x of
  Ident string -> string
  
transCID :: CID -> String
transCID x = case x of
  CID string -> string
  
transIVAL :: IVAL -> Int
transIVAL x = case x of
  IVAL string -> read string
  
transRVAL :: RVAL -> Float
transRVAL x = case x of
  RVAL string -> read string
  
transBVAL :: BVAL -> Bool
transBVAL x = case x of
  BVAL "true" -> True
  BVAL "false" -> False
  
transCVAL :: CVAL -> Char
transCVAL x = case x of
  CVAL string -> string !! 0
  
transProg :: Prog -> M_prog 
transProg x = case x of
  ProgBlock block -> M_prog (transBlock block)
  
transBlock :: Block -> ([M_decl],[M_stmt])
transBlock x = case x of
  Block1 declarations programbody -> (transDeclarations declarations, transProgram_body programbody)
  
transDeclarations :: Declarations -> [M_decl]
transDeclarations x = case x of
  Declarations1 declaration declarations -> (transDeclaration declaration)++(transDeclarations declarations)
  Declarations2 -> []
  
transDeclaration :: Declaration -> [M_decl]
transDeclaration x = case x of
  DeclarationVar_declaration vardeclaration -> transVar_declaration vardeclaration
  DeclarationFun_declaration fundeclaration -> [transFun_declaration fundeclaration]
  DeclarationData_declaration datadeclaration -> [transData_declaration datadeclaration]
  
transVar_declaration :: Var_declaration -> [M_decl]
transVar_declaration x = case x of
  Var_declaration1 varspecs type_ -> transVar_specs varspecs type_
	
transVar_specs :: Var_specs -> Type -> [M_decl]
transVar_specs x type_ = case x of
  Var_specs1 varspec morevarspecs -> (transVar_spec varspec type_) : (transMore_var_specs morevarspecs type_)
  
transMore_var_specs :: More_var_specs -> Type -> [M_decl]
transMore_var_specs x type_ = case x of
  More_var_specs1 varspec morevarspecs -> (transVar_spec varspec type_) : (transMore_var_specs morevarspecs type_)
  More_var_specs2 -> []
  
transVar_spec :: Var_spec -> Type -> M_decl
transVar_spec x type_ = case x of
  Var_spec1 ident arraydimensions -> M_var (transIdent ident, transArray_dimensions arraydimensions, transType type_)
  
transArray_dimensions :: Array_dimensions -> [M_expr]
transArray_dimensions x = case x of
  Array_dimensions1 expr arraydimensions -> (transExpr expr) : (transArray_dimensions arraydimensions)
  Array_dimensions2 -> []
  
transType :: Type -> M_type
transType x = case x of
  Type_int -> M_int
  Type_real -> M_real
  Type_bool -> M_bool
  Type_char -> M_char
  TypeIdent ident -> M_type (transIdent ident)
  
transFun_declaration :: Fun_declaration -> M_decl
transFun_declaration x = case x of
  Fun_declaration1 ident paramlist type_ funblock -> do
    let (ds, sts) = transFun_block funblock
    M_fun (transIdent ident, transParam_list paramlist, transType type_, ds, sts)
  
transFun_block :: Fun_block -> ([M_decl],[M_stmt])
transFun_block x = case x of
  Fun_block1 declarations funbody -> (transDeclarations declarations, transFun_body funbody)
  
transParam_list :: Param_list -> [(String,Int,M_type)]
transParam_list x = case x of
  Param_list1 parameters -> transParameters parameters
  
transParameters :: Parameters -> [(String,Int,M_type)]
transParameters x = case x of
  Parameters1 basicdeclaration moreparameters -> (transBasic_declaration basicdeclaration) : (transMore_parameters moreparameters)
  Parameters2 -> []
  
transMore_parameters :: More_parameters -> [(String,Int,M_type)]
transMore_parameters x = case x of
  More_parameters1 basicdeclaration moreparameters -> (transBasic_declaration basicdeclaration) : (transMore_parameters moreparameters)
  More_parameters2 -> []
  
transBasic_declaration :: Basic_declaration -> (String,Int,M_type)
transBasic_declaration x = case x of
  Basic_declaration1 ident basicarraydimensions type_ -> (transIdent ident, transBasic_array_dimensions basicarraydimensions, transType type_)
  
transBasic_array_dimensions :: Basic_array_dimensions -> Int
transBasic_array_dimensions x = case x of
  Basic_array_dimensions1 basicarraydimensions -> (transBasic_array_dimensions basicarraydimensions) + 1
  Basic_array_dimensions2 -> 0
  
transData_declaration :: Data_declaration -> M_decl
transData_declaration x = case x of
  Data_declaration1 ident consdeclarations -> M_data (transIdent ident, transCons_declarations consdeclarations)
  
transCons_declarations :: Cons_declarations -> [(String,[M_type])]
transCons_declarations x = case x of
  Cons_declarations1 consdecl moreconsdecl -> (transCons_decl consdecl) : (transMore_cons_decl moreconsdecl)
  
transMore_cons_decl :: More_cons_decl -> [(String,[M_type])]
transMore_cons_decl x = case x of
  More_cons_decl1 consdecl moreconsdecl -> (transCons_decl consdecl) : (transMore_cons_decl moreconsdecl)
  More_cons_decl2 -> []
  
transCons_decl :: Cons_decl -> (String,[M_type])
transCons_decl x = case x of
  Cons_decl1 cid typelist -> (transCID cid, transType_list typelist)
  Cons_declCID cid -> (transCID cid, [])
  
transType_list :: Type_list -> [M_type]
transType_list x = case x of
  Type_list1 type_ moretype -> (transType type_) : (transMore_type moretype)
  
transMore_type :: More_type -> [M_type]
transMore_type x = case x of
  More_type1 type_ moretype -> (transType type_) : (transMore_type moretype)
  More_type2 -> []
  
transProgram_body :: Program_body -> [M_stmt]
transProgram_body x = case x of
  Program_body1 progstmts -> transProg_stmts progstmts 
  Program_bodyProg_stmts progstmts -> transProg_stmts progstmts
  
transFun_body :: Fun_body -> [M_stmt]
transFun_body x = case x of
  Fun_body1 progstmts expr -> (transProg_stmts progstmts) ++ [M_return (transExpr expr)]
  Fun_body2 progstmts expr -> (transProg_stmts progstmts) ++ [M_return (transExpr expr)]
  
transProg_stmts :: Prog_stmts -> [M_stmt]
transProg_stmts x = case x of
  Prog_stmts1 progstmt progstmts -> (transProg_stmt progstmt) : (transProg_stmts progstmts)
  Prog_stmts2 -> []
  
transProg_stmt :: Prog_stmt -> M_stmt
transProg_stmt x = case x of
  Prog_stmt1 expr progstmt1 progstmt2 -> M_cond (transExpr expr, transProg_stmt progstmt1, transProg_stmt progstmt2)
  Prog_stmt2 expr progstmt -> M_while (transExpr expr, transProg_stmt progstmt)
  Prog_stmt3 location -> do
    let (str, exs) = transLocation location
    M_read (str, exs)
  Prog_stmt4 location expr -> do
    let (id, e) = transLocation location
    M_ass (id, e, transExpr expr)
  Prog_stmt5 expr -> M_print (transExpr expr)
  Prog_stmt6 block -> M_block (transBlock block)
  Prog_stmt7 expr caselist -> M_case (transExpr expr, transCase_list caselist)
  
transLocation :: Location -> (String,[M_expr])
transLocation x = case x of
  Location1 ident arraydimensions -> (transIdent ident, transArray_dimensions arraydimensions)
  
transCase_list :: Case_list -> [(String,[String],M_stmt)]
transCase_list x = case x of
  Case_list1 case_ morecase -> (transCase case_) : (transMore_case morecase)
  
transMore_case :: More_case -> [(String,[String],M_stmt)]
transMore_case x = case x of
  More_case1 case_ morecase -> (transCase case_) : (transMore_case morecase)
  More_case2 -> []
  
transCase :: Case -> (String,[String],M_stmt)
transCase x = case x of
  Case1 cid varlist progstmt -> (transCID cid, transVar_list varlist, transProg_stmt progstmt)
  
transVar_list :: Var_list -> [String]
transVar_list x = case x of
  Var_list1 varlist -> transVar_list varlist
  Var_list2 -> []
  Var_list11 ident morevarlist -> (transIdent ident) : (transMore_var_list morevarlist)
  
transMore_var_list :: More_var_list -> [String]
transMore_var_list x = case x of
  More_var_list1 ident morevarlist -> (transIdent ident) : (transMore_var_list morevarlist)
  More_var_list2 -> []
  
transExpr :: Expr -> M_expr
transExpr x = case x of
  Expr1 expr bintterm -> M_app (M_or, (transExpr expr) : [transBint_term bintterm])
  ExprBint_term bintterm -> transBint_term bintterm
  
transBint_term :: Bint_term -> M_expr
transBint_term x = case x of
  Bint_term1 bintterm bintfactor -> M_app (M_and, (transBint_term bintterm) : [transBint_factor bintfactor])
  Bint_termBint_factor bintfactor -> transBint_factor bintfactor
  
transBint_factor :: Bint_factor -> M_expr
transBint_factor x = case x of
  Bint_factor1 bintfactor -> M_app (M_not, [transBint_factor bintfactor])
  Bint_factor2 intexpr1 compareop intexpr2 -> M_app (transCompare_op compareop, (transInt_expr intexpr1) : [transInt_expr intexpr2])
  Bint_factorInt_expr intexpr -> transInt_expr intexpr
  
transCompare_op :: Compare_op -> M_operation
transCompare_op x = case x of
  Compare_op1 -> M_eq
  Compare_op2 -> M_lt
  Compare_op3 -> M_gt
  Compare_op4 -> M_le
  Compare_op5 -> M_ge
  
transInt_expr :: Int_expr -> M_expr
transInt_expr x = case x of
  Int_expr1 intexpr addop intterm -> M_app (transAddop addop, (transInt_expr intexpr) : [transInt_term intterm])
  Int_exprInt_term intterm -> transInt_term intterm
  
transAddop :: Addop -> M_operation
transAddop x = case x of
  Addop1 -> M_add
  Addop2 -> M_sub
  
transInt_term :: Int_term -> M_expr
transInt_term x = case x of
  Int_term1 intterm mulop intfactor -> M_app (transMulop mulop, (transInt_term intterm) : [transInt_factor intfactor])
  Int_termInt_factor intfactor -> transInt_factor intfactor
  
transMulop :: Mulop -> M_operation
transMulop x = case x of
  Mulop1 -> M_mul
  Mulop2 -> M_div
  
transInt_factor :: Int_factor -> M_expr
transInt_factor x = case x of
  Int_factor1 expr -> transExpr expr
  Int_factor2 ident basicarraydimensions -> M_size (transIdent ident, transBasic_array_dimensions basicarraydimensions)
  Int_factor3 expr -> M_app (M_float, [transExpr expr])
  Int_factor4 expr -> M_app (M_floor, [transExpr expr])
  Int_factor5 expr -> M_app (M_ceil, [transExpr expr])
  Int_factor6 ident modifierlist -> case modifierlist of  
    Modifier_listFun_argument_list a -> M_app (M_fn (transIdent ident), transModifier_list modifierlist)
    Modifier_listArray_dimensions a -> M_id (transIdent ident, transModifier_list modifierlist)
  Int_factor7 cid consargumentlist -> M_app (M_cid (transCID cid), (transCons_argument_list consargumentlist))
  Int_factorIVAL ival -> M_ival (transIVAL ival)
  Int_factorRVAL rval -> M_rval (transRVAL rval)
  Int_factorBVAL bval -> M_bval (transBVAL bval)
  Int_factorCVAL cval -> M_cval (transCVAL cval)
  Int_factor8 intfactor -> transInt_factor intfactor
  
transModifier_list :: Modifier_list -> [M_expr]
transModifier_list x = case x of
  Modifier_listFun_argument_list funargumentlist -> transFun_argument_list funargumentlist
  Modifier_listArray_dimensions arraydimensions -> transArray_dimensions arraydimensions
  
transFun_argument_list :: Fun_argument_list -> [M_expr]
transFun_argument_list x = case x of
  Fun_argument_list1 arguments -> transArguments arguments
  
transCons_argument_list :: Cons_argument_list -> [M_expr]
transCons_argument_list x = case x of
  Cons_argument_listFun_argument_list funargumentlist -> transFun_argument_list funargumentlist
  Cons_argument_list1 -> []
  
transArguments :: Arguments -> [M_expr]
transArguments x = case x of
  Arguments1 expr morearguments -> (transExpr expr) : (transMore_arguments morearguments)
  Arguments2 -> []
  
transMore_arguments :: More_arguments -> [M_expr]
transMore_arguments x = case x of
  More_arguments1 expr morearguments -> (transExpr expr) : (transMore_arguments morearguments)
  More_arguments2 -> []

