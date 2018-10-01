chr2ind(s::String, n::Integer) = Base.chr2ind(s, n)
function chr2ind(s::String, range::AbstractRange)
    if length(s) == 0 || length(range) == 0
        return 0:-1
    else
        ec = chr2ind(s, range.stop)
        sc = chr2ind(s, range.start)
        if step(range)>0
            sc:step(range):(ec+sizeof(s[ec:ec])-1)
        else
            sc+sizeof(s[sc:sc])-1:step(range):ec
        end
    end
end
"""
unirange(s::String, range::AbstractRange)

Like s[range] but for unicode.
"""
function unirange(s::String, range::AbstractRange)
    if length(s) == 0 || length(range) == 0
        ""
    elseif step(range) == 1
        r = chr2ind(s, range)
        s[r.start:r.stop]
    elseif step(range) == -1
        s = reverse(s)
        r = chr2ind(s, length(s)-range+1)
        s[r.start:r.stop]
    else
        error("Only single step range permitted")
    end
end

"""
replace!(c::Array{String, 1}, pattern, repl)

Replace pattern with repl in each member of c.
"""
function replace!(c::Array{String, 1}, pattern, repl)
    map!(s->replace(s, pattern, repl), c)
end

