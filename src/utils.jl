function getheight(b::Buffer)
    length(b.text)
end
function getline(b::Buffer)
    b.text[b.cursor.pos[1]]
end
function setline(b::Buffer, s::String)
    b.text[b.cursor.pos[1]] = s
end
function getwidth(b::Buffer)
    length(getline(b))
end

function escape(b::Buffer)
    b.mode = normal_mode
    clamp(b)
end

isint(c::Integer) = 48 < c < 57
function parse_n(args::Array)
    n = length(args)
    il = args[indexin([false], isint.(Int.(args)))[1]+1:end]
    if !isempty(il)
        parse(Int, join(il))
    else
        return 1
    end
end
parse_n(b::Buffer) = parse_n(b.args)

function clear_arg(b::Buffer)
    b.args = []
end

function deleteat(b::Buffer, pos)
    pr = b.text[pos[1]]
    n = parse_n(b)
    b.text[pos[1]] = string(pr[1:pos[2]-1], pr[pos[2]+n:end])
end

function joinlines(b::Buffer, interval::Tuple, delimiter=" ")
    b.text = [b.text[1:interval[1]-1]...; 
                   join(b.text[interval[1]:interval[2]]);
                   b.text[interval[2]+1:end]...]
end

function splitlines(b::Buffer, pos)
    b.text = [b.text[1:pos[1]-1]...; 
                   [b.text[pos[1]][1:pos[2]-1], b.text[pos[1]][pos[2]:end]];
                   b.text[pos[1]+1:end]...]
end

function replay(b::Buffer, actions::String)
    for c in actions
        handle_raw(b, c)
    end
end
replay(b::Buffer, s::Array{Char, 1}) = replay(b, join(s))

function nmap(c::Char, s::String)
    normal_actions[c]= b -> replay(b, s)
end

function quit(b::Buffer)
    b.state[:running] = false
end
