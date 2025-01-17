open Locations
module SymSet = Set.Make(Sym)
module IT = IndexTerms

module LRT = LogicalReturnTypes

type t = Computational of (Sym.t * BaseTypes.t) * info * LRT.t

let lrt (Computational (_, _, lrt)) = lrt


let to_logical = function
  | Computational ((name, bt), info, lrt) ->
     LRT.Logical ((name, bt), info, lrt)


let mComputational (name, bound, oinfo) t = 
  Computational ((name, bound), oinfo, t)


let concat (t1: t) (t2: LRT.t) : t = 
  match t1 with
  | Computational (bound, oinfo, t1') -> 
     Computational (bound, oinfo, LRT.concat t1' t2)



let subst (substitution: IT.t Subst.t) rt = 
  match rt with
  | Computational ((name, bt), oinfo, t) -> 
     if SymSet.mem name substitution.relevant then
       let name' = Sym.fresh_same name in
       let t' = LRT.subst (IT.make_subst [(name, IT.sym_ (name', bt))]) t in
       let t'' = LRT.subst substitution t' in
       Computational ((name', bt), oinfo, t'')
     else
       Computational ((name, bt), oinfo, LRT.subst substitution t)



let pp_aux rt = 
  let open Pp in
  match rt with
  | Computational ((name, bt), oinfo, t) ->
     let op = if !unicode then utf8string "\u{03A3}" else !^"EC" in
     (op ^^^ typ (Sym.pp name) (BaseTypes.pp bt) ^^ dot) :: LRT.pp_aux t

let pp rt = 
  Pp.flow (Pp.break 1) (pp_aux rt)



let json = function
  | Computational ((s, bt), oinfo, t) ->
     let args = [
         ("symbol", Sym.json s);
         ("basetype", BaseTypes.json bt);
         ("return_type", LRT.json t);
       ]
     in
     `Variant ("Computational", Some (`Assoc args))
