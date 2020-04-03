(* NOTE: this is work in progress *)
open Core_rewriter
open Core


(* TODO: move this to Core_aux *)
let rec match_pattern_pexpr (Pattern (annots_pat, pat_) as pat) (Pexpr (annots_pe, bTy, pexpr_) as pexpr)
  : [ `MATCHED of (pattern * pexpr) option * (Symbol.sym * [ `VAL of value | `SYM of Symbol.sym ]) list | `MISMATCHED ] =
  let wrap_pat z = Pattern (annots_pat, z) in
  let wrap_pexpr z = Pexpr (annots_pe, bTy, z) in
  match pat_, pexpr_ with
    |  CaseBase (None, _), _ ->
        `MATCHED (Some (pat, pexpr), [])
    | _, PEval cval ->
        begin match Core_aux.match_pattern pat cval with
          | None ->
              `MISMATCHED
          | Some xs ->
              `MATCHED (None, List.map (fun (sym, cval) -> (sym, `VAL cval)) xs)
        end
    | CaseBase (Some sym, _), PEsym sym' ->
        `MATCHED (None, [(sym, `SYM sym')])


    | CaseBase _, _
    | CaseCtor _, PEcfunction _
    | CaseCtor _, PEsym _ ->
        `MATCHED (Some (pat, pexpr), [])
    
    | CaseCtor (Cspecified, [pat']), PEctor (Cspecified, [pe']) ->
        begin match match_pattern_pexpr pat' pe' with
          | `MISMATCHED ->
              `MISMATCHED
          | `MATCHED (None, xs) ->
              `MATCHED (None, xs)
          | `MATCHED (Some (pat'', pe''), xs) ->
              `MATCHED (Some (wrap_pat (CaseCtor (Cspecified, [pat''])), wrap_pexpr (PEctor (Cspecified, [pe'']))), xs)
        end

(*

Vloaded (LVspecified oval)) ->
        match_pattern pat' (Vobject oval)
    | (CaseCtor Cunspecified [pat'], Vloaded (LVunspecified ty)) ->
        match_pattern pat' (Vctype ty)
*)
    | CaseCtor (Ctuple, pats), PEctor (Ctuple, pes) ->
        let xs =
          List.fold_left2 (fun acc pat pe ->
            match match_pattern_pexpr pat pe, acc with
              | `MISMATCHED, _
              | _, `MISMATCHED ->
                  `MISMATCHED
              | `MATCHED (None, xs), `MATCHED (pats_pes', acc_) ->
                  `MATCHED (pats_pes', xs @ acc_)
              | `MATCHED (Some (pat', pe'), xs), `MATCHED (None, acc_) ->
                  `MATCHED (Some ([pat'], [pe']), xs @ acc_)
              | `MATCHED (Some (pat', pe'), xs), `MATCHED (Some (pats', pes'), acc_) ->
                  `MATCHED  (Some (pat' :: pats', pe' :: pes'), xs @ acc_)
          ) (`MATCHED (Some ([], []), [])) (List.rev pats) (List.rev pes) in
        begin match xs with
          | `MISMATCHED ->
              `MISMATCHED
          | `MATCHED ( (None, xs) | Some ([], []), xs ) ->
              `MATCHED (None, xs)
          | `MATCHED (Some ([pat'], [pe']), xs) ->
              `MATCHED (Some (pat', pe'), xs)
          | `MATCHED (Some (pats', pes'), xs) ->
              assert (List.length pats' = List.length pes');
              `MATCHED (Some (wrap_pat (CaseCtor (Ctuple, pats')), wrap_pexpr (PEctor (Ctuple, pes'))), xs)
        end
    | _ ->
        print_endline "\n===========================================";
        PPrint.ToChannel.pretty 1.0 80 Stdlib.stdout (Pp_core.Basic.pp_pexpr (Pexpr ([], bTy, PElet (pat, pexpr, pexpr))));
        print_endline "\n===========================================";
        print_endline "BOOM";
        `MISMATCHED


let rec match_pattern_expr (Pattern (annots_pat, pat_) as pat) (Expr (annots_e, expr_) as expr)
   : [ `MATCHED of (pattern * 'a expr) option * (Symbol.sym * [ `VAL of value | `SYM of Symbol.sym ]) list | `MISMATCHED ] =
  let wrap_pat z = Pattern (annots_pat, z) in
  let wrap_expr z = Expr (annots_e, z) in
  match pat_, expr_ with
    |  CaseBase (None, _), _ ->
        `MATCHED (Some (pat, expr), [])
    | _, Epure pe ->
        begin match match_pattern_pexpr pat pe with
          | `MISMATCHED ->
              `MISMATCHED
          | `MATCHED (None, xs) ->
              `MATCHED (None, xs)
          | `MATCHED (Some (pat', pe'), xs) ->
              `MATCHED (Some (pat', wrap_expr (Epure pe')), xs)
        end
    | CaseBase (Some _, _), _ ->
        `MATCHED (Some (pat, expr), [])
    
    | CaseCtor (Ctuple, pats), Eunseq es ->
        let xs =
          List.fold_left2 (fun acc pat e ->
            match match_pattern_expr pat e, acc with
              | `MISMATCHED, _
              | _, `MISMATCHED ->
                  `MISMATCHED
              | `MATCHED (None, xs), `MATCHED (pats_pes', acc_) ->
                  `MATCHED (pats_pes', xs @ acc_)
              | `MATCHED (Some (pat', pe'), xs), `MATCHED (None, acc_) ->
                  `MATCHED (Some ([pat'], [pe']), xs @ acc_)
              | `MATCHED (Some (pat', pe'), xs), `MATCHED (Some (pats', pes'), acc_) ->
                  `MATCHED (Some (pat' :: pats', pe' :: pes'), xs @ acc_)
          ) (`MATCHED (Some ([], []), [])) (List.rev pats) (List.rev es) in
        begin match xs with
          | `MISMATCHED ->
              `MISMATCHED
          | `MATCHED ( None, xs | Some ([], []), xs ) ->
              `MATCHED (None, xs)
          | `MATCHED (Some ([pat'], [e']), xs) ->
              `MATCHED (Some (pat', e'), xs)
          | `MATCHED (Some (pats', es'), xs) ->
              assert (List.length pats' = List.length es');
              `MATCHED (Some (wrap_pat (CaseCtor (Ctuple, pats')), wrap_expr (Eunseq es')), xs)
        end
    
    | _ ->
        `MISMATCHED (* (Some (pat, expr), []) *)
(*
    | CaseBase (Some sym, _), PEval cval ->
        (None, [(sym, cval)])

    | CaseCtor (Ctuple, pats), PEctor (Ctuple, pes) ->
        let xs =
          List.fold_left2 (fun acc pat pe ->
            match match_pattern_pexpr pat pe, acc with
              | (None, xs), (pats_pes', acc_) ->
                  (pats_pes', xs @ acc_)
              | (Some (pat', pe'), xs), (None, acc_) ->
                  (Some ([pat'], [pe']), xs @ acc_)
              | (Some (pat', pe'), xs), (Some (pats', pes'), acc_) ->
                  (Some (pat' :: pats', pe' :: pes'), xs @ acc_)
          ) (Some ([], []), []) (List.rev pats) (List.rev pes) in
        begin match xs with
          | None, xs
          | Some ([], []), xs ->
              None, xs
          | Some ([pat'], [pe']), xs ->
              Some (pat', pe'), xs
          | Some (pats', pes'), xs ->
              assert (List.length pats' = List.length pes');
              Some (wrap_pat (CaseCtor (Ctuple, pats')), wrap_pexpr (PEctor (Ctuple, pes'))), xs
        end

    | _ ->
        (Some (pat, pexpr), []) (* TODO *)

*)


(* val     select_case_pexpr: forall 'a. (Symbol.sym -> value -> 'a -> 'a) -> value -> list (pattern * 'a) -> maybe 'a *)
let rec select_case_pexpr subst_sym pexpr = function
  | [] ->
      `MISMATCHED
  | (pat, e) :: pat_es' ->
      begin match match_pattern_pexpr pat pexpr with
        | `MISMATCHED ->
            (* trying the next branch *)
            select_case_pexpr subst_sym pexpr pat_es'
        | `MATCHED (z, xs) ->
(*            print_endline "TODO: this is wrong ==> multiple patterns might match"; *)
            begin match select_case_pexpr subst_sym pexpr pat_es' with
              | `MATCHED _ ->
                  (* Because the selecting expressions is not fully evaluated it might
                     look like it is (structuraly) matching more than one pattern *)
                  `MULTIPLE
              | `MISMATCHED ->
                  `MATCHED
                    ( z
                    ,  List.fold_left (fun acc (sym, cval) ->
                         subst_sym sym cval acc
                       ) e (List.rev xs) )
              | `MULTIPLE ->
                  `MULTIPLE
            end
      end


module Identity = struct
  type 'a t = 'a
  let return = fun z -> z
  let bind m f = f m
  let (>>=) = bind
  let mapM = List.map
  let foldlM f xs init =
    List.fold_left (fun acc x ->
      f x acc
    ) init xs
  
  let unwrap (x: 'a t) : 'a = x
end

module RW = Rewriter(Identity)


let subst_pexpr pat cval pe =
  match Core_aux.match_pattern pat cval with
    | None ->
        pe
    | Some xs ->
        List.fold_left (fun acc (sym, cval) ->
          Core_aux.subst_sym_pexpr sym cval acc
        ) pe xs

let subst_expr pat cval e =
  match Core_aux.match_pattern pat cval with
    | None ->
        e
    | Some xs ->
        List.fold_left (fun acc (sym, cval) ->
          Core_aux.subst_sym_expr sym cval acc
        ) e xs


let rec subst_sym_pexpr2 sym z (Pexpr (annot, bTy, pexpr_)) =
  Pexpr ( annot
        , bTy
        , match pexpr_ with
            | PEsym sym' ->
                if sym = sym' then
                  match z with
                    | `VAL cval ->
                        PEval cval
                    | `SYM sym ->
                        PEsym sym
                else
                  pexpr_
            | PEimpl _
            | PEval _
            | PEundef _ ->
                pexpr_
            | PEconstrained xs ->
                PEconstrained begin
                  List.map (fun (constrs, pe) -> (constrs, subst_sym_pexpr2 sym z pe)) xs
                end
            | PEerror (str, pe) ->
                PEerror (str, subst_sym_pexpr2 sym z pe)
            | PEctor (ctor, pes) ->
                PEctor (ctor, List.map (subst_sym_pexpr2 sym z) pes)
            | PEcase (pe, xs) ->
                PEcase ( subst_sym_pexpr2 sym z pe
                       , List.map (fun (pat, pe) ->
                           (pat, if Core_aux.in_pattern sym pat then pe else subst_sym_pexpr2 sym z pe)
                         ) xs )
            | PEarray_shift (pe1, ty, pe2) ->
                PEarray_shift (subst_sym_pexpr2 sym z pe1, ty, subst_sym_pexpr2 sym z pe2)
            | PEmember_shift (pe, tag_sym, memb_ident) ->
                PEmember_shift (subst_sym_pexpr2 sym z pe, tag_sym, memb_ident)
            | PEnot pe ->
                PEnot (subst_sym_pexpr2 sym z pe)
            | PEop (bop, pe1, pe2) ->
                PEop (bop, subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2)
            | PEstruct (tag_sym, xs) ->
                PEstruct (tag_sym, List.map (fun (ident, pe) -> (ident, subst_sym_pexpr2 sym z pe)) xs)
            | PEunion (tag_sym, ident, pe) ->
                PEunion (tag_sym, ident, subst_sym_pexpr2 sym z pe)
            | PEcfunction pe ->
                PEcfunction (subst_sym_pexpr2 sym z pe)
            | PEmemberof (tag_sym, memb_ident, pe) ->
                PEmemberof (tag_sym, memb_ident, subst_sym_pexpr2 sym z pe)
            | PEcall (nm, pes) ->
                PEcall (nm, List.map (subst_sym_pexpr2 sym z) pes)
            | PElet (pat, pe1, pe2) ->
                PElet (pat, subst_sym_pexpr2 sym z pe1, if Core_aux.in_pattern sym pat then pe2 else subst_sym_pexpr2 sym z pe2)
            | PEif (pe1, pe2, pe3) ->
                PEif (subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2, subst_sym_pexpr2 sym z pe3)
            | PEis_scalar pe ->
                PEis_scalar (subst_sym_pexpr2 sym z pe)
            | PEis_integer pe ->
                PEis_integer (subst_sym_pexpr2 sym z pe)
            | PEis_signed pe ->
                PEis_signed (subst_sym_pexpr2 sym z pe)
            | PEis_unsigned pe ->
                PEis_unsigned (subst_sym_pexpr2 sym z pe)
            | PEbmc_assume pe ->
                PEbmc_assume (subst_sym_pexpr2 sym z pe)
            | PEare_compatible (pe1, pe2) ->
                PEare_compatible (subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2) )

let rec subst_sym_expr2 sym z (Expr (annot, expr_)) =
  Expr ( annot
        , match expr_ with
            | Epure pe ->
                Epure (subst_sym_pexpr2 sym z pe)
            | Ememop (memop, pes) ->
                Ememop (memop, List.map (subst_sym_pexpr2 sym z) pes)
            | Eskip ->
                expr_
            | Elet (pat, pe1, e2) ->
                Elet ( pat
                     , subst_sym_pexpr2 sym z pe1
                     , if Core_aux.in_pattern sym pat then e2 else subst_sym_expr2 sym z e2 )
            | Eif (pe1, e2, e3) ->
                Eif ( subst_sym_pexpr2 sym z pe1
                    , subst_sym_expr2 sym z e2
                    , subst_sym_expr2 sym z e3 )
            | Ecase (pe, pat_es) ->
                Ecase ( subst_sym_pexpr2 sym z pe
                      , List.map (fun (pat, e) ->
                          (pat, if Core_aux.in_pattern sym pat then e else subst_sym_expr2 sym z e)
                        ) pat_es )
            | Eccall (annot, pe1, pe2, pes) ->
                Eccall ( annot
                       , subst_sym_pexpr2 sym z pe1
                       , subst_sym_pexpr2 sym z pe2
                       , List.map (subst_sym_pexpr2 sym z) pes )
            | Eproc (annot, nm, pes) ->
                Eproc (annot, nm, List.map (subst_sym_pexpr2 sym z) pes)
            | Eaction pact ->
                Eaction (subst_sym_paction2 sym z pact)
            | Eunseq es ->
                Eunseq (List.map (subst_sym_expr2 sym z) es)
            | Ewseq (pat, e1, e2) ->
                Ewseq ( pat
                      , subst_sym_expr2 sym z e1
                      , if Core_aux.in_pattern sym pat then e2 else subst_sym_expr2 sym z e2 )
            | Esseq (pat, e1, e2) ->
                Esseq ( pat
                      , subst_sym_expr2 sym z e1
                      , if Core_aux.in_pattern sym pat then e2 else subst_sym_expr2 sym z e2 )
            | Easeq ((sym', bTy), act1, pact2) ->
                Easeq ( (sym', bTy)
                      , subst_sym_action2 sym z act1
                      , begin
                          if sym = sym' then
                            pact2
                          else
                            subst_sym_paction2 sym z pact2
                        end )
            | Eindet (i, e) ->
                Eindet (i, subst_sym_expr2 sym z e)
            | Ebound (i, e) ->
                Ebound (i, subst_sym_expr2 sym z e)
            | Esave (lab_sym, sym_bTy_pes, e) ->
                let sym_bTy_pes' = List.map (fun (x, (bTy, pe)) ->
                  (x, (bTy, subst_sym_pexpr2 sym z pe))
                ) sym_bTy_pes in
                if List.exists (fun (z, _) -> sym = z) sym_bTy_pes then
                  (* TODO: check *)
                  Esave (lab_sym, sym_bTy_pes', e)
                else
                  Esave (lab_sym, sym_bTy_pes', subst_sym_expr2 sym z e)
            | Erun (annot, lab_sym, pes) ->
                Erun (annot, lab_sym, List.map (subst_sym_pexpr2 sym z) pes)
            | End es ->
                End (List.map (subst_sym_expr2 sym z) es)
            | Epar es ->
                Epar (List.map (subst_sym_expr2 sym z) es)
            | Ewait _ ->
                expr_ )

and subst_sym_action_2 sym z = function
  | Create (pe1, pe2, pref) ->
      Create (subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2, pref)
  | CreateReadOnly (pe1, pe2, pe3, pref) ->
      CreateReadOnly (subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2, subst_sym_pexpr2 sym z pe3, pref)
  | Alloc0 (pe1, pe2, pref) ->
      Alloc0 (subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2, pref)
  | Kill (b, pe) ->
      Kill (b, subst_sym_pexpr2 sym z pe)
  | Store0 (b, pe1, pe2, pe3, mo) ->
      Store0 (b, subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2, subst_sym_pexpr2 sym z pe3, mo)
  | Load0 (pe1, pe2, mo) ->
      Load0 (subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2, mo)
  | RMW0 (pe1, pe2, pe3, pe4, mo1, mo2) ->
      RMW0 ( subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2
           , subst_sym_pexpr2 sym z pe3, subst_sym_pexpr2 sym z pe4, mo1, mo2 )
  | Fence0 mo ->
      Fence0 mo
  | CompareExchangeStrong (pe1, pe2, pe3, pe4, mo1, mo2) ->
      CompareExchangeStrong ( subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2
                            , subst_sym_pexpr2 sym z pe3, subst_sym_pexpr2 sym z pe4, mo1, mo2 )
  | CompareExchangeWeak (pe1, pe2, pe3, pe4, mo1, mo2) ->
      CompareExchangeWeak ( subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2
                          , subst_sym_pexpr2 sym z pe3, subst_sym_pexpr2 sym z pe4, mo1, mo2 )
  | LinuxFence mo ->
      LinuxFence mo
  | LinuxStore (pe1, pe2, pe3, mo) ->
      LinuxStore ( subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2, subst_sym_pexpr2 sym z pe3, mo )
  | LinuxLoad (pe1, pe2, mo) ->
      LinuxLoad ( subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2, mo )
  | LinuxRMW (pe1, pe2, pe3, mo) ->
      LinuxRMW ( subst_sym_pexpr2 sym z pe1, subst_sym_pexpr2 sym z pe2, subst_sym_pexpr2 sym z pe3, mo )


and subst_sym_action2 sym z (Action (loc, bs, act_)) =
  Action (loc, bs, subst_sym_action_2 sym z act_)

and subst_sym_paction2 sym z (Paction (p, act)) =
  Paction (p, subst_sym_action2 sym z act)


let apply_substs_pexpr xs pe =
  List.fold_left (fun acc (sym, cval) ->
    subst_sym_pexpr2 sym cval acc
  ) pe xs


let apply_substs_expr xs e =
  List.fold_left (fun acc (sym, cval) ->
    subst_sym_expr2 sym cval acc
  ) e xs



(* Rewriter doing partial evaluation for Core (pure) expressions *)
let core_peval file : 'bty RW.rewriter =
  let eval_pexpr pexpr =
    let emp = Pmap.empty Symbol.instance_Basic_classes_Ord_Symbol_sym_dict.compare_method in
    Core_eval.eval_pexpr Location_ocaml.unknown emp [] None file pexpr in
  
  let to_unfold_funs =
    (* The list of stdlib functions to be unfolded (see PEcall) *)
    Pmap.filter (fun _ fdecl ->
      match fdecl with
        | Fun (_, sym_bTys, _) ->
            List.exists (function (_, BTy_ctype) -> true | _ -> false) sym_bTys
        | _ ->
            false
    ) file.stdlib in
  
  let to_unfold_impls =
    (* The list of impl-def functions to be unfolded (see PEcall) *)
    Pmap.filter (fun _ fdecl ->
      match fdecl with
        | IFun (_, sym_bTys, _) ->
            List.exists (function (_, BTy_ctype) -> true | _ -> false) sym_bTys
        | _ ->
            false
    ) file.impl in
  
  let check_unfold = function
    | Sym sym ->
        begin match Pmap.lookup sym to_unfold_funs with
          | Some (Fun (_, sym_bTys, pe)) ->
              Some (sym_bTys, pe)
          | _ ->
              None
        end
    | Impl iCst ->
        begin match Pmap.lookup iCst to_unfold_impls with
          | Some (IFun (_, sym_bTys, pe)) ->
              Some (sym_bTys, pe)
          | _ ->
              None
        end in
  
  let open RW in {
    rw_pexpr=
      RW.RW begin fun (Pexpr (annots, bTy, pexpr_) as pexpr) ->
        match eval_pexpr pexpr with
          | Right (Defined cval) ->
              begin match pexpr_ with
                | PEval _ ->
                    Unchanged
                | _ ->
                    Update (Pexpr (annots, bTy, PEval cval))
              end
          | _ ->
              begin match pexpr_ with
                | PEcfunction pe ->
                    begin match eval_pexpr pexpr with
                      | Right (Defined cval) ->
                          ChangeDoChildrenPost
                            ( Identity.return (Pexpr (annots, bTy, PEval cval))
                            , Identity.return )
                      | Right (Undef (_, ubs)) ->
                          failwith (String.concat ", " (List.map Undefined.stringFromUndefined_behaviour ubs))
                      | Right (Error (_, str)) ->
                          print_endline str;
                          exit 1
                      | Left err ->
                          Traverse
(*
                        print_endline ("PEcfunction => " ^ Pp_errors.to_string err);
                          exit 1
*)
                    end
                | PElet (pat, pe1, pe2) ->
                    begin match match_pattern_pexpr pat pe1 with
                    | `MISMATCHED ->
                        assert false
                    | `MATCHED (None, xs) ->
                        (* COMPLETE_MATCH *)
                        ChangeDoChildrenPost
                          ( Identity.return (apply_substs_pexpr xs pe2)
                          , Identity.return )
(*
                    | `MATCHED (Some (_, _), []) ->
                        Unchanged
*)
                    | `MATCHED (Some (pat', pe1'), xs) ->
                        (* PARTIAL *)
                        ChangeDoChildrenPost
                          ( Identity.return (Pexpr (annots, bTy, PElet (pat', pe1', apply_substs_pexpr xs pe2)))
                          , Identity.return )
                    end
                
                | PEif (pe1, pe2, pe3) ->
                    begin match eval_pexpr pe1 with
                      | Right (Defined Vtrue) ->
                          ChangeDoChildrenPost
                            ( Identity.return pe2
                            , Identity.return )
                      | Right (Defined Vfalse) ->
                          ChangeDoChildrenPost
                            ( Identity.return pe3
                            , Identity.return )
                      | Right (Defined _) ->
                          failwith "PEif -> not Vtrue or Vfalse"
                      | Right (Undef (_, ubs)) ->
                          failwith (String.concat ", " (List.map Undefined.stringFromUndefined_behaviour ubs))
                      | Right (Error (_, str)) ->
                          print_endline str;
                          exit 1
                      | Left err ->
                          Traverse
                    end
                | PEcase (pe1, pat_pes) ->
                    begin match select_case_pexpr subst_sym_pexpr2 pe1 pat_pes with
                      | `MULTIPLE ->
                          Traverse
                      | `MISMATCHED ->
                          print_endline "\n===========================================";
                          PPrint.ToChannel.pretty 1.0 80 Stdlib.stdout (Pp_core.Basic.pp_pexpr pe1);
                          print_endline "\n===========================================";
                          failwith "PEcase mismatched"
                      | `MATCHED (None, pe') ->
                          ChangeDoChildrenPost
                            ( Identity.return pe'
                            , Identity.return )
                      | `MATCHED (Some (pat', pe1'), pe') ->
                          ChangeDoChildrenPost
                            ( Identity.return (Pexpr (annots, bTy, PEcase (pe1', [(pat', pe')])))
                            , Identity.return )
                    end
                
                | PEcall (nm, pes) ->
                    (* UNFOLD CALLS TO STDLIB and IMPL-DEF FUNCTIONS TAKING A CTYPE AS PARAMETER *)
                    begin match check_unfold nm with
                      | Some (sym_bTys, body_pe) ->
                          let pats =
                            List.map (fun (sym, bTy) ->
                              Core_aux.mk_sym_pat sym bTy
                            ) sym_bTys in
                          Update begin
                            Core_aux.mk_let_pe
                              (Core_aux.mk_tuple_pat pats)
                              (Core_aux.mk_tuple_pe pes)
                              body_pe
                          end
                      | None ->
                          Traverse
                    end
                
                | _ ->
                    Traverse
              end
      end;
    
    rw_action=
      RW.RW begin fun act ->
        Traverse
      end;
    
    rw_expr=
      RW.RW begin fun (Expr (annots, expr_) (*as expr*)) ->
        match expr_ with
          | Ebound (_, e) ->
              ChangeDoChildrenPost
                ( Identity.return e, Identity.return )
(*
          | Ewseq (_, Expr (_, Eskip), e2)
          | Esseq (_, Expr (_, Eskip), e2) ->
              Update e2


          | Eskip ->
              Update (Core_aux.(mk_pure_e (mk_value_pe Vunit)))
*)
          
          | Ewseq (pat, e1, e2)
          | Esseq (pat, e1, e2) -> (* TODO !!! *)
              begin match match_pattern_expr pat e1 with
                | `MISMATCHED ->
                    failwith (String_core.string_of_expr e1)
                | `MATCHED (None, xs) ->
                    ChangeDoChildrenPost
                      ( Identity.return (apply_substs_expr xs e2)
                      , Identity.return )
(*
                | `MATCHED (Some (_, _), []) ->
                    Unchanged
*)
                | `MATCHED (Some (pat', e1'), xs) ->
                    (* PARTIAL *)
                    ChangeDoChildrenPost
                      ( Identity.return (Expr (annots, Esseq (pat', e1', apply_substs_expr xs e2)))
                      , Identity.return )
              end
          
          | Elet (pat, pe, e) ->
              begin match match_pattern_pexpr pat pe with
                | `MISMATCHED ->
                    assert false
                | `MATCHED (None, xs) ->
                    (* COMPLETE_MATCH *)
                    ChangeDoChildrenPost
                      ( Identity.return (apply_substs_expr xs e)
                          , Identity.return )
(*
                | `MATCHED (Some (_, _), []) ->
                    Unchanged
*)
                | `MATCHED (Some (pat', pe'), xs) ->
                    (* PARTIAL *)
                    ChangeDoChildrenPost
                      ( Identity.return (Expr (annots, Elet (pat', pe', apply_substs_expr xs e)))
                      , Identity.return )
              end
          
          | Eif (pe1, e2, e3) ->
              begin match eval_pexpr pe1 with
                | Right (Defined Vtrue) ->
                    ChangeDoChildrenPost
                      ( Identity.return e2
                      , Identity.return )
                | Right (Defined Vfalse) ->
                    ChangeDoChildrenPost
                      ( Identity.return e3
                      , Identity.return )
                | Right (Defined _) ->
                    failwith "PEif -> not Vtrue or Vfalse"
                | Right (Undef (_, ubs)) ->
                    failwith (String.concat ", " (List.map Undefined.stringFromUndefined_behaviour ubs))
                | Right (Error (_, str)) ->
                    print_endline str;
                    exit 1
                | Left err ->
                    Traverse
              end
          
          | Ecase (pe, pat_es) ->
              begin match select_case_pexpr subst_sym_expr2 pe pat_es with
                | `MULTIPLE ->
                    Traverse
                | `MISMATCHED ->
                    failwith "Ecase mismatched"
                | `MATCHED (None, e') ->
                    ChangeDoChildrenPost
                      ( Identity.return e'
                      , Identity.return )
                | `MATCHED (Some (pat', pe'), e') ->
                    ChangeDoChildrenPost
                      ( Identity.return (Expr (annots, Ecase (pe', [(pat', e')])))
                      , Identity.return )
              end


(*
                ChangeDoChildrenPost
                  ( begin match Core_aux.to_pure e1 with
                      | Some pe ->
                          begin match eval_pexpr pe with
                            | Right (Defined cval) ->
                                subst_expr pat cval e2
                            | _ ->
                                Identity.return (Expr (annots, Ewseq (pat, e1, e2)))(*expr*)
                          end
                      | None ->
                          Identity.return expr
                    end
                  , Identity.return )
*)

          | _ ->
              Traverse
      end
  }



(* This does one step of partial evaluation on an expression *)
let step_peval_expr file expr =
  Identity.unwrap RW.(rewriteExpr (core_peval file) expr)

(* CURRENTLY BROKEN, this fully applies the partial evaluator on an expression *)
let steps_peval_expr file expr =
  (* HACK: this currently only tried up to 100 steps *)
  Identity.unwrap RW.(repeat (100) (rewriteExpr (core_peval file)) expr)



(*
let sym_eq =
  Symbol.instance_Basic_classes_Eq_Symbol_sym_dict.Lem_basic_classes.isEqual_method



let symbol_of_funname file str : Symbol.sym option =
  List.find_opt (fun (Symbol.Symbol (_, _, str_opt)) ->
      match str_opt with
        | Some str' when str = str' ->
            true
        | _ ->
            false
    ) (Pset.elements (Pmap.domain file.stdlib))


(*
let is_recursive_function file name_str : bool =
  match symbol_of_funname file name_str with
    | None ->
        assert false
    | Some sym ->
*)
let is_recursive_function file sym : bool =
        let xs = Pmap.union file.stdlib file.funs in
        begin match Pmap.lookup sym xs with
          | Some (Fun (_, sym_btys, pe)) ->
              let rec aux (Pexpr (_, _, pexpr_)) =
                match pexpr_ with
                  | PEsym _
                  | PEimpl _
                  | PEval _
                  | PEundef _ ->
                      false
                  | PEconstrained _ ->
                      assert false
                  | PEerror (_, pe) ->
                      aux pe
                  | PEctor (_, pes) ->
                      List.exists aux pes
                  | PEcase (pe, pat_pes) ->
                      aux pe || List.exists (fun (_, pe) -> aux pe) pat_pes
                  | PEstruct (_, xs) ->
                      aux pe || List.exists (fun (_, pe) -> aux pe) xs
                  | PEmember_shift (pe, _, _)
                  | PEnot pe
                  | PEunion (_, _, pe)
                  | PEcfunction pe
                  | PEmemberof (_, _, pe) ->
                      aux pe
                  | PEis_scalar pe
                  | PEis_integer pe
                  | PEis_signed pe
                  | PEis_unsigned pe
                  | PEbmc_assume pe ->
                      aux pe
                  | PEcall (Sym sym', pes) ->
                      sym_eq sym sym' || List.exists aux pes
                  | PEcall (Impl _, pes) ->
                      List.exists aux pes
                  | PEarray_shift (pe1, _, pe2)
                  | PEop (_, pe1, pe2)
                  | PElet (_, pe1, pe2)
                  | PEare_compatible (pe1, pe2) ->
                      aux pe1 || aux pe2
                  | PEif (pe1, pe2, pe3) ->
                      aux pe1 || aux pe2 || aux pe3 in
              aux pe
          | Some (Proc _ | ProcDecl _ | BuiltinDecl _) ->
              false
          | _ ->
              assert false
        end


let unfold_functions file (funames: string (*Symbol.sym list*)) expr : unit expr =
  let funames =
    List.find (fun (Symbol.Symbol (_, _, str_opt)) ->
      match str_opt with
        | Some str when funames = str ->
            true
        | _ ->
            false
    ) (Pset.elements (Pmap.domain file.stdlib))
  in
  let rw =
    let open RW in {
      rw_pexpr=
        RW.RW begin fun (Pexpr (annots, bty, pexpr_)) ->
(*          let wrap z = Pexpr (annots, bty, z) in *)
          match pexpr_ with
            | PEcall (Sym sym, pes) ->
                if sym_eq sym funames then
                  begin match Pmap.lookup sym file.stdlib with
                    | Some (Fun (_, _, body_pe)) ->
                      Update body_pe
                    | _ ->
                      assert false
                  end
                else
                  Traverse
            | _ ->
                Traverse
        end;
      rw_action=
        RW.RW begin fun _ ->
          Traverse
        end;
      rw_expr=
        RW.RW begin fun _ ->
          Traverse
        end
    } in
  Identity.unwrap RW.(rewriteExpr rw expr)


let boom file =
  List.iter (fun sym ->
    if is_recursive_function file sym then
      Printf.printf "%s is recursive\n" (Pp_symbol.to_string sym)
  ) (Pset.elements (Pmap.(domain (union file.stdlib file.funs))))






let foo pp (Pexpr (annots, bTy, pexpr_)) =
  match pexpr_ with
    | PElet (pat, pe1, pe2) ->
        begin match match_pattern_pexpr pat pe1 with
          | `MISMATCHED ->
              assert false
          | `MATCHED (None, xs) ->
              print_endline "COMPLETE_MATCH"
          | `MATCHED (Some (pat', pe1'), xs) ->
              let pe2' =
                List.fold_left (fun acc (sym, cval) ->
                  subst_sym_pexpr2 sym cval acc
                ) pe2 xs in
              print_endline "PARTIAL";
              pp PPrint.(!^ "==> " ^^ Pp_core.Basic.pp_pexpr (Pexpr (annots, bTy, PElet (pat', pe1', pe2'))))
        end
    | _ ->
        print_endline "NOTHING"
*)