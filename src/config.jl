
function init(text)
    cursor = Cursor([1,1])
    state = Dict(:actions => "")
    state[:running] = "false"
    state[:console] = ""
    state[:register] = "\""
    init_call(state, :command)
    init_call(state, :search)
    state[:log] = ""
    state[:top] = "1"
    state[:bottom] = "19"
    state[:left] = "0"
    state[:right] = "80"
    state[:syntax] = "true"
    state[:undo] = ""
    registers = Dict{Char, String}()
    buffer = Buffer(text,
                    [""],
                    [""],
                    cursor, 
                    [normal_mode, normal_mode], 
                    state, 
                    registers, 
                    Array{Char, 1}())
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
