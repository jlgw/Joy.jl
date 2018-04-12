function set_boundaries(b::Buffer)
    if b.state[:top] > b.cursor.pos[1]
        d = b.cursor.pos[1] - b.state[:top]
    elseif b.state[:bottom] < b.cursor.pos[1]
        d = b.cursor.pos[1] - b.state[:bottom]
    else
        d = 0
    end
    b.state[:top], b.state[:bottom] = Base.clamp([b.state[:top], b.state[:bottom]]+d, 
                                                  1, length(b.text))
end
function after_normal(b::Buffer)
    clear_arg(b)
    clamp(b)
    set_boundaries(b)
end

function move_left(b::Buffer)
    b.cursor.pos[2] -= parse_n(b)
    after_normal(b)
end
function move_right(b::Buffer)
    b.cursor.pos[2] += parse_n(b)
    after_normal(b)
end
function move_up(b::Buffer)
    b.cursor.pos[1] -= parse_n(b)
    after_normal(b)
end
function move_down(b::Buffer)
    b.cursor.pos[1] += parse_n(b)
    after_normal(b)
end
function move_eol(b::Buffer)
    b.cursor.pos[2] = getwidth(b)
    clear_arg(b)
end
function move_bol(b::Buffer)
    b.cursor.pos[2] = 1
    clear_arg(b)
end

function delete_char(b::Buffer)
    deleteat(b, b.cursor.pos)
    after_normal(b)
end
function joinone(b::Buffer)
    joinlines(b, (b.cursor.pos[1],b.cursor.pos[1]+1))
end
function insert(b::Buffer)
    b.mode = insert_mode
    clamp(b, true)
end
function inserta(b::Buffer)
    b.cursor.pos[2] += 1
    b.mode = insert_mode
end

function gogo(b::Buffer)
    b.cursor.pos[1] = parse_n(b)
    escape(b)
    after_normal(b)
end
function gobottom(b::Buffer)
    b.cursor.pos[1] = getheight(b)
    escape(b)
    after_normal(b)
end

insertend(b::Buffer) = (move_eol(b); inserta(b))

function enter_cmdmode(b::Buffer)
    b.mode = command_mode
end

go_actions = Dict('g' => gogo,
                  'G' => gobottom,
                  '\e' => escape,
                 )
go_mode = Mode("go", go_actions)

function go(b::Buffer)
    b.mode = go_mode
end

function set_register(c)
    function set(b)
        b.state[:recording] = c
        #This is a bad solution since it assumes all key presses are saved and never purged
        b.state[:macroindex] = length(b.state[:actions])+1
        escape(b)
        b.state[:log] = "Recording to register $c"
    end
end

register_record_mode = Mode("register macro", Action(set_register, x->true))

function record(b::Buffer)
    if !in(:recording, keys(b.state)) || b.state[:recording] == '\e'
        b.mode = register_record_mode
    else
        b.state[:macros][b.state[:recording]] = join(b.state[:actions][b.state[:macroindex]:end-1])
        b.state[:log] = b.state[:macros][b.state[:recording]]
    end
end

function replay_register(c)
    function replay_macro(b::Buffer)
        if in(c, keys(b.state[:macros]))
            replay(b, b.state[:macros][c])
        else
            b.state[:log] = "No macro in register $c"
        end
        escape(b)
    end
end

replay_mode = Mode("replay", Action(replay_register, x->true))

function replay(b::Buffer)
    b.mode = replay_mode
end

normal_actions = Dict('h'  => move_left,
                      'j'  => move_down,
                      'k'  => move_up,
                      'l'  => move_right,
                      'i'  => insert,
                      'a'  => inserta,
                      '$'  => move_eol,
                      'A'  => insertend,
                      '\e' => clear_arg,
                      ':'  => enter_cmdmode,
                      'x'  => delete_char,
                      'J'  => joinone,
                      'g'  => go,
                      'G'  => gobottom,
                      'q' => record,
                      '@' => replay,
                     )

normal_mode = Mode("normal", normal_actions)
