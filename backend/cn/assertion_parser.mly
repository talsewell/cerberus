%{
(* adapting from core_parser.mly *)
open Assertion_parser_util
%}


%token <Z.t> Z
%token <string> NAME
%token <string> MEMBER


%token TRUE
%token FALSE

%token LET
%token EQUAL
%token UNCHANGED

%token DOTDOT

%token PLUS
%token MINUS
%token STAR
%token SLASH
%token POWER
%token PERCENT

%token EQ
%token NE
%token LT
%token GT
%token LE
%token GE

%token LPAREN
%token RPAREN
%token LBRACKET
%token RBRACKET
%token LBRACE
%token RBRACE
%token COMMA
%token SEMICOLON

%token QUESTION
%token COLON
%token OR
%token AND
%token NOT

%token NULL
%token OFFSETOF
%token POINTERCAST
%token INTEGERCAST
%token POINTER
%token INTEGER
%token DISJOINT

%token CELLPOINTER


%token FLIPBIT

%token AMPERSAND
%token AT

%token EACH

%token WHERE
%token WITH
%token TYP
%token TYPEOF


%token EOF

/* %left EQ NE GT LT GE LE */
%left AND
%left PLUS MINUS
%left STAR SLASH PERCENT
/* %nonassoc POWER */
/* %nonassoc POINTERCAST */
%nonassoc MEMBER /* PREDARG */

%type <Ast.term>term
%type <Ast.condition>cond
%type <Ast.condition>start
%type <Z.t>integer

%start start integer

%%


start:
  | cond=cond EOF
      { cond }




%inline pred_with_args:
  | id=NAME LPAREN args=separated_list(COMMA, term) RPAREN
      { (id, args) }


integer:
  | MINUS z=Z
      { Z.neg z }
  | z=Z
      { z }
  | LPAREN z=integer RPAREN
      { z }


atomic_term:
  | LPAREN t= term RPAREN
      { t }
  | TRUE
      { Ast.Bool true }
  | FALSE
      { Ast.Bool false }
  | z=Z
      { Ast.Integer z }
  | a1=atomic_term member=MEMBER
/* taking the location-handling aspect from c_parser.mly */
      { Ast.Member (a1, Id.parse (Location_ocaml.(region ($startpos, $endpos) (PointCursor $startpos(member)))) member) }
  | pred=NAME DOTDOT oarg=NAME
    { Ast. PredOutput (pred, oarg) }
  | AMPERSAND id=NAME
      { Ast.Addr id }
  | v=NAME
      { Ast.Var v }
  | STAR p=atomic_term
      { Ast.Pointee p }
  | NULL
      { Ast.Null }
  | OFFSETOF LPAREN tag = NAME COMMA member= NAME RPAREN
      { Ast.OffsetOf {tag; member} }
  | CELLPOINTER LPAREN t1=term COMMA t2=term COMMA t3=term COMMA t4=term COMMA t5=term RPAREN
      { Ast.CellPointer ((t1, t2), (t3, t4), t5) }
  | LBRACE a=term RBRACE AT l=NAME
      { Ast.Env (a, l) }
  | DISJOINT LPAREN p1=term COMMA sz1=term COMMA p2=term COMMA sz2=term RPAREN
      { Ast.Disjoint ((p1, sz1), (p2, sz2)) }

arith_term:
  | a1=arith_or_atomic_term PLUS a2=arith_or_atomic_term
      { Ast.Addition (a1, a2) }
  | a1=arith_or_atomic_term MINUS a2=arith_or_atomic_term
      { Ast.Subtraction (a1, a2) } 
  | a1=arith_or_atomic_term STAR a2=arith_or_atomic_term
      { Ast.Multiplication (a1, a2) }
  | a1=arith_or_atomic_term SLASH a2=arith_or_atomic_term
      { Ast.Division (a1, a2) }
  | a1=arith_or_atomic_term PERCENT a2=arith_or_atomic_term
      { Ast.Remainder (a1, a2) }
  | POWER LPAREN a1=term COMMA a2=term RPAREN
      { Ast.Exponentiation (a1, a2) }
  | FLIPBIT LPAREN bit=term COMMA t=term RPAREN
      { Ast.FlipBit {bit; t} }

arith_or_atomic_term:
  | a=arith_term
      { a }
  | a=atomic_term
      { a }

term:
  | t=arith_or_atomic_term
      { t }
  | a1=arith_or_atomic_term EQ a2=arith_or_atomic_term
      { Ast.Equality (a1, a2) }
  | a1=arith_or_atomic_term NE a2=arith_or_atomic_term
      { Ast.Inequality (a1, a2) }
  | a1=arith_or_atomic_term LT a2=arith_or_atomic_term
      { Ast.LessThan (a1, a2) }
  | a1=arith_or_atomic_term GT a2=arith_or_atomic_term
      { Ast.GreaterThan (a1, a2) }
  | a1=arith_or_atomic_term LE a2=arith_or_atomic_term
      { Ast.LessOrEqual (a1, a2) }
  | a1=arith_or_atomic_term GE a2=arith_or_atomic_term
      { Ast.GreaterOrEqual (a1, a2) }
  | a1=atomic_term QUESTION a2=atomic_term COLON a3=atomic_term
      { Ast.ITE (a1, a2, a3) }
  | a1=atomic_term OR a2=atomic_term
      { Ast.Or (a1, a2) }
  | a1=term AND a2=term
      { Ast.And (a1, a2) }
  | NOT LPAREN t=term RPAREN
      { Ast.Not t }
  | POINTERCAST a1=atomic_term
      { Ast.IntegerToPointerCast a1 }
  | INTEGERCAST a1=atomic_term
      { Ast.PointerToIntegerCast a1 }
  | a1=atomic_term LBRACKET a2=term RBRACKET
      { Ast.App (a1, a2) } 


term_with_name:
  | name=NAME EQUAL t=term
      { (name,t) }



basetype:
  | POINTER
      { BaseTypes.Loc }
  | INTEGER
      { BaseTypes.Integer }
  

%inline ctype:
  | TYPEOF LPAREN t=term RPAREN
      { Ast.Typeof t }

%inline with_clause:
  | WITH TYP EQUAL typ=ctype
      { typ }

%inline where_clause:
  | COMMA WHERE some_oargs=separated_list(COMMA, term_with_name)
      { some_oargs }





predicate:
  | predwithargs=pred_with_args oname=option(NAME) maybe_typ=option(with_clause) maybe_some_oargs=option(where_clause)
      { let (predicate, arguments) = predwithargs in
        let some_oargs = Option.value [] maybe_some_oargs in
        Ast.{oq = None; predicate; arguments; some_oargs; oname = oname; typ = maybe_typ} }
  | EACH LPAREN bt=basetype qname=NAME SEMICOLON t=term RPAREN LBRACE predwithargs=pred_with_args maybe_typ=option(with_clause) RBRACE oname=option(NAME) maybe_some_oargs=option(where_clause)
      { let (predicate, arguments) = predwithargs in
        let some_oargs = Option.value [] maybe_some_oargs in
        Ast.{oq = Some (qname,bt,t); predicate; arguments; some_oargs; oname = oname; typ = maybe_typ} }



cond:
  | c=term
      { Ast.Term c } 
  | c=predicate
      { Ast.Predicate c }
  | LET id=NAME EQUAL t=term
      { Ast.Define (id, t) }
  | LBRACE t=term RBRACE UNCHANGED
      { Ast.Unchanged t }

