(* 1 *)
let my_subset_test0 = subset [] [];;
let my_subset_test1 = not (subset [1; 2; 3] []);;
(* 2 *)
let my_equal_sets_test0 = equal_sets [] [];;
let my_equal_sets_test1 = not (equal_sets [] [1; 2; 3]);;
(* 3 *)
let my_set_union_test0 = equal_sets (set_union [] [1; 2; 3]) [1; 2; 3];;
let my_set_union_test1 = equal_sets (set_union [1; 2; 3] [4; 5]) [1; 2; 3; 4; 5];; 
(* 4 *)
let mt_set_all_union_test0 = equal_sets (set_all_union [[1; 2; 3]; [4; 5]]) [1; 2; 3; 4; 5];;
let mt_set_all_union_test1 = equal_sets (set_all_union [[]; [1; 2]; [2; 4]; [5]]) [1; 2; 2; 4; 5];;

(* 6 *)
let my_computed_fixed_point_test0 = (computed_fixed_point (=) (fun x -> x) 0) = 0;;
let my_computed_fixed_point_test1 = (computed_fixed_point (=) (fun x -> x) 5) = 5;;
(* 7 *)
let my_computed_periodic_point_test0 = (computed_periodic_point (=) (fun x -> -x) 2 3) = 3;;
let my_computed_periodic_point_test1 = (computed_periodic_point (=) (fun x -> -x) 2 7) = 7;;
(* 8 *)
let my_whileseq_test0 = equal_sets (whileseq ((+) 3) ((>) 10) 0) [0; 3; 6; 9];;
let my_whileseq_test1 = equal_sets (whileseq ((+) 1) ((>) 5) 0) [0; 1; 2; 3; 4];;
(* 9 *)
type my_test0_nonterminals =
  | A | B | S
;;
let my_test0_rules = [
    S, [N A; N B];
    A, [T "A"];
    A, [N A; N A];
    A, [];
    B, [T "B"];
    B, [];
    B, [N B; N B]
];;
let my_test0_grammar = S, my_test0_rules;;
let my_blind_alleys_test0 = filter_blind_alleys my_test0_grammar = my_test0_grammar;;
