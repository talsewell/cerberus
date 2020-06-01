open Subst

module RT = ReturnTypes
module BT = BaseTypes
module LS = LogicalSorts
module RE = Resources
module LC = LogicalConstraints

type t = 
  | Return of ReturnTypes.t
  | Computational of Sym.t * BT.t * t
  | Logical of Sym.t * LS.t * t
  | Resource of RE.t * t
  | Constraint of LC.t * t



let mcomputational name bound t = 
  Computational (name,bound,t)
let mlogical name bound t = 
  Logical (name,bound,t)
let mconstraint bound t = 
  Constraint (bound,t)
let mresource bound t = 
  Resource (bound,t)


let rec args_and_ret = function
  | Return rt -> 
     (RT.I,rt)
  | Computational (name,bound,t) ->
     let (args_rt, ret) = args_and_ret t in
     (RT.Computational (name,bound,args_rt), ret)
  | Logical (name,bound,t) ->
     let (args_rt, ret) = args_and_ret t in
     (RT.Logical (name,bound,args_rt), ret)
  | Resource (bound,t) ->
     let (args_rt, ret) = args_and_ret t in
     (RT.Resource (bound,args_rt), ret)
  | Constraint (bound,t) ->
     let (args_rt, ret) = args_and_ret t in
     (RT.Constraint (bound,args_rt), ret)


let rec subst_var substitution = function
  | Return t -> Return (ReturnTypes.subst_var substitution t)
  | Computational (name,bt,t) -> 
     if name = substitution.substitute then 
       Computational (name,bt,t) 
     else if name <> substitution.swith then
       let bt' = BT.subst_var substitution bt in
       let t' = subst_var substitution t in
       Computational (name,bt',t')
     else
       let newname = Sym.fresh () in
       let substitution2 = {substitute=name; swith=newname} in
       let bt' = BT.subst_var substitution (BT.subst_var substitution2 bt) in
       let t' = subst_var substitution (subst_var substitution2 t) in
       Computational (newname,bt',t')
  | Logical (name,ls,t) -> 
     if name = substitution.substitute then 
       Logical (name,ls,t) 
     else if name <> substitution.swith then
       let ls' = LS.subst_var substitution ls in
       let t' = subst_var substitution t in
       Logical (name,ls',t')
     else
       let newname = Sym.fresh () in
       let substitution2 = {substitute=name; swith=newname} in
       let ls' = LS.subst_var substitution (LS.subst_var substitution2 ls) in
       let t' = subst_var substitution (subst_var substitution2 t) in
       Logical (newname,ls',t')
  | Resource (re,t) -> 
     let re = RE.subst_var substitution re in
     let t = subst_var substitution t in
     Resource (re,t)
  | Constraint (lc,t) -> 
     let lc = LC.subst_var substitution lc in
     let t = subst_var substitution t in
     Constraint (lc,t)


let rec pp = 
  let open Pp in
  function
  | Return t -> 
     space ^^ space ^^ space ^^ ReturnTypes.pp t
  | Computational (name,bt,t) ->
     utf8string "Π" ^^ typ (Sym.pp name) (BT.pp false bt) ^^ dot ^^^ pp t
  | Logical (name,ls,t) ->
     utf8string "∀" ^^ typ (Sym.pp name) (LS.pp false ls) ^^ dot ^^^ pp t
  | Resource (re,t) ->
     RE.pp false re ^^^ !^"*" ^^^ pp t
  | Constraint (lc,t) ->
     LC.pp false lc ^^^ !^"∧" ^^^ pp t



