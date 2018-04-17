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
    cursor::Cursor
    mode::Array{Mode,1}
    state::Dict{Symbol, String}
    registers::Dict{Char, String}
    args::Array{Char,1}
end

function settext(b::Buffer, text)
    resize!(b.text, length(text))
    b.text .= text
end

mode(b::Buffer) = b.mode[1]
function setmode(b::Buffer, m::Mode)
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
    write(STDOUT, "$l \n")
end
function render(b::Buffer)
    clear_screen()
    #Change parsing to something else
    for l in b.text[top(b):min(end, bottom(b))]
        render_line(b, l)
    end
    #Change hardcoded stuff
    write(STDOUT, string("~\n~\n", b.state[:console], "  \n"))
end
