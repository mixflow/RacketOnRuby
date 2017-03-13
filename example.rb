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
