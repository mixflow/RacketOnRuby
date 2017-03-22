load 'racket.rb'
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
puts "fibonacci tokens:" + fib_tokens.to_s
p fib_ast

simple_algebra = "(+ 1 (* 2 3))"
p r.parse(simple_algebra)
p " 1+(2*3) result: %s" % r.eval_expressions(r.parse(simple_algebra))

if_str = "(if (> 1 2) (* 1 2) (- 4 9))"
# p r.parse(if_str)
p "should be -5, actual result: %s " % r.eval_expressions(r.parse(if_str))

p list_lst1 = r.execute("(list 1 2 3)")
p cons_lst1 = r.execute("(cons 1 (cons 2 (cons 3 null)))")
p list_lst1 == cons_lst1
p r.execute("(car (cdr (cdr (list 1 2 3))))") == 3
# open REPL
r.repl()
