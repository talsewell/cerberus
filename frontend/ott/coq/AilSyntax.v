(* generated by Ott 0.21.2 from: AilSyntax_.ott *)

Require Import Arith.
Require Import Bool.
Require Import List.

Require Import Common.
Require Import AilTypes.
Require Import Context.

Open Scope type.

Definition identifier := nat.
Definition eq_identifier : identifier -> identifier -> bool := eq_nat.

Inductive integerSuffix : Set := 
 | U : integerSuffix
 | UL : integerSuffix
 | ULL : integerSuffix
 | L : integerSuffix
 | LL : integerSuffix.

Definition eq_integerSuffix s1 s2 : bool :=
  match s1, s2 with
  | U  , U   => true
  | UL , UL  => true
  | ULL, ULL => true
  | L  , L   => true
  | LL , LL  => true
  | _  , _   => false
  end.

Definition integerConstant : Set := nat * option integerSuffix.

Definition eq_integerConstant := eq_pair eq_nat (eq_option eq_integerSuffix).

Inductive arithmeticOperator : Set :=  (*r 6.5.5 Multiplicative operators *)
 | Mul : arithmeticOperator
 | Div : arithmeticOperator
 | Mod : arithmeticOperator (*r 6.5.6 Additive operators *)
 | Add : arithmeticOperator
 | Sub : arithmeticOperator (*r 6.5.7 Bitwise shift operators *)
 | Shl : arithmeticOperator
 | Shr : arithmeticOperator (*r 6.5.10 Bitwise AND operator *)
 | Band : arithmeticOperator (*r 6.5.11 Bitwise exclusive OR operator *)
 | Bor : arithmeticOperator (*r 6.5.12 Bitwise inclusive OR operator *)
 | Xor : arithmeticOperator (*r Binary operators from 6.5.5-14, 6.5.17 *).

Definition eq_arithmeticOperator a1 a2 :=
  match a1, a2 with
  | Mul , Mul
  | Div , Div
  | Mod , Mod
  | Add , Add
  | Sub , Sub
  | Shl , Shl
  | Shr , Shr
  | Band, Band
  | Bor , Bor
  | Xor , Xor => true
  | _   , _   => false
  end.

Inductive constant : Set := 
 | ConstantInteger (ic:integerConstant).

Definition eq_constant c1 c2 :=
  match c1, c2 with
  | ConstantInteger ic1, ConstantInteger ic2 => eq_integerConstant ic1 ic2
  end.

Inductive unaryOperator : Set := 
 | Plus : unaryOperator
 | Minus : unaryOperator
 | Bnot : unaryOperator
 | Address : unaryOperator
 | Indirection : unaryOperator
 | PostfixIncr : unaryOperator (*r Note: Appears prefix in concrete syntax. *)
 | PostfixDecr : unaryOperator (*r Note: Appears prefix in concrete syntax. *).

Definition eq_unaryOperator u1 u2 :=
  match u1, u2 with
  | Plus       , Plus
  | Minus      , Minus
  | Bnot       , Bnot
  | Address    , Address
  | Indirection, Indirection
  | PostfixIncr, PostfixIncr
  | PostfixDecr, PostfixDecr => true
  | _          , _           => false
  end.

Inductive binaryOperator : Set :=  (*r Group of operators also used for assigments *)
 | Arithmetic (aop:arithmeticOperator) (*r 6.5.17 Comma operator *)
 | Comma : binaryOperator (*r 6.5.13 Logical AND operator *)
 | And : binaryOperator (*r 6.5.14 Logical OR operator *)
 | Or : binaryOperator (*r 6.5.8 Relational operators *)
 | Lt : binaryOperator
 | Gt : binaryOperator
 | Le : binaryOperator
 | Ge : binaryOperator (*r 6.5.9 Equality operators *)
 | Eq : binaryOperator
 | Ne : binaryOperator.

Definition eq_binaryOperator b1 b2 :=
  match b1, b2 with
  | Arithmetic a1, Arithmetic a2 => eq_arithmeticOperator a1 a2
  | Comma, Comma
  | And  , And
  | Or   , Or
  | Lt   , Lt
  | Gt   , Gt
  | Le   , Le
  | Ge   , Ge
  | Eq   , Eq
  | Ne   , Ne    => true
  | _    , _     => false
  end.

