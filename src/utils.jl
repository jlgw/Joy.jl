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
    if height(b) == 0
        settext(b, [""])
    end
    b.cursor.pos[1] = Base.clamp(y(b), 1, height(b))
    if width(b) > 0 || edgecase
        b.cursor.pos[2] = Base.clamp(x(b), 1, width(b)+edgecase)
    else
        b.cursor.pos[2] = 0
    end
end

function clamp_range(r::UnitRange, low::Number, high::Number)
    Base.clamp(r.start, low, high):Base.clamp(r.stop, low, high)
end
function clamp_range(r::StepRange, low::Number, high::Number)
    Base.clamp(r.start, low, high):step(r):Base.clamp(r.stop, low, high)
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

function paste_lines(b::Buffer, ln, 
                     s::Array{T,1} where T <: Union{String, SubString{String}})
    settext(b, [b.text[1:ln-1];
                s;
                b.text[ln:end]])
end
paste_lines(b::Buffer, ln, s::String) = paste_lines(b, ln, split(s, '\n')) 
function paste_lines(b::Buffer, s::Union{Array{String, 1}, String})
    paste_lines(b, y(b), s)
end
function pastea_lines(b::Buffer, s::String)
    paste(lines, b, y(b)+1, s)
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
    if s[1] == '\e' #Line copies add an escape symbol before the text
        b.state[:log] = "$pos"
        paste_lines(b, pos[1], s[2:end])
    else
        s_array = split(s, '\n')
        if length(s_array) == 1
            paste_single(b::Buffer, pos, s)
        else
            ln1 = string((t->unirange(t, 1:pos[2]))(b.text[pos[1]]), s_array[1])
            ln2 = string(s_array[end], (t->unirange(t, pos[2]+1:length(t)))(b.text[pos[1]]))
            settext(b, [b.text[1:pos[1]-1];
                        ln1;
                        s_array[2:end-1];
                        ln2;
                        b.text[pos[1]+1:end]
                       ])
        end
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
function pastea(b::Buffer, pos, s::String)
    if s[1] =='\e'
        paste(b, pos+[1, 0], s)
    else
        paste(b, pos+[0, 1], s)
    end
end
function pastea(b::Buffer, pos, c::Char)
    if c in keys(b.registers)
        pastea(b, pos, b.registers[c])
    else
        self.state[:log] = "Register $c empty"
    end
end
pastea(b::Buffer, s) = pastea(b::Buffer, pos(b), s)

function join_lines(b::Buffer, range::Range, delimiter=" ")
    range = clamp_range(range, 1, height(b))
    jl = join(b.text[range], delimiter)
    deleteat!(b.text, range[2:end])
    b.text[range[1]] = jl
end
function join_lines(b::Buffer, interval::Tuple, delimiter=" ")
    join_lines(b, interval[1]:interval[2], delimiter)
end

function splitlines(b::Buffer, pos)
    nl1 = unirange(b.text[pos[1]], 1:pos[2]-1)
    nl2 = unirange(b.text[pos[1]], max(1, pos[2]):length(b.text[pos[1]]))
    b.text[pos[1]] = nl1
    insert!(b.text, pos[1]+1, nl2)
end

function delete_lines(b::Buffer, range::Range)
    range = clamp_range(range, 1, height(b))
    yank_lines(b, range)
    deleteat!(b.text, range)
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
    yank_between(b, sp, ep, reg)
    nl = string(unirange(b.text[sp[1]], 1:sp[2]-1), 
                unirange(b.text[ep[1]], ep[2]:length(b.text[ep[1]])))
    deleteat!(b.text, sp[1]:ep[1]-1)
    b.text[sp[1]] = nl
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

function undo(b::Buffer)
    if b.state[:undo]=="undo"
        setredo(b, b.text)
        settext(b, b.undo)
    else
        b.state[:log] = "Multiple undos not supported"
    end
    after(b)
end
function redo(b::Buffer)
    if b.state[:undo]=="redo"
        settext(b, b.redo)
    else
        b.state[:log] = "Already at latest state"
    end
    after(b)
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

function reconfigure(b::Buffer)
    pkdir = Pkg.Dir.path("Joy")
    files = ["include(\"$pkdir/src/base.jl\")",
     "include(\"$pkdir/src/string_utils.jl\")",
     "include(\"$pkdir/src/utils.jl\")",
     "include(\"$pkdir/src/syntax.jl\")",
     "include(\"$pkdir/src/words.jl\")",
     "include(\"$pkdir/src/modes/movements.jl\")",
     "include(\"$pkdir/src/modes/normal.jl\")",
     "include(\"$pkdir/src/modes/insert.jl\")",
     "include(\"$pkdir/src/modes/calls.jl\")",
     "include(\"$pkdir/src/modes/command.jl\")",
     "include(\"$pkdir/src/modes/search.jl\")",
     "include(\"$pkdir/src/config.jl\")",
     "include(\"$pkdir/src/editor.jl\")",
    ]
    (f -> evalcmd(b, f)).(files)
end


function quit(b::Buffer)
    b.state[:running] = "false"
end
