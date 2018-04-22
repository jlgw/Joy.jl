function insertat(b::Buffer, c::Char, pos)
    pr = b.text[pos[1]]
    b.text[pos[1]] = string(unirange(pr, 1:pos[2]-1),
                            c,
                            unirange(pr, pos[2]:length(pr)),
                           )
end

function deleteback(b::Buffer)
    b.cursor.pos[2] -= 1
    if b.cursor.pos[2] >= 1
        deleteat(b, pos(b), 1)
    elseif y(b) > 1
        b.cursor.pos[1] -= 1
        b.cursor.pos[2] = width(b) + 1
        join_lines(b, (y(b), y(b) + 1), "")
    end
end
function splitp(b::Buffer)
    splitlines(b, b.cursor.pos)
    b.cursor.pos[1] += 1
    b.cursor.pos[2] = 1
end
function escape_insert(b)
    b.cursor.pos[2] -= 1
    escape(b)
end
function insert_fn(c)
    function insert(b::Buffer)
        if c=='\e'
            escape_insert(b)
        elseif c=='\x7f'
            deleteback(b)
            clamp!(b, true)
        elseif c=='\r'
            splitp(b)
        else 
            insertat(b, c, pos(b))
            b.cursor.pos[2] += 1
        end
    end
end

insert_mode = Mode("insert", Action(insert_fn, x->true))
