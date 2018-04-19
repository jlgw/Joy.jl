#Switch argument order? Convention is buffer first, but that conflicts with julia praxis
#This is not be identical to vi(m)
#Symmetric words don't support unicode, we have to do this another way
const Word = r"\S+|^\s+$|^$"
const word = r"[\pL\pN_]+|[\pS\pP]+|^\s+$|^$"

crs(s::String, r::Regex) = length(matchall(r, s))
crs(b::Buffer, r::Regex, n::Integer) = crs(line(b, n), r)

#It should be possible to make this faster
#it may be necessary, num arg word movement should be very fast
function next_pos(s::String, r::Regex, n=1)
    c = collect(eachmatch(r, s))
    if length(c)>=n
        if length(s)>1
            return ind2chr(s, c[n].offset)
        else
            return 1
        end
    else
        return -1
    end
end

next_pos(b::Buffer, r::Regex, n=1) = next_pos(unirange(line(b), max(x(b),1):width(b)),
                                              r, n)
function next_pos_naive(b::Buffer, r::Regex, n=1)
    s = unirange(line(b), max(x(b),1):width(b))
    if next_pos(s, r, 1) == 1
        n += 1
    end
    m = next_pos(s, r, n)
    if m!=-1
        return pos(b).+[0,m-1]
    else
        lf = length(collect(eachmatch(r, s)))+1
        wc = cumsum(crs.(b.text[y(b)+1:end], r))
        yoffset = findfirst(x->x>n, lf+wc)
        mc = n - lf
        if yoffset>1
            mc -= wc[yoffset-1]
        end
        if mc==0
            xoffset = next_pos(line(b, y(b)+yoffset), r, 1)
        else
            #Pretty clumsy solution
            if next_pos(line(b, y(b)+yoffset), r, 1)!=1
                xoffset = next_pos(line(b, y(b)+yoffset), r, mc)
            else
                xoffset = next_pos(line(b, y(b)+yoffset), r, mc+1)
            end
        end
        return [y(b)+yoffset, xoffset]
    end
end

function prev_pos_naive(b::Buffer, r::Regex, n=1)
    s = unirange(line(b), min(x(b),width(b)):-1:1)
    if next_pos(s, r, 1) == 1
        n += 1
    end
    m = next_pos(s, r, n)
    b.state[:m] = "$m"
    if m!=-1
        return pos(b).-[0,m-1]
    else
        lf = length(collect(eachmatch(r, s)))+1
        wc = cumsum(crs.(b.text[y(b)-1:-1:1], r))
        yoffset = findfirst(x->x>n, lf+wc)
        mc = n - lf
        if yoffset>1
            mc -= wc[yoffset-1]
        end
        if mc==0
            xoffset = next_pos(reverse(line(b, y(b)-yoffset)), r, 1)
        else
            #Pretty clumsy solution
            if next_pos(line(b, y(b)+yoffset), r, 1)!=1
                xoffset = next_pos(reverse(line(b, y(b)-yoffset)), r, mc)
            else
                xoffset = next_pos(reverse(line(b, y(b)-yoffset)), r, mc+1)
            end
        end
        return [y(b)-yoffset, length(line(b, y(b)-yoffset)) - xoffset+1]
    end
end

function eom(s::String, r::Regex)
    match(r, s).offset + length(match(r, s).match) - 1
end
eom(b::Buffer, r::Regex) = eom(unirange(line(b), max(x(b),1):width(b)), r)
bom(b::Buffer, r::Regex) = -eom(unirange(line(b), min(x(b),width(b)):-1:1), r)

function move_to_nth(b::Buffer, r::Regex, n)
    b.cursor.pos .= next_pos_naive(b, r, n)
end

function back_to_nth(b::Buffer, r::Regex, n)
    b.cursor.pos .= prev_pos_naive(b, r, n)
end

function move_to_nth_eom(b::Buffer, r::Regex, n)
    if eom(b, r)>1
        b.cursor.pos[2] += eom(b, r) - 1
        n -= 1
    end
    b.cursor.pos .= next_pos_naive(b, r::Regex, n)
    b.cursor.pos[2] += eom(b, r) - 1
end

function back_to_nth_eom(b::Buffer, r::Regex, n)
    if -bom(b, r)>1
        b.cursor.pos[2] += bom(b, r) + 1
        n -= 1
    end
    b.cursor.pos .= prev_pos_naive(b, r::Regex, n)
    b.cursor.pos[2] += bom(b, r) + 1
end

function move_ops(r::Regex)
    crs_r(b::Buffer, n) = crs(b, r, n)
    crs_r(s::String) = crs(s, r)
    next_pos_r(s::String, n=1) =  next_pos(s, r, n)
    next_pos_naive_r(b::Buffer, n=1)  = next_pos_naive(b, r, n)
    prev_pos_naive_r(b::Buffer, n=1)  = prev_pos_naive(b, r, n)
    eom_r(o::Union{Buffer, String}) = eom(o, r)
    bom_r(o::Union{Buffer, String}) = bom(o, r)
    move_to_nth_r(b::Buffer, n=parse_n(b)) = move_to_nth(b, r, n)
    move_to_nth_eom_r(b::Buffer, n=parse_n(b)) = move_to_nth_eom(b, r, n)
    back_to_nth_r(b::Buffer, n=parse_n(b)) = back_to_nth(b, r, n)
    back_to_nth_eom_r(b::Buffer, n=parse_n(b)) = back_to_nth_eom(b, r, n)
    [crs_r,
     next_pos_r,
     next_pos_naive_r,
     prev_pos_naive_r,
     eom_r,
     bom_r,
     move_to_nth_r,
     move_to_nth_eom_r,
     back_to_nth_r,
     back_to_nth_eom_r,
    ]
end

(cwords,
 nextword_pos,
 nextword_pos_naive,
 prevword_pos_naive,
 eow,
 bow,
 move_to_nth_word,
 move_to_nth_eow,
 back_to_nth_word,
 back_to_nth_eow,
) = move_ops(word)

(cWords,
 nextWord_pos,
 nextWord_pos_naive,
 prevWord_pos_naive,
 eoW,
 boW,
 move_to_nth_Word,
 move_to_nth_eoW,
 back_to_nth_Word,
 back_to_nth_eoW,
) = move_ops(Word)

