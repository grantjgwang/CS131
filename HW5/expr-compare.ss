#lang racket
(provide (all-defined-out))
(define ns (make-base-namespace))

; check lambda;
(define LAMBDA (string->symbol "\u03BB"))
(define (foo a) a)

(define (get-var-map x y var-map)
  (cond
    [(and (> (length x) 0) (> (length y) 0))
      (cond 
        [(not (equal? (hash-ref var-map (car x) 'err) 'err))
          (let (
            [updater (lambda (a) (foo (car y)))]
          )
            (get-var-map (cdr x) (cdr y) (hash-update var-map (car x) updater 'err))
          )
        ]
        [(equal? (hash-ref var-map (car x) 'err) 'err)
          (hash-set (get-var-map (cdr x) (cdr y) var-map) (car x) (car y))
        ]
      )
    ]
    [(and (< (length x) 1) (< (length y) 1))
      var-map
    ]
  )
)

(define (expr-comparator x y x-var-map y-var-map)
  (letrec (
    [lists-compare (lambda (x y x-var-map y-var-map) 
      ; (display "=====list-compare=====\n")
      ; (display x)
      ; (display "\n")
      ; (display y)
      ; (display "\n")
      (cond 
        [(and (> (length x) 1) (> (length y) 1))
          (cons (expr-comparator (car x) (car y) x-var-map y-var-map) (lists-compare (cdr x) (cdr y) x-var-map y-var-map))
        ]
        [else
          (cons (expr-comparator (car x) (car y) x-var-map y-var-map) '())
        ]
      )
    )]
    [func-arg-compare (lambda (x y) 
      ; (display "=====func-arg-compare=====\n")
      ; (display x)
      ; (display "\n")
      ; (display y)
      ; (display "\n")
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
    [check-named-var (lambda (x y x-var-map y-var-map)
      ; (display "=====check-arg-named-var=====\n")
      ; (display x)
      ; (display "\n")
      ; (display y)
      ; (display "\n")
      (cond 
        [(or 
          (not (equal? (hash-ref x-var-map x 'err) 'err)) 
          (not (equal? (hash-ref y-var-map y 'err) 'err))
        )
          #t
        ]
        [else
          #f
        ]
      )
    )]
    [get-sub-named-var (lambda (x var-map x-or-y)
      ; (display "=====get-sub-named-var=====\n")
      ; (display x)
      ; (display "\n")
      ; (display y)
      ; (display "\n")
      (cond 
        [(equal? (hash-ref var-map x 'err) 'err)
          x
        ]
        [(not (equal? (hash-ref var-map x 'err) 'err))
          (cond 
            [(equal? (hash-ref var-map x 'err) x)
              x
            ]
            [(not (equal? (hash-ref var-map x 'err) x))
              (cond 
                [(equal? x-or-y 'x)
                  (string->symbol (string-append
                    (symbol->string x)
                    "!" 
                    (symbol->string (hash-ref var-map x 'err))
                  ))
                ]
                [(equal? x-or-y 'y)
                  (string->symbol (string-append
                    (symbol->string (hash-ref var-map x 'err))
                    "!" 
                    (symbol->string x)
                  ))
                ]
              )
            ]
          )
        ] 
      )
    )]
    [sub-named-var (lambda (x y x-var-map y-var-map)
      ; (display "=====sub-named-var=====\n")
      ; (display x)
      ; (display "\n")
      ; (display y)
      ; (display "\n")
      ; (display x-var-map)
      ; (display "\n")
      ; (display y-var-map)
      ; (display "\n")
      (cond 
        [(and
          (not (equal? (hash-ref x-var-map x 'err) 'err))
          (not (equal? (hash-ref y-var-map y 'err) 'err))
          )
          (cond
            [(and 
              (equal? (hash-ref x-var-map x 'err) y)
              (equal? (hash-ref y-var-map y 'err) x)
              )
              (cond 
                [(equal? x y)
                  x
                ]
                [else
                  (string->symbol (string-append
                    (symbol->string x) 
                    "!" 
                    (symbol->string y)
                  ))
                ]
              )
            ]
            [else
              (list
                'if
                '%
                (get-sub-named-var x x-var-map 'x)
                (get-sub-named-var y y-var-map 'y)
              )
            ]
          )
        ]
        [else
          (list
            'if
            '%
            (get-sub-named-var x x-var-map 'x)
            (get-sub-named-var y y-var-map 'y)
          )
        ]
      )
    )]
    [lambda-compare (lambda (x y x-var-map y-var-map) 
      ; (display "=====lambda-compare====\n")
      ; (display x)
      ; (display "\n")
      ; (display y)
      ; (display "\n")
      (let (
        [new-x-var-map (get-var-map (car x) (car y) x-var-map)]
        [new-y-var-map (get-var-map (car y) (car x) y-var-map)]
        ; [x-var-map (get-var-map (car x) (car y) (hash))]
        ; [y-var-map (get-var-map (car y) (car x) (hash))]
        )
        (cons (func-arg-compare (car x) (car y)) (cons (expr-comparator (car (cdr x)) (car (cdr y)) new-x-var-map new-y-var-map) '()))
      )
    )]
    ) 
    ; (display "------------expr-comparator---------\n")
    ; (display x)
    ; (display "\n")
    ; (display y)
    ; (display "\n")
    (cond 
      [(not (equal? (check-named-var x y x-var-map y-var-map) #f))
        ; (display "x or y one is variable\n")
        (sub-named-var x y x-var-map y-var-map)
      ]
      ; case: x and y are the same
      [(equal? x y) 
        ; (display "x and y are same\n")
        (if (equal? x 'empty) '() x)
      ]
      ; case: both boolean such as "#f" ands "#t"
      [(and (boolean? x) (boolean? y)) 
        ; (display "x and y are boolean\n")
        (if x '% '(not %))
      ]
      ; case: one of them is not function such as "'(foo a b)" and "'a"
      [(or (not (list? x)) (not (list? y)))
        ; (display "one of x and y is not list\n")
        (list 'if '% x y)
      ]
      ; case: comparisonm stops when both x and y are quotes
      [(or (and (equal? (car x) 'quote) (equal? (car y) 'quote)))
        ; (display "x and y are quotes\n")
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
        ; (display "if appear\n")
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
        ; (display "two lambda\n")
        (cond 
          [(= (length (car (cdr x))) (length (car (cdr y))))
            (cons 'lambda (lambda-compare (cdr x) (cdr y) x-var-map y-var-map))
          ]
          [else
            (list 'if '% x y) 
          ]
        )
        
      ]
      [(and 
          (or 
            (and (equal? LAMBDA (car x)) (equal? LAMBDA (car y)))
            (and (equal? LAMBDA (car x)) (equal? 'lambda (car y)))
            (and (equal? 'lambda (car x)) (equal? LAMBDA (car y)))
          )
          (= (length x) 3)
          (= (length y) 3)
        )
        (cond 
          [(= (length (car (cdr x))) (length (car (cdr y))))
            (cons LAMBDA (lambda-compare (cdr x) (cdr y) x-var-map y-var-map))
          ]
          [else
            (list 'if '% x y) 
          ]
        )
      ]
      [(and 
           (or 
            (and 
              (or (equal? LAMBDA (car x)) (equal? 'lambda (car x))) 
              (not (or (equal? LAMBDA (car y)) (equal? 'lambda (car y))))
            )
            (and 
              (not (or (equal? LAMBDA (car x)) (equal? 'lambda (car x))) )
              (or (equal? LAMBDA (car y)) (equal? 'lambda (car y)))
            )
          )
          (= (length x) 3)
          (= (length y) 3)
        )
        (list 'if '% x y)
      ]
      [(and (list? x) (list? y) (equal? (length x) (length y)))
        ; (display "x and y are lists/functinos\n")
        (lists-compare x y x-var-map y-var-map)
      ]
    )
  )
)

(define (expr-compare x y) 
  (expr-comparator x y (hash) (hash))
)

(define (test-expr-compare x y) 
  (let (
    [case-x `(let ([% #t]) ,(expr-compare x y))]
    [case-y `(let ([% #f]) ,(expr-compare x y))]
  )
    (and 
      (equal? 
        (eval x ns)
        (eval case-x ns)
      )
      (equal? 
        (eval y ns)
        (eval case-y ns)
      )
    )
  )
)

(define test-expr-x '((lambda (a) (eq? a ((λ (a b) ((λ (a b) (a b)) b a)) a (lambda (a) a)))) (lambda (b a) (b a))))
(define test-expr-y '((λ (a) (eqv? a ((lambda (b a) ((lambda (a b) (a b)) b a)) a (λ (b) a)))) (lambda (a b) (a b))))

; (define test-expr-x '((lambda (lambda) (+ lambda if (f lambda))) 3))
; (define test-expr-y '((lambda (if) (+ if if (f λ))) 3))

; (test-expr-compare test-expr-x test-expr-y)


(expr-compare '(λ (x) ((λ (x) x) x))
                   '(λ (y) ((λ (x) y) x)))