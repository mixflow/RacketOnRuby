
class Racket
    def tokenize(str)
       str.gsub("(", "( ") # add space after '('
          .gsub(")", " )") # add space before ')'
          .gsub("[", "[ ")
          .gsub("]", " ]")
          .split(" ") # split string into an array(tokens) base on whitespaces
    end

    def generate_ast(tokens)
        parenthesis_map = {"("=>")", "["=>"]"} # the march parenthesis
        aux = lambda do |tokens, acc, left_parenthesis=nil|
            # the auxiliary(helper) function
            # @param tokens: the token array which is generated by 'tokenize' function
            # @param acc: the accumulator holds the result. array(maybe nested), default []

            if tokens.empty?
                # no tokens left, return result
                return acc
            end

            token = tokens.shift # get first token
            if '(' == token or '[' == token # start one s-expression
                sub_ast = aux.call tokens, [], token
                acc.push sub_ast

                aux.call(tokens,  acc, left_parenthesis) # recursive call to continue handling rest tokens
            elsif ')' == token or ']' == token # end one s-expression
                # match parenthesis
                if left_parenthesis.nil?
                    raise "unexpected \"%s\" ." % token
                elsif parenthesis_map[left_parenthesis] != token
                    raise "unmatched parenthesis. excepted \"%s\" to close \"%s\", found instead \"%s\"." % [
                        parenthesis_map[left_parenthesis], left_parenthesis, token]
                else
                    return acc
                end
            else
                acc.push atom(token) # convent current token to atom
                aux.call tokens, acc, left_parenthesis # recursive
            end
        end
        # initial call helper. copy tokens pass to 'aux', because tokens will be mutated in 'aux'
        aux.call tokens[0..-1], [], nil
    end

    def atom(token)
        str_part = token[/^"(.*)"$/, 1] # try match string(start and end with ")
        if not str_part.nil?
            str_part
        elsif token[/(?=(\.|[eE]))(\.\d+)?([eE][+-]?\d+)?$/]  # decimal
            token.to_f
        elsif token[/^\d+$/] # integer
            token.to_i
        else # symbol
            token.to_sym
        end
    end

    def parse(str)
        generate_ast( tokenize(str) )
    end

    ALGEBRA_OPERATORS = [:+, :-, :*, :/]
    COMPARISION = [:'=', :<, :>, :<=, :>=]
    UNASSIGNED_VAL = "*unassigned*"

    class Closure
        attr_reader :parameters, :body, :env
        def initialize(parameters, body ,env)
            @parameters = parameters
            @body = body
            @env = env
        end
    end

    attr_reader :env
    def initialize()

        @env = [
            [:'#t' ,  true],
            [:'#f' ,  false],
            # Racket 'not' operator if exp is #f, results #t. otherwise false. it differents from ruby not
            [:not ,  lambda { |exp| if false==exp then true else false end }],
            [:and ,  lambda { |*args| args.all? {|x| x == true} }],
            [:or ,  lambda { |*args| args.any? {|x| x == true} }],
            # cons cell, list
            [:null? ,  lambda { |exp| :null == exp }], # racket empty list.
            [:cons ,  lambda { |x, cell| [x, cell] }],
            [:car ,  lambda { |cell| cell[0] }],
            [:cdr ,  lambda { |cell| cell[1] }],
            [:list , lambda do |*args|
                # racket code '(list 1 2 3)' is equivalent to '(cons 1 (cons 2 (cons 3 null)))'
                racket_list_helper= lambda do |args|
                    if args.empty? then :null
                    else [args[0], racket_list_helper.call(args[1..-1])]
                    end
                end
                racket_list_helper.call(args)
            end],

            [:assoc , lambda do |key, cell|
                # find value based on key through list of some key-to-val pairs
                # (assoc "1st" (list (cons "1st" 1) (cons "2nd" 2))) # result: (cons "1st" 1)
                aux = lambda do |key, cell|
                    if cell == :null or cell.empty? # empty list
                        false # not found
                    else
                        map=cell[0]
                        if key == map[0]
                            map # return key, value pair
                        else
                            aux.call(key, cell[1])
                        end
                    end
                end
                aux.call(key, cell)
            end],
            [:begin , lambda do |*args|
                args[-1] # return last result.
            end]
        ]

        ALGEBRA_OPERATORS.map do |opt|
            @env.push [opt, lambda{ |*operands| operands.inject(opt) }]
        end
        COMPARISION.map do |opt|
            aux = lambda do |opt|
                lambda{ |*args| args.each_cons(2).all? {|x, y| x.method(opt).call(y)} }
            end
            if opt == :'=' then @env.push [:'=' , aux.(:==)]
            else @env.push [opt , aux.(opt)]
            end
        end
    end

    def eval_expressions(exps, env=@env)
        results = exps.map { |one_exp| eval(one_exp, env) }
        results[-1]
    end

    def eval(exp, env=@env)
        def lookup_env(env, var)
            error_no_var = "undefined: %s !" % var
            var_val = env.assoc var

            if var_val.nil?
                raise error_no_var
            elsif var_val[1] == UNASSIGNED_VAL
                raise "the unassigned value should not be access."
            else
                return var_val[1]
            end
        end

        if exp.is_a? Numeric
            exp # is a number(integer and float) return itself
        elsif exp.is_a? String
            exp
        elsif exp == :null
            exp
        elsif exp == UNASSIGNED_VAL
            exp
        elsif exp.is_a? Symbol
            lookup_env(env, exp) # look up var and return its value
        elsif exp[0] == :define
            _, var, value_exp = exp
            if var.is_a? Array # function define. transform lambda
                # value_exp is the body of the lambda
                fun_name = var[0]
                parameter_names = var[1..-1]
                env[0..-1] = [[fun_name , eval([:lambda, parameter_names, value_exp], env)]] + env
            else # variable
                value = eval( value_exp, env )
                env[0..-1] = [[var , value]] + env
            end
        elsif exp[0] == :set!
            _, var, new_val_exp = exp
            var_val = env.assoc var
            if var_val.nil?
                raise "set! assignment disallowed. undefined: %s !" %  var
            else
                var_val[1] = eval( new_val_exp, env )
            end
        elsif exp[0] == :if
            _, test_exp, then_exp, else_exp = exp
            if eval(test_exp, env) == false
                eval( else_exp, env )
            else # other than false(#f)
                eval( then_exp, env)
            end
        elsif exp[0] == :lambda
            _, parameter_names, fun_body = exp
            Closure.new(parameter_names, fun_body, env)
            # eval([:closure, false, parameter_names, fun_body], env) # return closure( no function name )
        elsif exp[0] == :let
            _, bindings, body = exp
            vars = [];vals = []
            bindings.each do |bind|
                vars.push(bind[0])
                vals.push(bind[1])
            end
            eval([[:lambda, vars, body]] + vals, env)
        elsif exp[0] == :letrec
            _, bindings, body = exp
            vars = []; val_exprs =[]
            bindings.each do |bind|
                vars.push(bind[0])
                val_exprs.push(bind[1]) # no eval now
            end
            eval([:let, vars.map{|var| [var, UNASSIGNED_VAL]}, # all vars' values are #f temp.
                        [:begin].+(vars.map.with_index{|var,idx| [:set!, var, val_exprs[idx]]})
                               .push(body)], env)
        else
            operator = eval(exp[0], env) # first thing of s-expression sequence.
            operands = exp[1..-1].map {|sub_exp| eval(sub_exp, env) } # the rest things of sequence

            if operator.is_a? Closure # compounded procedures(user-defined)# extends environment with parameters and their actual arguments applied.

                env_fn = operator.parameters.zip(operands) + operator.env
                body = operator.body
                eval(body, env_fn)
            else # primitive operators
                operator.call *operands
            end
        end
    end

    def execute(str)
        eval_expressions(parse(str))
    end

    def repl(options={})
        # default values
        prompt = options[:prompt] ||= "RacketOnRb >>"
        output_prompt = options[:output_prompt] ||= "=>"
        will_raise = options[:will_raise] ||= false

        while true
            print prompt
            code = gets

            begin
                ast = parse(code)
                result = eval_expressions(ast)
                puts output_prompt + result.to_s
            rescue Exception => e
                puts e
            end
        end
    end
end
