(* adapting from core_parser_util *)

type token =
  | Z of Z.t
  | NAME of string

  | TRUE
  | FALSE

  | LET
  | EQUAL
  | UNCHANGED

  | PLUS
  | MINUS
  | STAR
  | SLASH
  | POWER
  | PERCENT

  | FLIPBIT

  | EQ
  | NE
  | LT
  | GT
  | LE
  | GE

  | LPAREN
  | RPAREN
  | LBRACKET
  | RBRACKET
  | LBRACE
  | RBRACE
  | COMMA
  | SEMICOLON

  | QUESTION
  | COLON
  | OR
  | AND
  | NOT

  | NULL
  | OFFSETOF

  | CELLPOINTER
  | DISJOINT

  | MEMBER of string
  | DOTDOT

  | POINTERCAST
  | INTEGERCAST
  | POINTER
  | INTEGER

  | AMPERSAND
  | AT

  | EACH

  | WHERE
  | WITH
  | TYP
  | TYPEOF

  | EOF
