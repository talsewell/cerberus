open Pp
module Loc=Locations
module BT=BaseTypes
module IT=IndexTerms
module LS=LogicalSorts
module CF=Cerb_frontend
module RE=Resources
module VB=VariableBinding






(* more to be added *)
type memory_state = 
  | Unowned
  | Uninit of RE.size
  | Integer of string * RE.size
  | Location of string * RE.size
  | Within of {base_location : string; resource : Sym.t}

type location_state = { location : string; state : memory_state; }
type variable_location = { name : string; location : string}

type model = 
  { memory_state : location_state list;
    variable_locations : variable_location list;
  }


let pp_variable_and_location_state ( ovar, { location; state }) =
  let var = match ovar with
    | None -> Pp.empty
    | Some v -> !^v
  in
  let value, size = match state with
    | Unowned -> Pp.empty, Pp.empty
    | Uninit size -> !^"uninitialised", Z.pp size
    | Integer (value, size) -> typ !^value !^"integer", Z.pp size
    | Location (value, size) -> typ !^value !^"pointer", Z.pp size
    | Within {base_location; _} -> 
       parens (!^"within owned region at" ^^^ !^base_location), Pp.empty
  in
  ( (R, var), (R, !^location), (R, size), (L, value) )


let pp_model model = 
  let variable_and_location_state : (string option * location_state) list = 
    List.concat_map (fun (ls : location_state) ->
        let vars = 
          List.filter (fun vl -> String.equal ls.location vl.location
            ) model.variable_locations
        in
        match vars with
        | [] -> [(None, ls)]
        | _ -> List.map (fun v -> (Some v.name, ls)) vars
      ) model.memory_state
  in
  Pp.table4 
    (("var"), ("location"), ("size") , ("value"))
    (List.map pp_variable_and_location_state variable_and_location_state)
  


type access = 
  | Load 
  | Store
  | Kill
  | Free


type sym_or_string = 
  | Sym of Sym.t
  | String of string


type type_error = 
  | Unbound_name of sym_or_string
  | Name_bound_twice of sym_or_string

  | Uninitialised of BT.member option
  | Missing_resource of Resources.t * (Loc.t list) option
  | Missing_ownership of access * BT.member option * (Loc.t list) option
  | ResourceMismatch of { has: RE.t; expect: RE.t; }
  | Unused_resource of { resource: Resources.t }
  | Misaligned of access

  | Number_arguments of {has: int; expect: int}
  | Mismatch of { has: LS.t; expect: LS.t; }
  | Illtyped_it of IndexTerms.t
  | Unsat_constraint of LogicalConstraints.t
  | Unconstrained_logical_variable of Sym.t
  | Kind_mismatch of {has: VariableBinding.kind; expect: VariableBinding.kind}

  | Undefined_behaviour of CF.Undefined.undefined_behaviour * model option
  | Unspecified of CF.Ctype.ctype
  | StaticError of string

  | Internal of Pp.document
  | Unsupported of Pp.document
  | Generic of Pp.document
  | Generic_extra of Pp.document * document


type t = type_error








