function addchar(b::Buffer, c, s::Symbol)
    b.state[s] = string(b.state[s], c)
end
function rmchar(b::Buffer, s::Symbol)
    if length(b.state[s]) >= 1
        b.state[s] = b.state[s][1:end-1]
    else
        escape(b)
    end
end

function previous_call(b::Buffer, s::Symbol)
    calls = split(b.state[Symbol(s, :history)], '\n')
    b.state[s] = calls[max(1,parse(b.state[Symbol(s, :_ind)]))] #This stuff isn't super
    b.state[Symbol(s, :ind)] = "$(parse(b.state[Symbol(s, :_ind)])-1)"
end

function exec_fn(c, s::Symbol, evalfn, reset=true)
    function fn(b::Buffer)
        if c=='\e'
            if reset
                b.state[s] = ""
            end
            escape(b)
        elseif c=='\x7f'
            rmchar(b, s)
        elseif c=='\r'
            evalfn(b)
        elseif c=='\v'
            previous_call(b, s)
        else 
            addchar(b, c, s)
        end
    end
end

function init_call(d::Dict, s::Symbol)
    d[s] = ""
    d[Symbol(s,:_n)] = "0"
    d[Symbol(s,:_ind)] = "0"
    d[Symbol(s,:_history)] = ""
end
init_call(b::Buffer, s::Symbol) = init_call(b.state, s)
