pos(b::Buffer)  = b.cursor.pos
poss(b::Buffer) = "$(pos(b))"
y(b::Buffer)    = b.cursor.pos[1]
ys(b::Buffer)   = "$(y(b))"
x(b::Buffer)    = b.cursor.pos[2]
xs(b::Buffer)   = "$(x(b))"

top(b::Buffer) = parse(Int64, b.state[:top])
bottom(b::Buffer) = parse(Int64, b.state[:bottom])
function height(b::Buffer)
    length(b.text)
end
function line(b::Buffer, line::Integer)
    b.text[line]
end
line(b::Buffer) = line(b, y(b))
function setline(b::Buffer, line::Integer, s::String)
    b.text[line] = s
end
setline(b::Buffer, s::String) = setline(b, y(b), s)

function width(b::Buffer)
    length(line(b))
end

function escape(b::Buffer)
    setmode(b, normal_mode)
    clamp(b)
end

isint(c::Integer) = 47 < c < 58
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
    resize!(b.args,0)
end

function deleteat(b::Buffer, pos)
    pr = b.text[pos[1]]
    n = parse_n(b)
    b.text[pos[1]] = string(pr[1:pos[2]-1], pr[pos[2]+n:end])
end

function paste(b::Buffer, pos, s::String)
    setline(b, pos[1], line(b, pos[1])[1:pos[2]-1]*s*line(b, pos[1])[pos[2]:end])
end
paste(b::Buffer, s) = paste(b, pos(b), s)
pastea(b::Buffer, s) = paste(b, pos(b)+[0,1], s)

function joinlines(b::Buffer, interval::Tuple, delimiter=" ")
    #settext is slow in this context, we can make this more efficient
    settext(b, [b.text[1:interval[1]-1]...; 
                join(b.text[interval[1]:min(end, interval[2])]);
                b.text[interval[2]+1:end]...])
end

function splitlines(b::Buffer, pos)
    settext(b, [b.text[1:pos[1]-1]...; 
                [b.text[pos[1]][1:pos[2]-1], b.text[pos[1]][pos[2]:end]];
                b.text[pos[1]+1:end]...])
end

function delete_lines(b::Buffer, interval::Tuple)
    #settext is slow in this context, we can make this more efficient
    settext(b, [b.text[1:interval[1]-1]...; 
                b.text[interval[2]+1:end]...])
end

function replay(b::Buffer, actions::String, n=1)
    for i in 1:n
        for c in actions
            handle_raw(b, c)
        end
    end
end
replay(b::Buffer, s::Array{Char, 1}, n=1) = replay(b, join(s), n)

function nmap(c::Char, s::String)
    normal_actions[c]= b -> replay(b, s)
end

function quit(b::Buffer)
    b.state[:running] = "false"
end
