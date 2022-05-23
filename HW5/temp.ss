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