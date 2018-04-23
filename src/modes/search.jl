#Right now, we have some emacs keybindings for moving forward and back, (ctrl-f, ctrl-b, ctrl-a, ctrl-e)
# as well as ctrl-k, ctrl-j to get previous/next commands from command history

function after_search(b::Buffer)
    setmode(b, b.mode[2])
    after(b)
end

function search(b::Buffer)
    #This can be done faster for (very) large files,
    #also, no support for regex search
    txt = [unirange(b.text[y(b)], x(b)+1:length(b.text[y(b)]));
           b.text[y(b)+1:end]]

    inds = Base.search.(txt, b.state[:search])
    yoffset = findfirst(x->length(x)!=0, inds)
    if yoffset == 1
        b.cursor.pos .= [y(b)+yoffset-1, x(b)+inds[yoffset][1]]
        after(self)
    elseif yoffset>1
        b.cursor.pos .= [y(b)+yoffset-1, inds[yoffset][1]]
        after(self)
    else
        b.state[:log] = "NOT FOUND"
        escape(self)
    end
    b.state[:search_history] *= "\n"*b.state[:search]
    b.state[:search_n] = "$(parse(b.state[:search_n])+1)"
    b.state[:search_ind] = b.state[:search_n]
end

search_fn(c) = exec_fn(c, :search, search)
search_mode = Mode("search", Action(search_fn, x->true))
