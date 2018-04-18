function after_search(b::Buffer)
    b.mode[1] = b.mode[2]
    after(b)
end

function addsearchchar(b::Buffer, c)
    b.state[:search] = string(b.state[:search], c)
end
function rmsearchchar(b::Buffer)
    if length(b.state[:search]) >= 1
        b.state[:search] = b.state[:search][1:end-1]
    else
        escape(b)
    end
end

function previous_search(b::Buffer)
    searches = split(b.state[:searches], '\n')
    b.state[:search] = searches[max(1,parse(b.state[:searchind]))] #This stuff isn't super
    b.state[:searchind] = "$(parse(b.state[:searchind])-1)"
end
function search(b::Buffer) 
    #This can be done faster for (very) large files,
    #also, no support for regex search
    txt = [b.text[y(b)][x(b)+1:end];
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
    end
    b.state[:searchhistory] *= "\n"*b.state[:search]
    b.state[:searches] = "$(parse(b.state[:searches])+1)"
    b.state[:searchind] = b.state[:searches]
end

function search_fn(c)
    function fn(b::Buffer)
        if c=='\e'
            escape(b)
        elseif c=='\x7f'
            rmsearchchar(b)
        elseif c=='\r'
            search(b) #?
        elseif c=='\v'
            previous_search(b)
        else 
            addsearchchar(b, c)
        end
    end
end

search_mode = Mode("search", Action(search_fn, x->true))
