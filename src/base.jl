mutable struct Cursor
    pos
end

mutable struct Action
    getter
    permitted
end

Base.getindex(a::Action, n) = a.getter(n)

mutable struct Mode
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

mutable struct Buffer
    term::Base.Terminals.TextTerminal
    text
    cursor::Cursor
    mode::Mode
    state::Dict
    args
end

function Base.show(io::IO, b::Buffer)
    print(io, "Buffer: ")
    print(io, "$(length(b.text)) lines ")
    print(io, "$(b.mode.signature) ")
    print(io, "cursor position $(b.cursor.pos[1]),$(b.cursor.pos[2])")
end

function clear_screen()
    write(STDOUT, "\e[2J");
end

function move_sys_cursor(row,col)
    write(STDOUT, "\e[$(row);$(col)H");
end

function render(b::Buffer)
    clear_screen()
    for l in b.text[b.state[:top]:min(end, b.state[:bottom])]
        write(STDOUT, "$l  \n")
    end
    #Change hardcoded stuff
    write(STDOUT, string("~\n~\n~\n", b.state[:console], "  \n"))
end
