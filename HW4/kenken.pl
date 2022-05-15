checkRow(T, N) :-
    length(T, N).
checkCol([Hd|Tl], N) :-
    length(Hd, N).

/* is T NxN matrix */
isNxN(T, N) :- 
    checkRow(T, N),
    checkCol(T, N).

/* all values in T is between 1, 2, ... , N */
val_between(_, []).
val_between(N, [Hd|Tl]) :-
    fd_domain(Hd, 1, N),
    val_between(N, Tl).

list_n(N, L):- 
    findall(Num, between(1, N, Num), L).
transpose_col([],[],[]).
transpose_col([[H|T]|Rows], [H|Hs], [T|Ts]) :- 
    transpose_col(Rows, Hs, Ts).
trans_matrix([[]|_], []).
trans_matrix(M, [Hd|Tl]) :-
    transpose_col(M, Hd, X),
    trans_matrix(X, Tl).
row_diff(_, []).
row_diff(N_list, [Hd|Tl]) :-
    permutation(Hd, N_list),
    row_diff(N_list, Tl).

/* every row and column is different or a permunation of [1, 2, ... , N] */
val_diff(N, M) :-
    list_n(N, X),
    row_diff(X, M),
    trans_matrix(M, TM),
    row_diff(X, TM).

at(T, Row, Col, Val) :-
    nth(Row, T, ARow),
    nth(Col, ARow, Val).
sum(T, [], 0).
sum(T, [[Row|Col]|Tl], Sum) :-
    at(T, Row, Col, Val),
    sum(T, Tl, Part_sum),
    Sum is Val + Part_sum.

/* addition constraint */
line_constraint(T, +(S, L)) :- 
    sum(T, L, Sum),
    S is Sum.

product(T, [], 1).
product(T, [[Row|Col]|Tl], Product) :-
    at(T, Row, Col, Val),
    sum(T, Tl, Part_prod),
    Product is Val * Part_prod.
/* multiplication constraint */
line_constraint(T, *(P, L)) :- 
    product(T, L, Product), 
    P is Product.

/* subtraction constraint */
%line_constraint(T, −(D, J, K)) :- 
    /* D =  |square in J - square at K| */

/* division constraint */
%line_constraint(T, /(Q, J, K)) :- 
    /* Q = square at J \/ square at K*/

/* satisfy all cell constraints */
%all_valid(N, C, T) :- 

/* with GNU Prolog finite domain solver */
%kenken(N, C, T) :- 
    /*
    N, a nonnegative integer specifying the number of cells on each side of the KenKen square
    C, a list of numeric cage constraints as described below
    T, a list of list of integers. T and its members all have length N. This represents the N×N grid
    */
%    isNxN(T, N),
%    val_between(N, T),
%    val_diff(N, T),
%    all_valid(N, C, T).

/* without GNU Prolog finite domain solver */
%plain_kenken(N, C, T) :- 


/*
T = 
[[5,6,3,4,1,2], [6,1,4,5,2,3], [4,5,2,3,6,1], [3,4,1,2,5,6], [2,3,6,1,4,5], [1,2,5,6,3,4]]
*/