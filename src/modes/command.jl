# It would be cool if this were an actual REPL with completion etc
#Right now, we have some emacs keybindings for moving forward and back, (ctrl-f, ctrl-b, ctrl-a, ctrl-e)
# as well as ctrl-k, ctrl-j to get previous/next commands from command history

function evalcmd(b::Buffer, s::String)
    try
        eval(Base.parse_input_line(s))
    catch
        "INVALID COMMAND"
    end
end
function evalcmd(b::Buffer) 
    try
        escape(b)
        if b.state[:command][1] == '?'
            c = eval(Base.parse_input_line("@doc "*b.state[:command][2:end]))
        else
            c = eval(Base.parse_input_line(b.state[:command]))
        end
        if b.state[:command][end] != ';'
            b.state[:log] = "$c"
        end
        b.state[:command_history] *= b.state[:command]*"\n"
        b.state[:command] = ""
        command_n = parse(b.state[:command_n])
        b.state[:command_n] = "$(command_n+1)"
        b.state[:command_ind] = "$(b.state[:command_n])"
    catch y
        b.state[:log] = "INVALID COMMAND: $y"
        setmode(b, command_mode)
    end
end

command_fn(c) = exec_fn(c, :command, evalcmd)
command_mode = Mode("command", Action(command_fn, x->true))
