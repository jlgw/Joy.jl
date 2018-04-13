#Some constructs shamelessly stolen from TerminalMenus

#This needs to be reconsidered
if !isdefined(:self)
    const self = init([""])
end

#Adds time to load, reduces time to open, should be replaced later
handle_raw(self, 'j')
handle_raw(self, 'k')

function attach(buffer::Buffer)
    buffer.state[:running] = "true"
    Base.REPL.raw!(buffer.term, true)
    move_sys_cursor(1,1)
    render(buffer)
    move_sys_cursor(1,1)
    while buffer.state[:running]=="true"
        buffer.state[:log] = ""
        r = read(STDIN, Char)
        handle_raw(buffer, r)
        move_sys_cursor(1,1)
        render(buffer)
        if mode(buffer)==command_mode
            write(STDOUT, string(":", buffer.state[:command]))
        else
            move_sys_cursor(buffer.cursor.pos[1]-top(buffer)+1, buffer.cursor.pos[2])
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

function open(st::String)
    self.state[:filename] = st
    data = readlines(st)
    settext(self, data)
    #Change later
    self.state[:top] = "1"
    self.state[:bottom] = "19"
    if self.state[:running] == "false"
        attach(self)
    end
    self
end

function open(b::Buffer, st)
    b.state[:filename] = st
    settext(b, readlines(st))
end

function save(b::Buffer, st::String)
    write(st, join(b.text, "\n"))
end
function save(b::Buffer)
    if in(:filename, keys(b.state))
        save(b, b.state[:filename])
    else
        "No file name"
    end
end
save(st::String) = save(self, st)
save() = save(self)

function quit()
    quit(self)
end

#Just for vi muscle memory
struct Save
end
Base.show(io::IO, s::Save) = save()
(s::Save)() = save()

struct Quit
end
Base.show(io::IO, q::Quit) = quit()
(q::Quit)() = quit()

w = Save()
q = Quit()