Inductive expression' {A : Set} : Set := 
  | Unary (uop:unaryOperator) (e:expression)
  | Binary (e1:expression) (bop:binaryOperator) (e2:expression)
  | Assign (e1:expression) (e2:expression)
  | CompoundAssign (e1:expression) (aop:arithmeticOperator) (e2:expression)
  | Conditional (e1:expression) (e2:expression) (e3:expression)
  | Cast (q:qualifiers) (t:ctype) (e:expression)
  | Call (e:expression) (es:list expression)
  | Constant (c:constant)
  | Var (v:identifier)
  | SizeOf (q:qualifiers) (t:ctype)
  | AlignOf (q:qualifiers) (t:ctype)
with expression {A : Set} : Set :=
  | AnnotatedExpression (a:A) (e:expression').
Arguments expression  : default implicits.
Arguments expression' : default implicits.

Definition eq_arguments_aux {A : Set} (eq_A : A -> A -> bool) eq_expression :=
  fix eq_arguments (a1 a2 : list (expression A)) : bool :=
    match a1, a2 with
    | nil     , nil      => true
    | e1 :: a1, e2 :: a2 => eq_expression eq_A e1 e2 && eq_arguments a1 a2
    | _       , _        => false
    end.
Arguments eq_arguments_aux : default implicits.

Fixpoint eq_expression' {A} eq_A (e1 e2 : expression' A) {struct e1} : bool :=
  let eq_arguments := eq_arguments_aux eq_A eq_expression in
  match e1, e2 with
  | Unary uop1 e1, Unary uop2 e2 =>
      eq_unaryOperator uop1 uop2 &&
      eq_expression eq_A e1 e2
  | Binary e1_1 bop1 e2_1, Binary e1_2 bop2 e2_2 =>
      eq_expression eq_A e1_1 e1_2 &&
      eq_binaryOperator bop1 bop2 &&
      eq_expression eq_A e2_1 e2_2
  | Assign e1_1 e2_1, Assign e1_2 e2_2 =>
      eq_expression eq_A e1_1 e1_2 &&
      eq_expression eq_A e2_1 e2_2
  | CompoundAssign e1_1 aop1 e2_1, CompoundAssign e1_2 aop2 e2_2 =>
      eq_expression eq_A e1_1 e1_2 &&
      eq_arithmeticOperator aop1 aop2 &&
      eq_expression eq_A e2_1 e2_2
  | Conditional e1_1 e2_1 e3_1, Conditional e1_2 e2_2 e3_2 =>
      eq_expression eq_A e1_1 e1_2 &&
      eq_expression eq_A e2_1 e2_2 &&
      eq_expression eq_A e3_1 e3_2
  | Cast q1 t1 e1, Cast q2 t2 e2 =>
      eq_qualifiers q1 q2 &&
      eq_ctype t1 t2 &&
      eq_expression eq_A e1 e2
  | Call e1 es1, Call e2 es2 =>
      eq_expression eq_A e1 e2 &&
      eq_arguments es1 es2
  | Constant c1, Constant c2 =>
      eq_constant c1 c2
  | Var v1, Var v2 =>
      eq_identifier v1 v2
  | SizeOf q1 t1, SizeOf q2 t2 =>
      eq_qualifiers q1 q2 &&
      eq_ctype t1 t2
  | AlignOf q1 t1, AlignOf q2 t2 =>
      eq_qualifiers q1 q2 &&
      eq_ctype t1 t2
  | _, _ => false
  end
with eq_expression {A} eq_A (e1 e2 : expression A) {struct e1} : bool :=
  match e1, e2 with
  | AnnotatedExpression a1 e1, AnnotatedExpression a2 e2 => eq_A a1 a2 && eq_expression' eq_A e1 e2
  end.

Definition eq_arguments {A} eq_A (a1 a2 : list (expression A)) :=
  eq_arguments_aux eq_A eq_expression a1 a2.

Definition equiv_arguments_aux {A1 A2 : Set} equiv_expression :=
  fix equiv_arguments (a1 : list (expression A1)) (a2 : list (expression A2)) : bool :=
    match a1, a2 with
    | nil     , nil      => true
    | e1 :: a1, e2 :: a2 => equiv_expression e1 e2 && equiv_arguments a1 a2
    | _       , _        => false
    end.
Arguments equiv_arguments_aux : default implicits.

