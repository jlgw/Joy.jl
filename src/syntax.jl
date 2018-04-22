using Tokenize

const word2color = Dict(
                        :FUNCTION    => :light_magenta,
                        :IF          => :light_magenta,
                        :ELSE        => :light_magenta,
                        :ELSEIF      => :light_magenta,
                        :WHILE       => :light_magenta,
                        :FOR         => :light_magenta,
                        :RETURN      => :light_magenta,
                        :END         => :light_magenta,
                        :STRUCT      => :light_magenta,
                        :TRUE        => :yellow,
                        :FALSE       => :yellow,
                        :STRING      => :green,
                        :PAIR_ARROW  => :light_yellow,
                        :EQ          => :light_yellow,
                        :LESS        => :light_yellow,
                        :GREATER     => :light_yellow,
                        :CONDITIONAL => :light_yellow,
                        :DECLARATION => :light_yellow,
                        :COMMENT     => :light_green,
                       )

const ttc = Dict(zip(getfield.(Tokenize.Tokens, collect(keys(word2color))),
                     values(word2color)))

function colorize(s::String, c, def="\e[0m")
    tc = Base.text_colors
    c in keys(tc) ? string(tc[c], s, def) : s
end

function highlight(t::Tokenize.Tokens.Token)
    ek = Tokenize.Tokens.exactkind(t)
    ek in keys(ttc) ? colorize(untokenize(t), ttc[ek]) : untokenize(t)
end

function highlight(s::String)
    tk = collect(tokenize(s))
    join(highlight.(tk))
end
