#lang racket
(provide (all-defined-out))
(define ns (make-base-namespace))

; check lambda;
(define LAMBDA (string->symbol "\u03BB"))

(define (get-var-map x y)
  (cond
    [(and (> (length x) 0) (> (length y) 0))
      (hash-set (get-var-map (cdr x) (cdr y)) (car x) (car y))
    ]
    [(and (< (length x) 1) (< (length y) 1))
      (hash)
    ]
  )
)

(define (expr-compare x y)
  (letrec (
    ; function for comparing two lists/functions with same length
    [lists-compare (lambda (x y) 
      ; (display "=====deal list/function=====\n")
      ; (display x)
      ; (display "\n")
      ; (display y)
      ; (display "\n")
      (cond 
        [(and (> (length x) 1) (> (length y) 1))
          (cons (expr-compare (car x) (car y)) (lists-compare (cdr x) (cdr y)))
        ]
        [else
          (cons (expr-compare (car x) (car y)) '())
        ]
      )
    )]
    [func-arg-compare (lambda (x y) 
      ; (display "doing func-arg-compare\n")
      (cond 
        [(and (> (length x) 0) (> (length y) 0))
          (cond
            [(equal? (car x) (car y))
              (cons (car x) (func-arg-compare (cdr x) (cdr y)))
            ]
            [else
              (cons 
                (string->symbol (string-append 
                  (symbol->string (car x)) 
                  "!" 
                  (symbol->string (car y))
                ))
                (func-arg-compare (cdr x) (cdr y)) 
              )
            ]
          )
        ]
        [else
          '()
        ]
      )
    )]
    [func-body-compare (lambda (x y x-var-map y-var-map)
      (display "doing func-body-compare\n")
      (display x)
      (display "\n")
      (display y)
      (display "\n")
      (cond 
        [(and (not (list? x)) (not (list? y)))
          (cond
            [(and
                (not (equal? (hash-ref x-var-map x 'err) 'err))
                (not (equal? (hash-ref y-var-map y 'err) 'err))
              )
              (display "both are variables\n")
              (cond
                [(equal? x y)
                  x
                ]
                [(and
                    (equal? (hash-ref x-var-map x 'err) y) 
                    (equal? (hash-ref y-var-map y 'err) x)
                  )
                  (string->symbol (string-append
                    (symbol->string x) 
                    "!" 
                    (symbol->string y)
                  ))
                ]
                [(and 
                    (equal? (hash-ref x-var-map x 'err) x)
                    (equal? (hash-ref y-var-map y 'err) y)
                  )
                  (list
                    'if
                    '%
                    x
                    y
                  )
                ]
                [(and 
                    (not (equal? (hash-ref x-var-map x 'err) x))
                    (equal? (hash-ref y-var-map y 'err) y)
                  )
                  (list
                    'if
                    '%
                    (string->symbol (string-append
                      (symbol->string x)
                      "!" 
                      (symbol->string (hash-ref x-var-map x 'err)) 
                    ))
                    y
                  )
                ]
                [(and 
                    (equal? (hash-ref x-var-map x 'err) x)
                    (not (equal? (hash-ref y-var-map y 'err) y))
                  )
                  (list
                    'if
                    '%
                    x
                    (string->symbol (string-append
                      (symbol->string (hash-ref y-var-map y 'err))
                      "!" 
                      (symbol->string y)
                    ))
                  )
                ]
                [(and 
                    (not (equal? (hash-ref x-var-map x 'err) y))
                    (not (equal? (hash-ref y-var-map y 'err) x))
                  )
                  (list
                    'if
                    '%
                    (string->symbol (string-append
                      (symbol->string x)
                      "!" 
                      (symbol->string (hash-ref x-var-map x 'err))
                    ))
                    (string->symbol (string-append
                      (symbol->string (hash-ref y-var-map y 'err))
                      "!" 
                      (symbol->string y) 
                    ))
                  )
                ]
              )
            ]
            [(not (equal? (hash-ref x-var-map x 'err) 'err))
              (display "x is variable\n")
              (cond
                [(equal? (hash-ref x-var-map x 'err) x)
                  (list
                    'if
                    '%
                    x
                    y
                  )
                ]
                [else
                  (list
                    'if
                    '%
                    (string->symbol (string-append
                      (symbol->string x)
                      "!" 
                      (symbol->string (hash-ref x-var-map x 'err))
                    ))
                    y
                  )
                ]
              )  
            ]
            [(not (equal? (hash-ref y-var-map y 'err) 'err))
              (display "y is variable\n")
              (cond 
                [(equal? (hash-ref y-var-map y 'err) y)
                  (list
                    'if
                    '%
                    x
                    y
                  )
                ]
                [else
                  (list
                    'if
                    '%
                    x
                    (string->symbol (string-append
                      (symbol->string (hash-ref y-var-map y 'err))
                      "!" 
                      (symbol->string y)
                    ))
                  )
                ]
              )  
            ]
            [else
              (display "both not variable\n")
              (cond 
                [(equal? x y) 
                  (display "x and y are same\n")
                  (if (equal? x 'empty) '() x)
                ]
                [(and (boolean? x) (boolean? y)) 
                  (display "x and y are boolean\n")
                  (if x '% '(not %))
                ]
                ; case: one of them is not function such as "'(foo a b)" and "'a"
                [(or (not (list? x)) (not (list? y)))
                  (display "one of x and y is not list\n")
                  (list 'if '% x y)
                ]
                ; case: comparisonm stops when both x and y are quotes
                [(or (and (equal? (car x) 'quote) (equal? (car y) 'quote)))
                  (display "x and y are quotes\n")
                  (list 'if '% x y)
                ]
                [(or 
                    (and 
                      (equal? (car x) 'if) 
                      (not (equal? (car y) 'if))
                    ) 
                    (and 
                      (not (equal? (car x) 'if))
                      (equal? (car y) 'if)
                    )
                  )
                  (list 'if '% x y)
                ]
                ; case: x and y are in different length
                [(and (not (equal? (length x) (length y))))
                  ; (display "x and y in different length\n")
                  (list 'if '% x y) 
                ]
                [(and 
                    (equal? 'lambda (car x))
                    (equal? 'lambda (car y))
                    (= (length x) 3)
                    (= (length y) 3)
                  )
                  (display "two lambda\n")
                  (cons 'lambda (lambda-compare (cdr x) (cdr y)))
                ]
                [(and 
                    (or 
                      (equal? LAMBDA (car x))
                      (equal? LAMBDA (car y))
                    )
                    (= (length x) 3)
                    (= (length y) 3)
                  )
                  (display "at least one LAMBDA\n")
                  (cons LAMBDA (lambda-compare (cdr x) (cdr y)))
                ]
                [(and (list? x) (list? y) (equal? (length x) (length y)))
                  (display "x and y are lists/functinos\n")
                  (lists-compare x y)
                ]
              )
              (expr-compare x y)
            ]
          )
        ]
        [(and (null? x) (null? y))
          '()
        ]
        [(and )

        ]
        [else
          (cons  
            (func-body-compare (car x) (car y) x-var-map y-var-map)
            (func-body-compare (cdr x) (cdr y) x-var-map y-var-map)
          )
        ]
        
      )
    )]
    [lambda-compare (lambda (x y) 
      (display "doing lambda compare\n")
      (let (
        [x-var-map (get-var-map (car x) (car y))]
        [y-var-map (get-var-map (car y) (car x))]
        )
        ; (display (hash->list x-var-map))
        ; (display "\n")
        ; (display (hash->list y-var-map))
        ; (display "\n")
        ; (cond
        ;   [(and (list? (car (cdr x))) (list? (car (cdr y))))
        ;     ; (display "lambda longer than 1\n")
        ;     (cons (func-arg-compare (car x) (car y)) (cons (func-body-compare (car (cdr x)) (car (cdr y)) x-var-map y-var-map) '()))
        ;   ]
        ;   [else
        ;     ; (display "lambda not longer than 1\n")
        ;     (cons (func-arg-compare (car x) (car y)) (func-body-compare (car (cdr x)) (car (cdr y)) x-var-map y-var-map))
        ;   ]
        ; )
        (cons (func-arg-compare (car x) (car y)) (cons (func-body-compare (car (cdr x)) (car (cdr y)) x-var-map y-var-map) '()))
      )
    )]
    ) 
    (display "------------deal expr---------\n")
    (display x)
    (display "\n")
    (display y)
    (display "\n")
    (cond 
      ; case: x and y are the same
      [(equal? x y) 
        (display "x and y are same\n")
        (if (equal? x 'empty) '() x)
      ]
      ; case: both boolean such as "#f" ands "#t"
      [(and (boolean? x) (boolean? y)) 
        (display "x and y are boolean\n")
        (if x '% '(not %))
      ]
      ; case: one of them is not function such as "'(foo a b)" and "'a"
      [(or (not (list? x)) (not (list? y)))
        (display "one of x and y is not list\n")
        (list 'if '% x y)
      ]
      ; case: comparisonm stops when both x and y are quotes
      [(or (and (equal? (car x) 'quote) (equal? (car y) 'quote)))
        (display "x and y are quotes\n")
        (list 'if '% x y)
      ]
      [(or 
          (and 
            (equal? (car x) 'if) 
            (not (equal? (car y) 'if))
          ) 
          (and 
            (not (equal? (car x) 'if))
            (equal? (car y) 'if)
          )
        )
        (list 'if '% x y)
      ]
      ; case: x and y are in different length
      [(and (not (equal? (length x) (length y))))
        ; (display "x and y in different length\n")
        (list 'if '% x y) 
      ]
      [(and 
          (equal? 'lambda (car x))
          (equal? 'lambda (car y))
          (= (length x) 3)
          (= (length y) 3)
        )
        (display "two lambda\n")
        (cons 'lambda (lambda-compare (cdr x) (cdr y)))
      ]
      [(and 
          (or 
            (equal? LAMBDA (car x))
            (equal? LAMBDA (car y))
          )
          (= (length x) 3)
          (= (length y) 3)
        )
        (display "at least one LAMBDA\n")
        (cons LAMBDA (lambda-compare (cdr x) (cdr y)))
      ]
      [(and (list? x) (list? y) (equal? (length x) (length y)))
        (display "x and y are lists/functinos\n")
        (lists-compare x y)
      ]
    )
  )
)

; compare and see if the (expr-compare x y) result is the same with x when % = #t
;                                                 and the same with y when % = #f
(define (test-expr-compare x y) 
  (and (equal? (eval x)
               (eval `(let ((% #t)) ,(expr-compare x y))))
       (equal? (eval y)
               (eval `(let ((% #f)) ,(expr-compare x y))))))

; WARNING: IT MUST BE A SINGLE TEST CASE
; You need to cover all grammars including:
;     constant literals, variables, procedure calls, quote, lambda, if
(define test-expr-x
  `(cons 12 ((lambda (a) (+ a 1)) 2)))

(define test-expr-y
  `(cons 11 ((lambda (a) (+ a 2)) 3)))


; the following line can be tested from interpreter
;     (eval test-expr-x)
;     (test-expr-compare test-expr-x test-expr-y))
;           test-expr-compare should return #t after you finish its implementation
;     (expr-compare 'a '(cons a b)) 
;     (expr-compare '(cons a b) '(cons a b))
;     (lambda? 'λ)

; test cases;
; (expr-compare 12 12) ; 12;
; (expr-compare 12 20) ; (if % 12 20);
; (expr-compare #t #t) ; #t;
; (expr-compare #f #f) ; #f;
; (expr-compare #t #f) ; %;
; (expr-compare #f #t) ; (not %);
; (expr-compare '(/ 1 0) '(/ 1 0.0)) ; (/ 1 (if % 0 0.0));
; (expr-compare 'a '(cons a b)) ; (if % a (cons a b));
; (expr-compare '(cons a b) '(cons a b)) ; (cons a b);
; (expr-compare '(cons a lambda) '(cons a λ)) ; (cons a (if % lambda λ));
; (expr-compare '(cons (cons a b) (cons b c))
;               '(cons (cons a c) (cons a c))) ; (cons (cons a (if % b c)) (cons (if % b a) c));
; (expr-compare '(cons a b) '(list a b)) ; ((if % cons list) a b);
; (expr-compare '() empty) ; '();
; (expr-compare '(list) '(list a)) ; (if % (list) (list a));
; (expr-compare ''(a b) ''(a c)) ; (if % '(a b) '(a c)); 
; (expr-compare '(quote (a b)) '(quote (a c))) ; (if % '(a b) '(a c)); 
; (expr-compare '(quoth (a b)) '(quoth (a c))) ; (quoth (a (if % b c)));
; (expr-compare '(if x y z) '(if x z z)) ; (if x (if % y z) z);
; (expr-compare '(if x y z) '(g x y z)) ; (if % (if x y z) (g x y z));
; (expr-compare '((lambda (a) (f a)) 1) '((lambda (a) (g a)) 2)) ; ((lambda (a) ((if % f g) a)) (if % 1 2));
; (expr-compare '((lambda (a) (f a)) 1) '((λ (a) (g a)) 2)) ; ((λ (a) ((if % f g) a)) (if % 1 2));
; (expr-compare '((lambda (a) a) c) '((lambda (b) b) d)) ; ((lambda (a!b) a!b) (if % c d));
; (expr-compare ''((λ (a) a) c) ''((lambda (b) b) d)) ; (if % '((λ (a) a) c) '((lambda (b) b) d));
; (expr-compare '(+ #f ((λ (a b) (f a b)) 1 2))
;               '(+ #t ((lambda (a c) (f a c)) 1 2)))
; #|
;   (+
;      (not %)
;      ((λ (a b!c) (f a b!c)) 1 2)) 
; |#
; (expr-compare '((λ (a b) (f a b)) 1 2)
;               '((λ (a b) (f b a)) 1 2))
; #|
; ((λ (a b) (f (if % a b) (if % b a))) 1 2)
; |#
; (expr-compare '((λ (a b) (f a b)) 1 2)
;               '((λ (a c) (f c a)) 1 2))
; #|
; ((λ (a b!c) (f (if % a b!c) (if % b!c a))) 1 2)
; |#


; (expr-compare '((lambda (lambda) (+ lambda if (f lambda))) 3)
;               '((lambda (if) (+ if if (f λ))) 3))
; #|
; ((lambda (lambda!if) (+ lambda!if (if % if lambda!if) (f (if % lambda!if λ)))) 3)
; |#
(expr-compare 
'(
  (lambda 
    (a) 
    (eq? 
      a 
      (
        (λ 
          (a b) 
          (
            (λ (a b) (a b)) 
            b a
          )
        ) 
        a 
        (lambda (a) a)
      )
    )
  )
  (lambda (b a) (b a))
)

'(
  (λ 
    (a) 
    (eqv? 
      a 
      (
        (lambda 
          (b a) 
          (
            (lambda (a b) (a b)) 
            b a
          )
        ) 
        a 
        (λ (b) a)
      )
    )
  )
  (lambda (a b) (a b))
))
#|
    ((λ (a)
      ((if % eq? eqv?)
       a
       ((λ (a!b b!a) ((λ (a b) (a b)) (if % b!a a!b) (if % a!b b!a)))
        a (λ (a!b) (if % a!b a)))))
     (lambda (b!a a!b) (b!a a!b)))
|#