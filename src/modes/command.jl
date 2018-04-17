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
function evalcmd(b::Buffer, s::String)
    try
        eval(Base.parse_input_line(s))
    catch
        "INVALID COMMAND"
    end
end
function previous_cmd(b::Buffer)
    cmds = split(b.state[:cmdhistory], '\n')
    b.state[:command] = cmds[max(1,parse(b.state[:cmd]))] #This stuff isn't super
    b.state[:cmd] = "$(parse(b.state[:cmd])-1)"
end
function evalcmd(b::Buffer) 
    try
        escape(b)
        c = eval(Base.parse_input_line(b.state[:command]))
        if b.state[:command][end] != ';'
            b.state[:log] = "$c"
        end
        b.state[:cmdhistory] *= "\n"*b.state[:command]
        b.state[:command] = ""
        b.state[:cmds] = "$(parse(b.state[:cmds])+1)"
        b.state[:cmd] = b.state[:cmds]
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
        elseif c=='\v'
            self.state[:log] = "working"
            previous_cmd(b)
        else 
            addcmdchar(b, c)
        end
    end
end

command_mode = Mode("command", Action(command_fn, x->true))
