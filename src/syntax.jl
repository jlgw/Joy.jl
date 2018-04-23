using Tokenize

const word2color = Dict(
                        :KEYWORD       => :light_magenta,
                        :OP            => :light_yellow,
                        :END           => :magenta,
                        :TRUE          => :yellow,
                        :FALSE         => :yellow,
                        :FLOAT         => :cyan,
                        :INTEGER       => :cyan,
                        :STRING        => :light_green,
                        :TRIPLE_STRING => :light_green,
                        :CHAR          => :red,
                        :COMMENT       => :green,
                        :ERROR         => :light_red,
                       )

const ttc = Dict(zip(getfield.(Tokenize.Tokens, collect(keys(word2color))),
                     values(word2color)))

function colorize(s::String, c, def="\e[0m")
    tc = Base.text_colors
    c in keys(tc) ? string(tc[c], s, def) : s
end

function highlight(t::Tokenize.Tokens.Token)
    s = untokenize(t)
    k = Tokenize.Tokens.kind(t)
    ek = Tokenize.Tokens.exactkind(t)
    if ek in keys(ttc)
        colorize(s, ttc[ek])
    elseif k in keys(ttc)
        colorize(s, ttc[k])
    else
        s
    end
end

function highlight(s::String)
    tk = collect(tokenize(s))
    join(highlight.(tk))
end
