pos(b::Buffer)  = b.cursor.pos
poss(b::Buffer) = "$(pos(b))"
y(b::Buffer)    = b.cursor.pos[1]
ys(b::Buffer)   = "$(y(b))"
x(b::Buffer)    = b.cursor.pos[2]
xs(b::Buffer)   = "$(x(b))"
xu(b::Buffer)   = chr2ind(line(b), x(b))
posu(b::Buffer) = [y(b), xu(b)]

function after(b::Buffer)
    if mode(b)==normal_mode
        after_normal(b)
    elseif mode(b)==insert_mode
        after_insert(b)
    elseif mode(b)==delete_mode
        after_delete(b)
    elseif mode(b)==yank_mode
        after_yank(b)
    elseif mode(b)==find_mode
        after_find(b)
    elseif mode(b)==search_mode
        after_search(b)
    elseif mode(b)==go_mode
        after_go(b)
    elseif mode(b)==replace_mode
        #after_replace(b)
    end
end

top(b::Buffer) = parse(Int64, b.state[:top])
bottom(b::Buffer) = parse(Int64, b.state[:bottom])
left(b::Buffer) = parse(Int64, b.state[:left])
right(b::Buffer) = parse(Int64, b.state[:right])
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
    clamp!(b)
end

function clamp!(b::Buffer, edgecase=false)
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

# Should be cleaned up
function set_boundaries(b::Buffer, ind::Integer, first::Symbol, last::Symbol)
    #remove parsing from here
    f, l = parse.([b.state[first], b.state[last]])
    if f > ind
        d = ind - f
    elseif l < ind
        d = ind - l
    else
        d = 0
    end
    b.state[first], b.state[last] = string.([f, l]+d)
end
function set_boundaries(b::Buffer)
    set_boundaries(b, y(b), :top, :bottom)
    df = right(b)-left(b)
    b.state[:left], b.state[:right] = string.([max(1, x(b)-df), max(df+1, x(b))])
end
function resize(b::Buffer, height, width)
    b.state[:top], b.state[:bottom] = string.([top(b), top(b) + height])
    b.state[:left], b.state[:right] = string.([left(b), left(b) + width])
end

function resize(b::Buffer)
    try
        term = Base.REPL.Terminals.TTYTerminal(get(ENV, "TERM", "dumb"), STDIN, STDOUT, STDERR)
        c = Base.Terminals.width(term)
        r = Base.Terminals.height(term)
        resize(b, r-3, c-1)
    catch z
        b.state[:log] = "$z"
    end
end

function clear_arg(b::Buffer)
    resize!(b.args,0)
end

function deleteat(b::Buffer, pos, n)
    pr = b.text[pos[1]]
    b.text[pos[1]] = string(unirange(pr, 1:pos[2]-1), unirange(pr, pos[2]+n:length(pr)))
end

function paste_single(b::Buffer, pos, s::String)
    setline(b, 
            pos[1], 
            string((ln -> unirange(ln, 1:pos[2]-1))(line(b, pos[1])),
                   s,
                   (ln -> unirange(ln, pos[2]:length(ln)))(line(b, pos[1])),
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
                            (t->unirange(t, 1:pos[2]))(b.text[pos[1]]),
                            s_array[1])];
                    s_array[2:end-1];
                    [string(
                            s_array[end],
                            (t->unirange(t, pos[2]+1:length(t)))(b.text[pos[1]]))];
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
                [unirange(b.text[pos[1]], 1:pos[2]-1), 
                 unirange(b.text[pos[1]], max(1, pos[2]):length(b.text[pos[1]]))];
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
                [string(unirange(b.text[sp[1]], 1:sp[2]-1), 
                        unirange(b.text[ep[1]], ep[2]:length(b.text[ep[1]])))];
                b.text[ep[1]+1:end]])
    b.cursor.pos .= sp
end

function yank_between(b::Buffer, pos1, pos2, reg='"')
    sp, ep = order_pos(pos1, pos2)
    if sp[1] == ep[1]
        b.registers[reg] = string(b.text[sp[1]][sp[2]:ep[2]-1])
    else
        b.registers[reg] = join([unirange(b.text[sp[1]], sp[2]:length(b.text[sp[1]]));
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

function reconfigure(b)
    pkdir = Pkg.Dir.path("Joy")
    files = ["include(\"$pkdir/src/base.jl\")",
     "include(\"$pkdir/src/utils.jl\")",
     "include(\"$pkdir/src/words.jl\")",
     "include(\"$pkdir/src/modes/movements.jl\")",
     "include(\"$pkdir/src/modes/normal.jl\")",
     "include(\"$pkdir/src/modes/insert.jl\")",
     "include(\"$pkdir/src/modes/command.jl\")",
     "include(\"$pkdir/src/config.jl\")",
     "include(\"$pkdir/src/editor.jl\")",
    ]
    (f -> evalcmd(b, f)).(files)
end


function quit(b::Buffer)
    b.state[:running] = "false"
end
