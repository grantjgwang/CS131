/* addition constraint */
line_constraint(L, +(S, L)) :- .
    /* S = sum(squares at L list) */

/* multiplication constraint */
line_constraint(L, *(P, L)) :- .
    /* P = product of squares at L list */

/* subtraction constraint */
line_constraint(L, −(D, J, K)) :- .
    /* D =  |square in J - square at K| */

/* division constraint */
line_constraint(L, /(Q, J, K)) :- .
    /* Q = square at J \/ square at K*/

/* is T NxN matrix */
isNxN(T) :- .

/* all values in T is between 1, 2, ... , N */
val_between(N, T) :- .

/* every row and column is different or a permunation of [1, 2, ... , N] */
val_diff(N, T) :- .

/* satisfy all cell constraints */
all_valid(N, C, T) :- .

/* with GNU Prolog finite domain solver */
kenken(N, C, T) :- 
    /*
    N, a nonnegative integer specifying the number of cells on each side of the KenKen square
    C, a list of numeric cage constraints as described below
    T, a list of list of integers. T and its members all have length N. This represents the N×N grid
    */
    isNxN(T),
    val_between(N, T),
    val_diff(N, T),
    all_valid(N, C, T).

/* without GNU Prolog finite domain solver */
plain_kenken(N, C, T) :- .