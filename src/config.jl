
function init(text)
    cursor = Cursor([1,1])
    state = Dict(:actions => "")
    #state[:actions] = ""
    state[:running] = "false"
    state[:console] = ""
    state[:command] = ""
    state[:log] = ""
    state[:top] = "1"
    state[:bottom] = "19"
    registers = Dict{Char, String}()
    term = Base.REPL.Terminals.TTYTerminal(get(ENV, "TERM", "dumb"), STDIN, STDOUT, STDERR)
    Base.REPL.raw!(term, true)
    buffer = Buffer(term, text, cursor, [normal_mode], state, registers, [])
    return buffer
end

function clamp(b::Buffer, edgecase=false)
    y,x = b.cursor.pos
    y = b.cursor.pos[1] = Base.clamp(y, 1, length(b.text))
    x = b.cursor.pos[2] = Base.clamp(x, 1, length(b.text[y])+edgecase)
end

function handle_raw(b::Buffer, c::Char)
    b.state[:actions] = b.state[:actions]*c
    mode(b).actions[c](b)
    b.state[:console] = string(mode(b).signature,
                               " $(b.cursor.pos[1]),$(b.cursor.pos[2]) ",
                               join(b.args, ""), "\n", b.state[:log])
end
