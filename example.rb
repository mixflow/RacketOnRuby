require_relative 'racket.rb'
r = Racket.new
str1 =
%{(+ 1
     (* 2
        (- 7 3)))
}

p r.tokenize(str1)

str1 =
%{(+ 1
(* 2
(- 7 3)))
}
p r.tokenize(str1)

str2 =
%{
(define (my-delay th)
  (mcons #f th))
(define (my-force p)
  (if (mcar p)
      (mcdr p)
      (begin (set-mcar! p #t)
             (set-mcdr! p ((mcdr p)))
             (mcdr p))))
}
p r.generate_ast(r.tokenize(str2))

fib_str =
%{
(define fibonacci
  (letrec ([memo null]
           [f (lambda (x)
                (let ([ans (assoc x memo)])
                  (if ans
                      (cdr ans)
                      (let ([new-ans (if (or (= x 1) (= x 2))
                                         1
                                         (+ (f (- x 1)) (f (- x 2))))])
                        (begin
                          (set! memo (cons (cons x new-ans) memo))
                          new-ans)))))])
    f))
}
fib_tokens = r.tokenize(fib_str)
fib_ast = r.generate_ast(fib_tokens)
puts "tokens:" + fib_tokens.to_s
p fib_ast

simple_algebra = "(+ 2 (* 2 3))"
p r.eval(r.parse(simple_algebra))
