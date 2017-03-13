class Racket
    def tokenize(str)
        str.gsub(/\s\s+/, " ") # replace multi whitespaces to one space
           .gsub!("(", "( ") # add space after '('
           .gsub!(")", " )") # add space before ')'
           .split(" ") # split string into an array(tokens) base on space
    end
end
