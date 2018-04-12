include("extra_modes.jl")

function set_boundaries(b::Buffer)
    #remove parsing from here
    top, bottom = parse.([b.state[:top], b.state[:bottom]])
    if top > b.cursor.pos[1]
        d = b.cursor.pos[1] - top
    elseif bottom < b.cursor.pos[1]
        d = b.cursor.pos[1] - bottom
    else
        d = 0
    end
    b.state[:top], b.state[:bottom] = string.(Base.clamp.([top,
                                                           bottom]+d,
                                                          1, length(b.text)))
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
    b.cursor.pos[2] = width(b)
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

function join_arg(b::Buffer)
    n = parse_n(b.args)
    joinlines(b, (b.cursor.pos[1],b.cursor.pos[1]+n))
    after_normal(b)
end
function insert(b::Buffer)
    setmode(b,insert_mode)
    clamp(b, true)
end
function inserta(b::Buffer)
    b.cursor.pos[2] += 1
    setmode(b, insert_mode)
end

insertend(b::Buffer) = (move_eol(b); inserta(b))

function enter_cmdmode(b::Buffer)
    setmode(b,command_mode)
end

function go(b::Buffer)
    setmode(b, go_mode)
end

function start_replay(b::Buffer)
    setmode(b, replay_mode)
end

function enter_deletemode(b::Buffer)
    setmode(b, delete_mode)
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
                      'J'  => join_arg,
                      'g'  => go,
                      'G'  => gobottom,
                      'q'  => start_record,
                      '@'  => start_replay,
                      'd'  => enter_deletemode,
                      'Z'  => quit,
                     )

normal_mode = Mode("normal", normal_actions)
