checkRow(L, N) :-
    length(L, N).
checkCol([], _).
checkCol([Hd|Tl], N) :-
    length(Hd, N), 
    checkCol(Tl, N).

/* is T NxN matrix */
isNxN(T, N) :- 
    checkRow(T, N),
    checkCol(T, N).

/* all values in T is between 1, 2, ... , N */
val_between(_, []).
val_between(N, [Hd|Tl]) :-
    fd_domain(Hd, 1, N),
    val_between(N, Tl).

transpose_col([],[],[]).
transpose_col([[H|T]|Rows], [H|Hs], [T|Ts]) :- 
    transpose_col(Rows, Hs, Ts).
trans_matrix([[]|_], []).
trans_matrix(M, [Hd|Tl]) :-
    transpose_col(M, Hd, X),
    trans_matrix(X, Tl).
row_diff([]).
row_diff([Hd|Tl]) :-
    fd_all_different(Hd),
    row_diff(Tl).

/* every row and column is different or a permutation of [1, 2, ... , N] */
val_diff(M) :-
    row_diff(M),
    trans_matrix(M, TM),
    row_diff(TM).

at(T, Row, Col, Val) :-
    nth(Row, T, ARow),
    nth(Col, ARow, Val).
sum(_, [], 0).
sum(T, [[Row|Col]|Tl], Sum) :-
    at(T, Row, Col, Val),
    sum(T, Tl, Part_sum),
    Sum #= Val + Part_sum.

product(_, [], 1).
product(T, [[Row|Col]|Tl], Product) :-
    at(T, Row, Col, Val),
    product(T, Tl, Part_prod),
    Product #= Val * Part_prod.

/* addition constraint */
line_constraint(T, +(S, L)) :- 
    sum(T, L, Sum),
    Sum #= S.

/* multiplication constraint */
line_constraint(T, *(P, L)) :- 
    product(T, L, Product), 
    P #= Product.

/* subtraction constraint */
line_constraint(T, -(D, [Row1|Col1], [Row2|Col2])) :-
    at(T, Row1, Col1, Val1),
    at(T, Row2, Col2, Val2),
    (
        D #= Val1 - Val2;
        D #= Val2 - Val1
    ).

/* division constraint */
line_constraint(T, /(Q, [Row1|Col1], [Row2|Col2])) :- 
    at(T, Row1, Col1, Val1),
    at(T, Row2, Col2, Val2),
    (
        Q #= Val1 / Val2;
        Q #= Val2 / Val1
    ).

/* satisfy all cell constraints */
all_valid(T, L) :- 
    maplist(line_constraint(T), L).

find_sol([]).
find_sol([Hd|Tl]) :-
    fd_labeling(Hd),
    find_sol(Tl).

/* with GNU Prolog finite domain solver */
kenken(N, C, T) :- 
    isNxN(T, N),
    val_between(N, T),
    val_diff(T),
    all_valid(T, C),
    find_sol(T).

/* all values in T is between 1, 2, ... , N */
plain_val_between(_, []).
plain_val_between(N, [Hd|Tl]) :-
    maplist(between(1, N), Hd),
    plain_val_between(N, Tl).

plain_row_diff(N_list, M) :- 
    maplist(permutation(N_list), M).
list_n(N, L):- 
    findall(Num, between(1, N, Num), L).

/* every row and column is different or a permutation of [1, 2, ... , N] */
plain_val_diff(N, M) :-
    list_n(N, X), !,
    plain_row_diff(X, M),
    trans_matrix(M, TM),
    plain_row_diff(X, TM).

/* without GNU Prolog finite domain solver */
plain_kenken(N, C, T) :- 
    isNxN(T, N),
    plain_val_between(N, T),
    plain_val_diff(N, T),
    all_valid(T, C).

/* 
==========
testcase
==========
*/
kenken_testcase(
    6,
    [
    +(11, [[1|1], [2|1]]),
    /(2, [1|2], [1|3]),
    *(20, [[1|4], [2|4]]),
    *(6, [[1|5], [1|6], [2|6], [3|6]]),
    -(3, [2|2], [2|3]),
    /(3, [2|5], [3|5]),
    *(240, [[3|1], [3|2], [4|1], [4|2]]),
    *(6, [[3|3], [3|4]]),
    *(6, [[4|3], [5|3]]),
    +(7, [[4|4], [5|4], [5|5]]),
    *(30, [[4|5], [4|6]]),
    *(6, [[5|1], [5|2]]),
    +(9, [[5|6], [6|6]]),
    +(8, [[6|1], [6|2], [6|3]]),
    /(2, [6|4], [6|5])
    ]
).
/*
    [[5,6,3,4,1,2],
    [6,1,4,5,2,3],
    [4,5,2,3,6,1],
    [3,4,1,2,5,6],
    [2,3,6,1,4,5],
    [1,2,5,6,3,4]]
*/

kenken_3_testcase(
    3, 
    [
        -(1, [1|1], [1|2]),
        *(2, [[2|1], [2|2], [3|2]]),
        +(3, [[3|1]]),
        +(1, [[1|3]]),
        -(1, [2|3], [3|3])
    ]
).
/*
    [[2, 3, 1],
    [1, 2, 3], 
    [3, 1, 2]]
*/

kenken_4_testcase(
    4,
    [
    +(6, [[1|1], [1|2], [2|1]]),
    *(96, [[1|3], [1|4], [2|2], [2|3], [2|4]]),
    -(1, [3|1], [3|2]),
    -(1, [4|1], [4|2]),
    +(8, [[3|3], [4|3], [4|4]]),
    *(2, [[3|4]])
    ]
).
/*
[[1,2,3,4],[3,4,2,1],[4,3,1,2],[2,1,4,3]]
[[1,2,4,3],[3,4,2,1],[4,3,1,2],[2,1,3,4]]
[[2,1,3,4],[3,4,2,1],[4,3,1,2],[1,2,4,3]]
[[2,1,4,3],[3,4,2,1],[4,3,1,2],[1,2,3,4]]
[[3,1,2,4],[2,4,3,1],[4,3,1,2],[1,2,4,3]]
[[3,2,4,1],[1,4,2,3],[4,3,1,2],[2,1,3,4]]
*/