let pp_type_error = function
  | Unbound_name unbound ->
     let name_pp = match unbound with
       | Sym s -> Sym.pp s
       | String str -> !^str
     in
     (!^"Unbound symbol" ^^ colon ^^^ name_pp, [])
  | Name_bound_twice name ->
     let name_pp = match name with
       | Sym s -> Sym.pp s
       | String str -> !^str
     in
     (!^"Name bound twice" ^^ colon ^^^ squotes name_pp, [])


  | Uninitialised omember ->
     begin match omember with
     | None -> 
        (!^"Trying to read uninitialised data", [])
     | Some m -> 
        (!^"Trying to read uninitialised struct member" ^^^ BT.pp_member m, [])
     end
  | Missing_resource (t, owhere) ->
     let extra = match owhere with
       | None -> []
       | Some locs -> 
          [!^"Maybe last used in the following places:" ^^^
             Pp.list (fun loc -> 
                 let (head, _pos) = Locations.head_pos_of_location loc in
                 !^head
               ) locs]
     in
     (!^"Missing resource of type" ^^^ Resources.pp t, extra)
  | Missing_ownership (access, omember, owhere) ->
     let msg = match access, omember with
     | Kill, None ->  
        !^"Missing ownership for de-allocating"
     | Kill, Some m ->  
        !^"Missing ownership for de-allocating struct member" ^^^ BT.pp_member m
     | Load, None   ->  
        !^"Missing ownership for reading"
     | Load, Some m -> 
        !^"Missing ownership for reading struct member" ^^^ BT.pp_member m
     | Store, None   -> 
        !^"Missing ownership for writing"
     | Store, Some m -> 
        !^"Missing ownership for writing struct member" ^^^ BT.pp_member m
     | Free, _ -> 
        !^"Missing ownership for free-ing"
     in
     let extra = match owhere with
       | None -> []
       | Some locs -> 
          [!^"Maybe last used in the following places:" ^^^
             Pp.list Loc.pp locs]
     in
     (msg, extra)
  | ResourceMismatch {has; expect} ->
     (!^"Need a resource" ^^^ RE.pp expect ^^^
        !^"but have resource" ^^^ RE.pp has, [])
  | Unused_resource {resource;_} ->
     (!^"Left-over unused resource" ^^^ Resources.pp resource, [])
  | Misaligned access ->
     let msg = match access with
     | Kill -> !^"Misaligned de-allocation operation"
     | Load -> !^"Misaligned read"
     | Store ->  !^"Misaligned write"
     | Free ->  !^"Misaligned free"
     in
     (msg, [])

  | Number_arguments {has;expect} ->
     (!^"Wrong number of arguments:" ^^^
        !^"expected" ^^^ !^(string_of_int expect) ^^^ comma ^^^
          !^"has" ^^^ !^(string_of_int has), [])
  | Mismatch {has; expect} ->
     (!^"Expected value of type" ^^^ LS.pp false expect ^^^
        !^"but found value of type" ^^^ LS.pp false has, [])
  | Illtyped_it it ->
     (!^"Illtyped index term" ^^ colon ^^^ (IndexTerms.pp it), [])
  | Unsat_constraint c ->
     (!^"Unsatisfied constraint" ^^^ LogicalConstraints.pp c, [])
  | Unconstrained_logical_variable name ->
     (!^"Unconstrained logical variable" ^^^ Sym.pp name, [])
  | Kind_mismatch {has; expect} ->
     (!^"Expected" ^^^ VariableBinding.kind_pp expect ^^^ 
        !^"but found" ^^^ VariableBinding.kind_pp has, [])

  | Undefined_behaviour (undef, omodel) -> 
     let ub = CF.Undefined.pretty_string_of_undefined_behaviour undef in
     let extras = match omodel with 
       | Some model -> [!^ub; pp_model model] 
       | None -> [!^ub] 
     in
     (!^"Undefined behaviour", extras)
  | Unspecified _ctype ->
     (!^"Unspecified value", [])
  | StaticError err ->
     (!^("Static error: " ^ err), [])

  | Internal err ->
     (!^"Internal error" ^^ colon ^^^ err, [])
  | Unsupported unsupported ->
     (!^"Unsupported feature" ^^ colon ^^^ unsupported, [])
  | Generic err ->
     (err, [])
  | Generic_extra (err, extra) ->
     (err, [extra])


(* stealing some logic from pp_errors *)
let type_error (loc : Loc.t) (ostacktrace : string option) (err : t) = 
  let (msg, extras) = pp_type_error err in
  let extras = match ostacktrace with
    | Some stacktrace -> extras @ [item "stacktrace" !^stacktrace]
    | None -> extras
  in
  Pp.error loc msg extras
