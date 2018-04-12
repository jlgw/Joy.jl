# It would be cool if this were an actual REPL with completion etc

function addcmdchar(b::Buffer, c)
    b.state[:command] = string(b.state[:command], c)
end
function rmcmdchar(b::Buffer)
    if length(b.state[:command]) >= 1
        b.state[:command] = b.state[:command][1:end-1]
    else
        escape(b)
    end
end
function evalcmd(b::Buffer)
    try
        #rethink this
        escape(b)
        c = eval(Base.parse_input_line(b.state[:command]))
        if b.state[:command][end] != ';'
            b.state[:log] = "$c"
        end
        b.state[:command] = ""
    catch
        b.state[:log] = "INVALID COMMAND"
        setmode(b, command_mode)
    end
end

function command_fn(c)
    function fn(b::Buffer)
        if c=='\e'
            b.state[:command] = ""
            escape(b)
        elseif c=='\x7f'
            rmcmdchar(b)
        elseif c=='\r'
            evalcmd(b)
        else 
            addcmdchar(b, c)
        end
    end
end

command_mode = Mode("command", Action(command_fn, x->true))
