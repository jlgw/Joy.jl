
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

function handle_raw(b::Buffer, c::Char)
    b.state[:actions] = string(b.state[:actions], c)
    mode(b).actions[c](b)
    xp = (x(b)>0 ? xs(b) : "0-1")
    b.state[:console] = string(mode(b).signature,
                               " ",ys(b), ",", xp, " ",
                               join(b.args, ""), "\n", b.state[:log])
end