Fixpoint equiv_expression' {A1 A2 : Set} (e1 : expression' A1) (e2 : expression' A2) {struct e1} : bool :=
  let equiv_arguments := equiv_arguments_aux equiv_expression in
  match e1, e2 with
  | Unary uop1 e1, Unary uop2 e2 =>
      eq_unaryOperator uop1 uop2 &&
      equiv_expression e1 e2
  | Binary e1_1 bop1 e2_1, Binary e1_2 bop2 e2_2 =>
      equiv_expression e1_1 e1_2 &&
      eq_binaryOperator bop1 bop2 &&
      equiv_expression e2_1 e2_2
  | Assign e1_1 e2_1, Assign e1_2 e2_2 =>
      equiv_expression e1_1 e1_2 &&
      equiv_expression e2_1 e2_2
  | CompoundAssign e1_1 aop1 e2_1, CompoundAssign e1_2 aop2 e2_2 =>
      equiv_expression e1_1 e1_2 &&
      eq_arithmeticOperator aop1 aop2 &&
      equiv_expression e2_1 e2_2
  | Conditional e1_1 e2_1 e3_1, Conditional e1_2 e2_2 e3_2 =>
      equiv_expression e1_1 e1_2 &&
      equiv_expression e2_1 e2_2 &&
      equiv_expression e3_1 e3_2
  | Cast q1 t1 e1, Cast q2 t2 e2 =>
      eq_qualifiers q1 q2 &&
      eq_ctype t1 t2 &&
      equiv_expression e1 e2
  | Call e1 es1, Call e2 es2 =>
      equiv_expression e1 e2 &&
      equiv_arguments es1 es2
  | Constant c1, Constant c2 =>
      eq_constant c1 c2
  | Var v1, Var v2 =>
      eq_identifier v1 v2
  | SizeOf q1 t1, SizeOf q2 t2 =>
      eq_qualifiers q1 q2 &&
      eq_ctype t1 t2
  | AlignOf q1 t1, AlignOf q2 t2 =>
      eq_qualifiers q1 q2 &&
      eq_ctype t1 t2
  | _, _ => false
  end
with equiv_expression {A1 A2 : Set} (e1 : expression A1) (e2 : expression A2) {struct e1} : bool :=
  match e1, e2 with
  | AnnotatedExpression _ e1, AnnotatedExpression _ e2 => equiv_expression' e1 e2
  end.

Definition equiv_arguments {A1 A2 : Set} (a1 : list (expression A1)) (a2 : list (expression A2)) :=
  equiv_arguments_aux equiv_expression a1 a2.

Definition bindings : Set := list (identifier * (qualifiers * ctype)).

Definition eq_bindings : bindings -> bindings -> bool :=
  eq_list (eq_pair eq_identifier (eq_pair eq_qualifiers eq_ctype)).
 
Inductive statement' {A B : Set} : Set := 
 | Skip
 | Expression (e:expression B)
 | Block (b:bindings) (ss:list statement)
 | If (e:expression B) (s1:statement) (s2:statement)
 | While (e:expression B) (s:statement)
 | Do (s:statement) (e:expression B)
 | Break
 | Continue
 | ReturnVoid
 | Return (e:expression B)
 | Switch (e:expression B) (s:statement)
 | Case (ic:integerConstant) (s:statement)
 | Default (s:statement)
 | Label (v:identifier) (s:statement)
 | Goto (v:identifier)
 | Declaration (d:list (identifier * expression B))
with statement {A B : Set} : Set :=
 | AnnotatedStatement (a:A) (s:statement').
Arguments statement  : default implicits.
Arguments statement' : default implicits.

Definition eq_definition {A : Set} eq_A (d1 d2 : identifier * expression A) : bool :=
  eq_pair eq_identifier (eq_expression eq_A) d1 d2.

Definition eq_declaration {A : Set} eq_A (ds1 ds2 : list (identifier * expression A)) : bool :=
  eq_list (eq_definition eq_A) ds1 ds2.

Definition equiv_definition {A1 A2 : Set} (d1 : identifier * expression A1) (d2 : identifier * expression A2) : bool :=
  equiv_pair eq_identifier equiv_expression d1 d2.

Fixpoint equiv_declaration {A1 A2 : Set} (ds1 : list (identifier * expression A1)) (ds2 : list (identifier * expression A2)) : bool :=
  match ds1, ds2 with
  | nil      , nil       => true
  | d1 :: ds1, d2 :: ds2 => equiv_definition d1 d2 && equiv_declaration ds1 ds2
  | _        , _         => false
  end.

Definition eq_block_aux {A B : Set} (eq_A : A -> A -> bool) (eq_B : B -> B -> bool) equiv_statement :=
  fix equiv_block (ss1 ss2 : list (statement A B)) : bool :=
    match ss1, ss2 with
    | nil      , nil       => true
    | s1 :: ss1, s2 :: ss2 => equiv_statement eq_A eq_B s1 s2 && equiv_block ss1 ss2
    | _        , _         => false
    end.

Fixpoint eq_statement' {A B : Set} eq_A (eq_B : B -> B -> bool) (s1 s2 : statement' A B) : bool :=
  let eq_block := eq_block_aux eq_A eq_B eq_statement in
  match s1, s2 with
  | Skip, Skip => true
  | Expression e1, Expression e2 =>
      eq_expression eq_B e1 e2
  | Block b1 ss1, Block b2 ss2 =>
      eq_bindings b1 b2 &&
      eq_block ss1 ss2
  | If e1 s1_1 s2_1, If e2 s1_2 s2_2 =>
      eq_expression eq_B e1 e2 &&
      eq_statement eq_A eq_B s1_1 s1_2 &&
      eq_statement eq_A eq_B s2_1 s2_2  
  | While e1 s1, While e2 s2 =>
      eq_expression eq_B e1 e2 &&
      eq_statement eq_A eq_B s1 s2
  | Do s1 e1, Do s2 e2 =>
      eq_expression eq_B e1 e2 &&
      eq_statement eq_A eq_B s1 s2
  | Break, Break => true
  | Continue, Continue => true
  | ReturnVoid, ReturnVoid => true
  | Return e1, Return e2 =>
      eq_expression eq_B e1 e2
  | Switch e1 s1, Switch e2 s2 =>
      eq_expression eq_B e1 e2 &&
      eq_statement eq_A eq_B s1 s2
  | Case ic1 s1, Case ic2 s2 =>
      eq_integerConstant ic1 ic2 &&
      eq_statement eq_A eq_B s1 s2
  | Default s1, Default s2 =>
      eq_statement eq_A eq_B s1 s2
  | Label v1 s1, Label v2 s2 =>
      eq_identifier v1 v2 &&
      eq_statement eq_A eq_B s1 s2
  | Goto v1, Goto v2 =>
      eq_identifier v1 v2
  | Declaration d1, Declaration d2 =>
      eq_declaration eq_B d1 d2
  | _, _ => false
  end
with eq_statement {A B : Set} eq_A eq_B (s1 s2 : statement A B) : bool :=
  match s1, s2 with
  | AnnotatedStatement a1 s1, AnnotatedStatement a2 s2 =>
      eq_A a1 a2 &&
      eq_statement' eq_A eq_B s1 s2
  end.

Definition eq_block {A B} eq_A eq_B (ss1 ss2 : list (statement A B)) := eq_block_aux eq_A eq_B eq_statement ss1 ss2.

Definition equiv_block_aux {A1 A2 B1 B2 : Set} equiv_statement :=
  fix equiv_block (ss1 : list (statement A1 B1)) (ss2 : list (statement A2 B2)) : bool :=
    match ss1, ss2 with
    | nil      , nil       => true
    | s1 :: ss1, s2 :: ss2 => equiv_statement s1 s2 && equiv_block ss1 ss2
    | _        , _         => false
    end.

Fixpoint equiv_statement' {A1 A2 B1 B2 : Set} (s1 : statement' A1 B1) (s2 : statement' A2 B2) : bool :=
  let equiv_block := equiv_block_aux equiv_statement in
  match s1, s2 with
  | Skip, Skip => true
  | Expression e1, Expression e2 =>
      equiv_expression e1 e2
  | Block b1 ss1, Block b2 ss2 =>
      eq_bindings b1 b2 &&
      equiv_block ss1 ss2
  | If e1 s1_1 s2_1, If e2 s1_2 s2_2 =>
      equiv_expression e1 e2 &&
      equiv_statement s1_1 s1_2 &&
      equiv_statement s2_1 s2_2  
  | While e1 s1, While e2 s2 =>
      equiv_expression e1 e2 &&
      equiv_statement s1 s2
  | Do s1 e1, Do s2 e2 =>
      equiv_expression e1 e2 &&
      equiv_statement s1 s2
  | Break, Break => true
  | Continue, Continue => true
  | ReturnVoid, ReturnVoid => true
  | Return e1, Return e2 =>
      equiv_expression e1 e2
  | Switch e1 s1, Switch e2 s2 =>
      equiv_expression e1 e2 &&
      equiv_statement s1 s2
  | Case ic1 s1, Case ic2 s2 =>
      eq_integerConstant ic1 ic2 &&
      equiv_statement s1 s2
  | Default s1, Default s2 =>
      equiv_statement s1 s2
  | Label v1 s1, Label v2 s2 =>
      eq_identifier v1 v2 &&
      equiv_statement s1 s2
  | Goto v1, Goto v2 =>
      eq_identifier v1 v2
  | Declaration d1, Declaration d2 =>
      equiv_declaration d1 d2
  | _, _ => false
  end
with equiv_statement {A1 A2 B1 B2 : Set} (s1 : statement A1 B1) (s2 : statement A2 B2) : bool :=
  match s1, s2 with
  | AnnotatedStatement _ s1, AnnotatedStatement _ s2 =>
      equiv_statement' s1 s2
  end.

Definition equiv_block {A1 A2 B1 B2 : Set} (ss1 : list (statement A1 B1)) (ss2 : list (statement A2 B2)) := equiv_block_aux equiv_statement ss1 ss2.

(* Currently unused.
Definition declaration : Set := identifier * option storageDuration.
*)

Definition sigma {A B : Set} : Set := context identifier ((ctype * bindings) * statement A B).
Arguments sigma  : default implicits.

Definition eq_sigma {A B : Set} (eq_A : A -> A -> bool) (eq_B : B -> B -> bool) :=
  eq_context eq_identifier (eq_pair (eq_pair eq_ctype eq_bindings) (eq_statement eq_A eq_B)).

Definition equiv_sigma {A1 A2 B1 B2 : Set} (S1 : sigma A1 B1) (S2 : sigma A2 B2) :=
  equiv eq_identifier (fun _ => equiv_pair (eq_pair eq_ctype eq_bindings) equiv_statement) S1 S2.

Definition equiv_eq_sigma {A B : Set}  (eq_A : A -> A -> bool) (eq_B : B -> B -> bool) (S1 S2 : sigma A B) :=
  equiv eq_identifier (fun _ => eq_pair (eq_pair eq_ctype eq_bindings) (eq_statement eq_A eq_B)) S1 S2.

Definition gamma : Set := Context.context identifier (qualifiers * ctype).

Definition eq_gamma : gamma -> gamma -> bool :=
  eq_context eq_identifier (eq_pair eq_qualifiers eq_ctype).

Definition equiv_gamma : gamma -> gamma -> bool :=
  equiv eq_identifier (fun _ => eq_pair eq_qualifiers eq_ctype).

Definition lookup {B} (C : Context.context identifier B) := Context.lookup eq_identifier C.
Definition mem {B} v (C : Context.context identifier B) := Context.mem eq_identifier v C.
Definition fresh {B} v (C : Context.context identifier B) := Context.fresh eq_identifier v C.
Definition fresh_bindings {B} (bs : bindings) (C : Context.context identifier B) := Context.fresh_bindings eq_identifier bs C.
Definition disjoint {B1 B2} : Context.context identifier B1 -> Context.context identifier B2 -> bool := Context.disjoint eq_identifier.

Definition parameters_of_bindings : bindings -> list (qualifiers * ctype) := map snd.

Definition type_from_sigma {A B} (f : (ctype * bindings) * statement A B) :=
  Function (fst (fst f)) (parameters_of_bindings (snd (fst f))).
Arguments type_from_sigma  : default implicits.

Definition program {A B} : Set := identifier * sigma A B.
Arguments program  : default implicits.
(** induction principles *)

Definition eq_program {A B : Set} (eq_A : A -> A -> bool) (eq_B : B -> B -> bool) :=
  eq_pair eq_identifier (eq_sigma eq_A eq_B).

Definition equiv_program {A1 A2 B1 B2 : Set} (p1 : program A1 B1) (p2 : program A2 B2)  :=
  equiv_pair eq_identifier equiv_sigma p1 p2.

Definition equiv_eq_program {A B : Set} (eq_A : A -> A -> bool) (eq_B : B -> B -> bool) :=
  eq_pair eq_identifier (equiv_eq_sigma eq_A eq_B).