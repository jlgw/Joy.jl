
function init(text)
    #t1 = time()
    cursor = Cursor([1,1])
    state = Dict()
    state[:actions] = []
    state[:running] = false 
    state[:console] = ""
    state[:command] = ""
    state[:macros] = Dict()
    state[:log] = ""
    state[:top] = 1
    state[:bottom] = 30
    #t2 = time()
    term = Base.REPL.Terminals.TTYTerminal(get(ENV, "TERM", "dumb"), STDIN, STDOUT, STDERR)
    #t3 = time()
    Base.REPL.raw!(term, true)
    buffer = Buffer(term, text, cursor, normal_mode, state, [])
    #t4 = time()
    #buffer.state[:timelog] = "t2-t1: $(t2-t1), t3-t2: $(t3-t2), t4-t3: $(t4-t3)"
    return buffer
end

function clamp(b::Buffer, edgecase=false)
    y,x = b.cursor.pos
    y = b.cursor.pos[1] = Base.clamp(y, 1, length(b.text))
    x = b.cursor.pos[2] = Base.clamp(x, 1, length(b.text[y])+edgecase)
end

function handle_raw(b::Buffer, c::Char)
    push!(b.state[:actions], c)
    b.mode.actions[c](b)
    b.state[:console] = string(b.mode.signature,
                               " $(b.cursor.pos[1]),$(b.cursor.pos[2]) ",
                               join(b.args, ""), "\n", b.state[:log])
end
