pos(b::Buffer)  = b.cursor.pos
poss(b::Buffer) = "$(pos(b))"
y(b::Buffer)    = b.cursor.pos[1]
ys(b::Buffer)   = "$(y(b))"
x(b::Buffer)    = b.cursor.pos[2]
xs(b::Buffer)   = "$(x(b))"
xu(b::Buffer)   = c2ic(line(b), x(b))
posu(b::Buffer) = [y(b), xu(b)]

function c2ic(s::String, n::Integer)
    if n<1
        return 0
    elseif n>length(s)
        return sizeof(s)+1
    else
        return chr2ind(s, n)
    end
end

function after(b::Buffer)
    if mode(b)==normal_mode
        after_normal(b)
    elseif mode(b)==insert_mode
        after_insert(b)
    elseif mode(b)==delete_mode
        after_delete(b)
    elseif mode(b)==yank_mode
        after_yank(b)
    end
end

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

function clamp(b::Buffer, edgecase=false)
    b.cursor.pos[1] = Base.clamp(y(b), 1, height(b))
    if width(b) > 0
        b.cursor.pos[2] = Base.clamp(x(b), 1, width(b)+edgecase)
    else
        b.cursor.pos[2] = 0
    end
end

function findsymbol(s::String, c::Char, n::Integer)
    p = findn([s...] .== c)
    if n>length(p)
        return 0
    else
        return p[n]
    end
end
function findsymbol(b::Buffer, c::Char, pos, n::Integer)
    pos[2] + findsymbol(line(b,pos[1])[pos[2]+1:end], c, n)
end
findsymbol(b::Buffer, c::Char, n::Integer) = findsymbol(b, c, posu(b), n)
findsymbol(b::Buffer, c::Char) = findsymbol(b, c, parse_n(b))

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
function parse_n(b::Buffer) 
    parse_n(b.args)
end

function clear_arg(b::Buffer)
    resize!(b.args,0)
end

function deleteat(b::Buffer, pos, n)
    pr = b.text[pos[1]]
    b.text[pos[1]] = string(pr[1:min(c2ic(pr, pos[2])-1, end)],
                            pr[max(1, c2ic(pr, pos[2]+n)):end])
end

function paste_single(b::Buffer, pos, s::String)
    setline(b, 
            pos[1], 
            string((ln -> ln[1:min(c2ic(ln, pos[2])-1, end)])(line(b, pos[1])),
                   s,
                   (ln -> ln[max(1, c2ic(ln, pos[2])):end])(line(b, pos[1])),
                  )
           )
end
function paste(b::Buffer, pos, s::String)
    s_array = split(s, '\n')
    if length(s_array) == 1
        paste_single(b::Buffer, pos, s)
    else
        settext(b, [b.text[1:pos[1]-1];
                    [string(
                            (t->t[1:c2ic(t, pos[2])])(b.text[pos[1]]),
                            s_array[1])];
                    s_array[2:end-1];
                    [string(
                            s_array[end],
                            (t->t[c2ic(t, pos[2]+1):end])(b.text[pos[1]]))];
                    b.text[pos[1]+1:end]
                   ])
    end
end
function paste(b::Buffer, pos, c::Char)
    if c in keys(b.registers)
        paste(b, pos, b.registers[c])
    else
        self.state[:log] = "Register $c empty"
    end
end
paste(b::Buffer, s) = paste(b, pos(b), s)
pastea(b::Buffer, s) = paste(b, pos(b)+[0, 1], s)

function joinlines(b::Buffer, interval::Tuple, delimiter=" ")
    #settext is slow in this context, we can make this more efficient
    settext(b, [b.text[1:interval[1]-1];
                [join(b.text[interval[1]:min(end, interval[2])])];
                b.text[interval[2]+1:end]])
end

function splitlines(b::Buffer, pos)
    settext(b, [b.text[1:pos[1]-1]; 
                [b.text[pos[1]][1:pos[2]-1], b.text[pos[1]][max(1, pos[2]):end]];
                b.text[pos[1]+1:end]])
end

function delete_lines(b::Buffer, interval::Tuple)
    #settext is slow in this context, we can make this more efficient
    settext(b, [b.text[1:interval[1]-1]; 
                b.text[interval[2]+1:end]])
end

function order_pos(pos1, pos2)
    if (pos1[1] < pos2[1]) || ((pos1[1] == pos2[1]) && (pos1[2] < pos2[2]))
        return (pos1, pos2)
    else
        return (pos2, pos1)
    end
end

#Caution: Doesn't work exactly like vim (line delete etc)
function delete_between(b::Buffer, pos1, pos2, reg='"')
    #no unicode support for this right now
    sp, ep = order_pos(pos1, pos2)
    yank_between(b::Buffer, sp, ep, reg)
    settext(b, [b.text[1:sp[1]-1];
                [string(b.text[sp[1]][1:sp[2]-1], b.text[ep[1]][ep[2]:end])];
                b.text[ep[1]+1:end]])
    b.cursor.pos .= sp
end

function yank_between(b::Buffer, pos1, pos2, reg='"')
    sp, ep = order_pos(pos1, pos2)
    if sp[1] == ep[1]
        b.registers[reg] = string(b.text[sp[1]][sp[2]:ep[2]-1])
    else
        b.registers[reg] = join([b.text[sp[1]][sp[2]:end];
                                b.text[sp[1]+1:ep[1]-1];
                                b.text[ep[1]][1:ep[2]-1]], '\n')
    end
end
function replay(b::Buffer, actions::String, n=1)
    for i in 1:n
        for c in actions
            handle_raw(b, c)
        end
    end
end
replay(b::Buffer, s::Array{Char, 1}, n=1) = replay(b, join(s), n)

source(b::Buffer) = evalcmd(b, join(b.text, '\n'))

function nmap(c::Char, f)
    normal_actions[c] = f
end
function nmap(c::Char, s::String)
    normal_actions[c] = b -> replay(b, s)
end

function quit(b::Buffer)
    b.state[:running] = "false"
end
