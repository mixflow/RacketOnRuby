class Racket
    def tokenize(str)
       str.gsub("(", "( ") # add space after '('
           .gsub!(")", " )") # add space before ')'
           .split(" ") # split string into an array(tokens) base on whitespaces
    end
end
