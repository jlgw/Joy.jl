function move_left(b::Buffer)
    b.cursor.pos[2] -= parse_n(b)
    after(b)
end
function move_right(b::Buffer)
    b.cursor.pos[2] += parse_n(b)
    after(b)
end
function move_up(b::Buffer)
    b.cursor.pos[1] -= parse_n(b)
    after(b)
end
function move_down(b::Buffer)
    b.cursor.pos[1] += parse_n(b)
    after(b)
end
function move_eol(b::Buffer)
    b.cursor.pos[2] = width(b)
    after(b)
end
function move_bol(b::Buffer)
    b.cursor.pos[2] = 1
    after(b)
end

function go(b::Buffer)
    setmode(b, go_mode)
end
function gobottom(b::Buffer)
    b.cursor.pos[1] = height(b)
    escape(b)
    after_normal(b) #Keep this for now
end

function enter_findmode(b::Buffer)
    setmode(b, find_mode)
end

#Caution: This doesn't work the same as it does in vim
#In vim, an empty line is included with w but not e, these are different operators
#Here, we treat the e operation as a combination of e and an eow call
function move_word(b::Buffer)
    n = parse_n(b.args)
    move_to_nth_word(b, n)
    after(b)
end
function move_eow(b::Buffer)
    n = parse_n(b.args)
    move_to_nth_eow(b, n)
    after(b)
end
function back_word(b::Buffer)
    n = parse_n(b.args)
    back_to_nth_word(b, n)
    after(b)
end
function back_eow(b::Buffer)
    n = parse_n(b.args)
    back_to_nth_eow(b, n)
    after(b)
end

function move_Word(b::Buffer)
    n = parse_n(b.args)
    move_to_nth_Word(b, n)
    after(b)
end
function move_eoW(b::Buffer)
    n = parse_n(b.args)
    move_to_nth_eoW(b, n)
    after(b)
end
function back_Word(b::Buffer)
    n = parse_n(b.args)
    back_to_nth_Word(b, n)
    after(b)
end
function back_eoW(b::Buffer)
    n = parse_n(b.args)
    back_to_nth_eoW(b)
    after(b)
end

movements = Dict('h' => move_left,
                 'j' => move_down,
                 'k' => move_up,
                 'l' => move_right,
                 '$' => move_eol,
                 'g' => go,
                 'G' => gobottom,
                 'f' => enter_findmode,
                 'w' => move_word,
                 'e' => move_eow,
                 'b' => back_eow,
                 'W' => move_Word,
                 'E' => move_eoW,
                 'B' => back_eoW,
                )

