#Some constructs shamelessly stolen from TerminalMenus

#This needs to be reconsidered
const self = init([""])

function attach(buffer::Buffer)
    buffer.state[:running] = true
    Base.REPL.raw!(buffer.term, true)
    move_sys_cursor(1,1)
    render(buffer)
    move_sys_cursor(1,1)
    while buffer.state[:running]
        buffer.state[:log] = ""
        handle_raw(buffer, read(STDIN, Char))
        move_sys_cursor(1,1)
        render(buffer)
        if buffer.mode==command_mode
            write(STDOUT, string(":", buffer.state[:command]))
        else
            move_sys_cursor(buffer.cursor.pos[1]-buffer.state[:top]+1, buffer.cursor.pos[2])
        end
    end
    finalize(buffer)
    buffer
end
function finalize(buffer::Buffer)
    clear_screen()
end

#It would be nice if we had a macro so that all functions that take ::Buffer as argument
#were defined without buffer as argument using the global self variable

function open(st)
    data = readlines(st)
    self.text = data
    if !self.state[:running]
        attach(self)
    end
    self
end

function open(st, buffer)
    buffer.text = readlines(st)
end

function save(st, buffer)
    write(st, join(buffer.text, "\n"))
end

function save(st::String)
    write(st, join(self.text, "\n"))
end

function quit()
    quit(self)
end

