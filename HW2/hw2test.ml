(* 5 *)
let accept_all string = Some string
let accept_empty_suffix = function
   | _::_ -> None
   | x -> Some x

type awksub_nonterminals =
  | Expr | Num | Binop | Term

let test_grammar =
  (Expr,
   function
     | Expr ->
         [[N Term; N Binop; N Expr];
          [N Term]]
     | Binop ->
        [[T "+"];
          [T "-"]]
     | Term ->
        [[N Num];
          [N Num; N Term]]
     | Num ->
	    [[T "0"]; 
          [T "1"]])    

let make_matcher_test1 =
  ((make_matcher test_grammar accept_all ["1"; "2"]) = Some ["2"])

let make_matcher_test2 =
  ((make_matcher test_grammar accept_all ["+"; "-"; "0"]) = None)

let make_matcher_test3 =
  ((make_matcher test_grammar accept_empty_suffix ["1"; "+"; "0"; "1"; "0"]) = Some [])

let make_matcher_test4 =
  ((make_matcher test_grammar accept_empty_suffix ["1"; "1"; "-"; "1"; "-"]) = None)

let make_matcher_test5 =
 ((make_matcher test_grammar accept_empty_suffix
     ["1"; "0"; "1"; "0"; "1"; "+"; "1"; "-"; "0"; "1"; "0"; "1"; "0"; "+"; "1"; "0"; "0"; "0"; "1"])= Some [])

(* 6 *)
let make_matcher_tester1 = ["1"; "1"; "+"; "0"; "1"; "-"; "1"]
let make_matcher_tester2 = (make_parser test_grammar make_matcher_tester1)
let make_parser_test1 = 
    (make_matcher_tester2
      = Some 
      (Node (Expr,
            [Node (Term,
                [Node (Num, 
                    [Leaf "1"]); 
                Node (Term, 
                    [Node (Num, 
                        [Leaf "1"])])]);
            Node (Binop, [Leaf "+"]);
            Node (Expr,
                [Node (Term,
                    [Node (Num, 
                        [Leaf "0"]); 
                    Node (Term, 
                        [Node (Num, 
                            [Leaf "1"])])]);
                Node (Binop, 
                    [Leaf "-"]);
                Node (Expr, 
                    [Node (Term, 
                        [Node (Num, 
                            [Leaf "1"])])])])]))
    )

let make_parser_test2 = ( match make_matcher_tester2 with 
    | Some a -> (parse_tree_leaves a) = make_matcher_tester1
    | _ -> false) 
                      
