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
    b.state[is] = "$p"
end
function step_endpt(b::Buffer, s::Symbol, pt=1)
    b.state[Symbol(s, :_insert)] = (pt==1 ? "1" : "$(length(b.state[s])+1)")
end

function compl(b::Buffer, s::Symbol)
    #we do need unicode here, we'll run into issues (crashing) if we run latex compl.
    is = Symbol(s, :_insert)
    p = max(1, parse(b.state[is]))
    cmp = Base.REPLCompletions.completions(b.state[s], min(p, length(b.state[s])))
    rng = cmp[2]
    alts = cmp[1]
    if 1 <= length(alts) < 10
        if length(alts) == 1
            mstr = alts[1]
        else
            fn(k) = all((i->i[k]).(alts) .== alts[1][k])
            mn = minimum(length, alts)
            f = findfirst(.!(fn.(1:mn)))
            mstr = alts[1][1:(f == 0 ? mn : f-1)]
            b.state[:dbg] = repr(fn.(1:mn))
            b.state[:mstr] = repr(mstr)
            b.state[:log] = string(join(alts, "\t"), "\n")
        end
        b.state[s] = string(b.state[s][1:rng[1]-1],
                            mstr,
                            b.state[s][(rng[end]+1):end])
        b.state[is] = "$(p+length(mstr)-length(rng))"
    elseif 10 <= length(alts) < 100
        b.state[:log] = string(join(alts, "\t"), "\n")
    end
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

#Should be moved elsewhere at some point
function reset_call(b::Buffer, s::Symbol, r::Bool)
    r && (b.state[s] = "")
    escape(b)
    b.state[Symbol(s, :_ind)] = b.state[Symbol(s, :_n)]
    b.state[Symbol(s, :_insert)] = "1"
end

const call_actions = Dict(
                    '\v' => previous_call,
                    '\n' => next_call,
                    '\x06' => (b,s) -> step_dir(b, s, 1),
                    '\x02' => (b,s) -> step_dir(b, s, -1),
                    '\x01' => (b,s) -> step_endpt(b, s, 1),
                    '\x05' => (b,s) -> step_endpt(b, s, -1),
                    '\t' => compl,
                   )
function exec_fn(c, s::Symbol, evalfn, reset=true)
    function fn(b::Buffer)
        if c=='\e'
            reset_call(b, s, reset)
        elseif c=='\x7f'
            rmchar(b, s)
        elseif c=='\r'
            evalfn(b)
            b.state[Symbol(s, :_insert)] = "1"
        elseif c in keys(call_actions)
            call_actions[c](b,s)
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
