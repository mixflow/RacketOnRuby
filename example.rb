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

# test set
p r.execute('(define a 3) (set! a 6) (+ 4 a)')

# test cons cells and list
p list_lst1 = r.execute("(list 1 2 3)")
p cons_lst1 = r.execute("(cons 1 (cons 2 (cons 3 null)))")
p list_lst1 == cons_lst1
p r.execute("(car (cdr (cdr (list 1 2 3))))") == 3

# test 'assoc'
p r.execute('(assoc "1st" (list (cons "1st" 1) (cons "2nd" 2)))')

p "let test result(should be 2): %s" % r.execute("(let ([x 1] [y 2]) (* x y))")
p "letrec test result(should be 4): %s" % r.execute("(letrec ([x 2] [y x]) (+ x y))")

r.eval_expressions(fib_ast)

num = 300
p "fibonacci 300 result: %s" % r.execute('(fibonacci 300)')
# open REPL
# r.repl()
r
