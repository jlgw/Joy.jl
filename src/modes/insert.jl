function insertat(b::Buffer, c::Char, pos)
    pr = b.text[pos[1]]
    b.text[pos[1]] = string(pr[1:min(pos[2]-1, end)], c, pr[max(1,pos[2]):end])
end

function deleteback(b::Buffer)
    b.cursor.pos[2] -= 1
    if b.cursor.pos[2] >= 1
        deleteat(b, b.cursor.pos)
    else
        b.cursor.pos[1] -= 1
        b.cursor.pos[2] = length(b.text[b.cursor.pos[1]])+1
        joinlines(b, (b.cursor.pos[1], b.cursor.pos[1]+1))
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
            clamp(b, true)
        elseif c=='\r'
            splitp(b)
        else 
            insertat(b, c, pos(b))
            b.cursor.pos[2] += 1
        end
    end
end

insert_mode = Mode("insert", Action(insert_fn, x->true))
