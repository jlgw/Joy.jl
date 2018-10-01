struct Cursor
    pos
end

struct Action
    getter
    permitted
end

Base.getindex(a::Action, n) = a.getter(n)

struct Mode
    signature::String
    actions::Action
end

function Mode(signature::String, d::Dict)
    function f(x)
        if in(x,keys(d))
            return d[x]
        else
            return y->push!(y.args, x)
        end
    end
    Mode(signature, Action(f, x->in(x,keys(d))))
end

struct Buffer
    text::Array{String,1}
    undo::Array{String,1} #Given time, this should be replaced with multi-level undo with diffs
    redo::Array{String,1}
    cursor::Cursor
    mode::Array{Mode,1}
    state::Dict{Symbol, String}
    registers::Dict{Char, String}
    args::Array{Char,1}
end

function settext(b::Buffer, text::Array{String,1})
    resize!(b.text, length(text))
    b.text .= text
end

#patch
function settext(b::Buffer, text::Array{AbstractString,1})
    resize!(b.text, length(text))
    b.text .= text
end

function setundo(b::Buffer, text)
    b.state[:undo] = "undo"
    resize!(b.undo, length(text))
    b.undo .= text
end
setundo(b::Buffer) = setundo(b, b.text)

function setredo(b::Buffer, text)
    b.state[:undo] = "redo"
    resize!(b.redo, length(text))
    b.redo .= text
end
setredo(b::Buffer) = setredo(b, b.text)

mode(b::Buffer) = b.mode[1]
function setmode(b::Buffer, m::Mode)
    if m!=normal_mode
        setundo(b)
    end
    b.mode[1] = m
end

function Base.show(io::IO, b::Buffer)
    print(io, "Buffer: ")
    print(io, "$(length(b.text)) lines ")
    print(io, "$(mode(b).signature) ")
    print(io, "cursor position $(b.cursor.pos[1]),$(b.cursor.pos[2])")
end

function clear_screen()
    write(STDOUT, "\e[2J");
end

function move_sys_cursor(row,col)
    write(STDOUT, "\e[$(row);$(col)H");
end

function render_line(b::Buffer, l::String)
    s = Base.clamp(left(b), 1, max(1,length(l)))
    f = Base.clamp(right(b), 1, length(l))
    if length(l)>=1
        displ = l[chr2ind(l, s):chr2ind(l, f)]
    else
        displ = ""
    end
    if :syntax in keys(b.state) && b.state[:syntax] == "true"
        displ = highlight(displ)
    end
    write(STDOUT, "$displ\n")
end

function render(b::Buffer)
    resize(b)
    clear_screen()
    move_sys_cursor(1,1)
    #Change parsing to something else
    for l in b.text[max(1,top(b)):min(end, bottom(b))]
        render_line(b, l)
    end
    #Change hardcoded stuff
    tildes = max(0, (bottom(b)-top(b)+1)-length(b.text))
    write(STDOUT, string("~\n"^tildes, b.state[:console]))
end
