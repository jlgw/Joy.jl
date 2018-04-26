function run(b::Buffer)
    b.state[:log] = ""
    r = read(STDIN, Char)
    handle_raw(b, r)
    render(b)
    h = bottom(b)-top(b)
    if mode(b)==command_mode
        write(STDOUT, string(":", b.state[:command]))
        move_sys_cursor(h+3, 1+parse(b.state[:command_insert]))
    elseif mode(b)==search_mode
        write(STDOUT, string("/", b.state[:search]))
        move_sys_cursor(h+3, 1+parse(b.state[:search_insert]))
    else
        move_sys_cursor(b.cursor.pos[1]-top(b)+1, b.cursor.pos[2]-left(b)+1)
    end
end

function init(text)
    cursor = Cursor([1,1])
    state = Dict(:actions => "")
    state[:running]  = "false"
    state[:console]  = ""
    state[:register] = "\""
    state[:log]      = ""
    state[:top]      = "1"
    state[:bottom]   = "19"
    state[:left]     = "0"
    state[:right]    = "80"
    state[:syntax]   = "true"
    state[:undo]     = ""
    init_call(state, :command)
    init_call(state, :search)
    registers = Dict{Char, String}()
    Buffer(text,
           [""],
           [""],
           cursor, 
           [normal_mode, normal_mode], 
           state, 
           registers, 
           Array{Char, 1}())
end

function handle_raw(b::Buffer, c::Char)
    b.state[:actions] = string(b.state[:actions], c)
    mode(b).actions[c](b)
    xp = (x(b)>0 ? xs(b) : "0-1")
    b.state[:console] = string(mode(b).signature,
                               " ",ys(b), ",", xp, " ",
                               join(b.args, ""), "\n", b.state[:log])
end

function onopen()
end
function onattach()
end
