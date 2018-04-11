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
    b.cursor.pos[2] -= 1
    after_normal(b)
end
function move_right(b::Buffer)
    b.cursor.pos[2] += 1
    after_normal(b)
end
function move_up(b::Buffer)
    b.cursor.pos[1] -= 1
    after_normal(b)
end
function move_down(b::Buffer)
    b.cursor.pos[1] += 1
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

function delete(b::Buffer)
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

function gobottom(b::Buffer)
    b.cursor.pos[1] = getheight(b)
    after_normal(b)
end

function go(b::Buffer)
    if b.args == ['g']
        b.cursor.pos[1] = 1
    elseif b.args == ['G']
        b.cursor.pos[1] = getheight(b)
    else
        return push!(b.args, 'g')
    end
    after_normal(b)
end

insertend(b::Buffer) = (move_eol(b); inserta(b))

function enter_cmdmode(b::Buffer)
    b.mode = command_mode
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
                      'x'  => delete,
                      'J'  => joinone,
                      'g'  => go,
                      'G'  => gobottom,
                     )

normal_mode = Mode("normal", normal_actions)
