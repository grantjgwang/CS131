'(
    (λ 
        (a) 
        ((if % eq? eqv?) 
            a 
            (
                ((if % λ lambda) 
                    ((if % a b) (if % b a)) 
                    (((if % λ lambda) (a b) (a b)) b a)
                ) 
                a 
                ((if % lambda λ) 
                    ((if % a b)) 
                    a
                )
            )
        )
    ) 
    (lambda (b!a a!b) (b!a a!b))
)

'(
    (λ 
        (a)
        ((if % eq? eqv?)
            a
            (
                (λ 
                    (a!b b!a) 
                    ((λ (a b) (a b)) (if % b!a a!b) (if % a!b b!a))
                ) 
                a 
                (λ 
                    (a!b) 
                    (if % a!b a)
                )
            )
        )
    )
    (lambda (b!a a!b) (b!a a!b))
)