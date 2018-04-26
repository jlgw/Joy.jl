using Requires

@require Spelling begin
    function spell_colorize(s::String, c=1.0)
        words = spellcheck_sentence(lowercase(s), c)
        sp = (w->w.offset).(words)
        ep = (w->w.offset+length(w.match)).(words)
        sar = split(s, "")
        for i in 1:length(sp)
            insert!(sar, sp[i]+2*i-2, Base.text_colors[:light_red])
            insert!(sar, ep[i]+2*i-1, Base.text_colors[:normal])
        end
        join(sar)
    end
end
