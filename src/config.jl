
function init(text)
    cursor = Cursor([1,1])
    state = Dict(:actions => "")
    state[:running] = "false"
    state[:console] = ""
    state[:register] = "\""
    state[:command] = ""
    state[:cmdhistory] = ""
    state[:cmd] = "0"
    state[:cmds] = "0"
    state[:search] = ""
    state[:searchhistory] = ""
    state[:searchind] = "0"
    state[:searches] = "0"
    state[:log] = ""
    state[:top] = "1"
    state[:bottom] = "19"
    registers = Dict{Char, String}()
    buffer = Buffer(text, 
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
