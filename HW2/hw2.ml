(* 1 *)
let rec make_prod_func rules symbol = match rules with
  | (s, rhs)::tl -> if s = symbol then rhs::(make_prod_func tl symbol)
      else make_prod_func tl symbol
  | _ -> []
;;

let convert_grammar gram1 = 
  (fst gram1), (make_prod_func (snd gram1))
;;

(* 2 *)
type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

let rec rec_parse_tree_leaves tree = match tree with
  | hd::tl -> (match hd with 
      | (Node (s, rhs)) -> (rec_parse_tree_leaves rhs)@(rec_parse_tree_leaves tl)
      | (Leaf s) -> s::(rec_parse_tree_leaves tl)) 
  | _ -> []
;;

let parse_tree_leaves tree = match tree with 
  | (Node (s, rhs)) -> rec_parse_tree_leaves rhs
  | (Leaf s) -> s::[] 
;;

(* 3 *)
type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal
;;

let rec match_check prod_func rules accept frag = 
  if frag = [] && rules = [] then accept frag
  else match rules with 
    | rule_hd::rule_tl -> ( 
        match rule_hd with 
        | N a -> (non_terminal_func prod_func (prod_func a) (match_check prod_func rule_tl accept) frag)
        | T b -> (
            match frag with 
            | frag_hd::frag_tl -> (
                if frag_hd = b then (match_check prod_func rule_tl accept frag_tl)
                else None 
              )
            | _ -> None
          )
      )
    | _ -> accept frag
and non_terminal_func prod_func rule_list accept frag = match rule_list with 
  | list_hd::list_tl -> (
      match (match_check prod_func list_hd accept frag) with 
      | None -> (non_terminal_func prod_func list_tl accept frag)
      | Some s -> Some s 
    )
  | _ -> None
;;

let make_matcher gram = 
  match gram with 
  | (expr, prod_func) -> ( 
      fun accept frag -> (non_terminal_func prod_func (prod_func expr) accept frag)
    )
;;

(* 4 *)
let accept_empty path frag = match frag with 
  | [] -> Some path, frag
  | _ -> None, frag 
;; 

let rec and_parse_func prod_func rules accept path frag = (* return (Some path, left)  or (None, left) *) 
  match rules with 
  | rule_hd::rule_tl -> (
      match rule_hd with 
      | N a -> ( 
          (or_parse_func prod_func a (prod_func a) (and_parse_func prod_func rule_tl accept) path frag)
        )
      | T b -> match frag with 
        | frag_hd::frag_tl -> (
            if frag_hd = b then (
              let (s2, l3) = (and_parse_func prod_func rule_tl accept path frag_tl) in 
              match s2 with 
              | None -> (None, frag)
              | Some _ -> (s2, l3)
            )
            else ( 
              (None, frag)
            )
          )
        | _ -> (None, frag) (*done frag but not done rule so fail*)
    )
  | _ -> accept path frag (*accept*)
and or_parse_func prod_func symbol rule_list accept path frag = (* return (Some path, left) or (None, left) *)
  match rule_list with 
  | list_hd::list_tl -> (
      let (s1, l) = (and_parse_func prod_func list_hd accept path frag) in 
      match s1 with 
      | None -> or_parse_func prod_func symbol list_tl accept path frag
      | Some s2 -> (Some (list_hd::s2), l)
    ) 
  | _ -> (None, frag)
;; 


let rec build_tree prod_func symbol rule_list path = (* return (tree, left) *)
  match rule_list with 
  | list_hd::list_tl -> 
      if list_hd = (List.hd path) then (
        let (branch, l1) = build_branch prod_func list_hd (List.tl path) in
        (Node (symbol, branch), l1) 
      )
      else build_tree prod_func symbol list_tl path
  | _ -> Node (symbol, []), path
and build_branch prod_func rules path = (* return (branch[], left) *)
  match rules with 
  | rule_hd::rule_tl -> (
      match rule_hd with 
      | N a ->  (
          let (tree, l1) = build_tree prod_func a (prod_func a) path in
          let (left_tree, l2) = (build_branch prod_func rule_tl l1) in
          (tree::left_tree, l2) 
        )
      | T b -> (
          let (left_tree, l1) = (build_branch prod_func rule_tl path) in
          ((Leaf b)::left_tree, l1) 
        ) 
    )
  | _ -> [], path
;; 


let make_parser gram = match gram with 
  | (expr, prod_func) -> (
      fun frag -> ( 
          let (path, left) = (or_parse_func prod_func expr (prod_func expr) accept_empty [] frag) in
          match path with 
          | Some p -> let (tree, left) = (build_tree prod_func expr (prod_func expr) p) in
              (
                Some tree
              )
          | None -> None 
        )
    )
;; 