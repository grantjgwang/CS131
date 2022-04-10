(* 1 *)
let rec subset a b =
    if a = [] then true
    else if List.exists (fun x -> x = (List.hd a)) b then subset (List.tl a) b
    else false;;

(* 2 *)
let equal_sets a b =
    if subset a b && subset b a then true
    else false;;

(* 3 *)
let rec set_union a b = match a with
    | [] -> b
    | _ -> (List.hd a)::(set_union (List.tl a) b);; 

(* 4 *)
let rec set_all_union a = match a with 
    | [] -> []
    | _ -> set_union (List.hd a) (set_all_union (List.tl a));;

(* 5 *)
(* It is not possible to write the self_member function since if input s is 'a list but in order to have s be a member of s, then s must be type 'a list list, which is a contradiction. *)

(* 6 *)
let rec computed_fixed_point eq f x =
    if (eq (f x ) x) then x
    else computed_fixed_point eq f (f x);;

(* 7 *)
let rec fun_n f n x = match n with 
    | 1 -> f x
    | _ -> fun_n f (n-1) (f x)
let rec computed_periodic_point eq f p x = match p with 
    | 0 -> x 
    | _ -> if (eq (fun_n f p x) x) then x 
        else computed_periodic_point eq f p (f x);;

(* 8 *)
let rec whileseq s p x =
    if (p x) then x::(whileseq s p (s x))
    else [];;

(* 9 *)
type ('nonterminal, 'terminal) symbol = 
    | N of 'nonterminal
    | T of 'terminal 
;; 

let equal_snd (a1, b1) (a2, b2) = 
    equal_sets b1 b2
;;

let terminal_symbol symbol t_list = match symbol with 
    | T _ -> true
    | N a -> if subset (a::[]) t_list then true 
        else false 
;;

let rec full_rule_terminal symbol_rule t_list =
    if symbol_rule = [] then true
    else if terminal_symbol (List.hd symbol_rule) t_list then full_rule_terminal (List.tl symbol_rule) t_list
    else false
;;

let rec filter_func_rec rules t_list = 
    if rules = [] then t_list
    else let this_rule = List.hd rules in
        if full_rule_terminal (snd this_rule) t_list then filter_func_rec (List.tl rules) ((fst this_rule)::t_list)
        else filter_func_rec (List.tl rules) t_list
;;

let filter_func (rules, t_list) = 
    rules, filter_func_rec rules t_list
;;

let rec filter_symbol rules terminal_symbol result =
    if rules = [] then result 
    else let this_rule = List.hd rules in 
        if full_rule_terminal (snd this_rule) terminal_symbol then filter_symbol (List.tl rules) terminal_symbol (result@(this_rule::[]))
        else filter_symbol (List.tl rules) terminal_symbol result 
;;

let filter_blind_alleys g = 
    let filtered_symbols = (snd (computed_fixed_point equal_snd filter_func ((snd g), []))) in
    (fst g), (filter_symbol (snd g) filtered_symbols [])
;;

