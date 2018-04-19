function addchar(b::Buffer, c, s::Symbol)
    is = Symbol(s, :_insert)
    p = max(1, parse(b.state[is]))
    b.state[s] = string(b.state[s][1:p-1], c, b.state[s][p:end])
    b.state[is] = "$(p+1)"
end

function rmchar(b::Buffer, s::Symbol)
    if length(b.state[s]) >= 1
        is = Symbol(s, :_insert)
        p = max(1, parse(b.state[is]))
        b.state[s] = string(b.state[s][1:p-2], b.state[s][p:end])
        b.state[is] = "$(p-1)"
    else
        escape(b)
    end
end

function step_dir(b::Buffer, s::Symbol, dir=1)
    is = Symbol(s, :_insert)
    p = Base.clamp(parse(b.state[is])+dir, 1, length(b.state[s])+1)
    self.state[is] = "$p"
end
function step_endpt(b::Buffer, s::Symbol, pt=1)
    self.state[Symbol(s, :_insert)] = (pt==1 ? "1" : "$(length(b.state[s])+1)")
end

function previous_call(b::Buffer, s::Symbol)
    calls = split(b.state[Symbol(s, :_history)], '\n')
    ncalls = parse(b.state[Symbol(s, :_n)])
    nextnum = min(parse(b.state[Symbol(s, :_ind)])-1, ncalls)
    if 1<=nextnum<=ncalls
        b.state[s] = calls[Base.clamp(nextnum, 1, ncalls)]
    else
        b.state[s] = ""
    end
    b.state[Symbol(s, :_ind)] = "$(Base.clamp(nextnum, 1, ncalls))"
end
function next_call(b::Buffer, s::Symbol)
    calls = split(b.state[Symbol(s, :_history)], '\n')
    ncalls = parse(b.state[Symbol(s, :_n)])
    nextnum = min(parse(b.state[Symbol(s, :_ind)])+1, ncalls)
    if 1<=nextnum<=ncalls
        b.state[s] = calls[Base.clamp(nextnum, 1, ncalls)]
    else
        b.state[s] = ""
    end
    b.state[Symbol(s, :_ind)] = "$(Base.clamp(nextnum, 1, ncalls))"
end

#Hardcoded chars should be moved elsewhere at some point
function exec_fn(c, s::Symbol, evalfn, reset=true)
    function fn(b::Buffer)
        if c=='\e'
            if reset
                b.state[s] = ""
            end
            escape(b)
            b.state[Symbol(s, :_ind)] = b.state[Symbol(s, :_n)]
            b.state[Symbol(s, :_insert)] = "1"
        elseif c=='\x7f'
            rmchar(b, s)
        elseif c=='\r'
            evalfn(b)
            b.state[Symbol(s, :_insert)] = "1"
        elseif c=='\v'
            previous_call(b, s)
        elseif c=='\n'
            next_call(b, s)
        elseif c=='\x06'
            step_dir(b, s, 1)
        elseif c=='\x02'
            step_dir(b, s, -1)
        elseif c=='\x01'
            step_endpt(b, s, 1)
        elseif c=='\x05'
            step_endpt(b, s, -1)
        else
            addchar(b, c, s)
        end
    end
end

function init_call(d::Dict, s::Symbol)
    d[s] = ""
    d[Symbol(s,:_insert)] = "1"
    d[Symbol(s,:_n)] = "1"
    d[Symbol(s,:_ind)] = "1"
    d[Symbol(s,:_history)] = ""
end
init_call(b::Buffer, s::Symbol) = init_call(b.state, s)
