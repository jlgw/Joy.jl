# It would be cool if this were an actual REPL with completion etc

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
        c = eval(Base.parse_input_line(b.state[:command]))
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
