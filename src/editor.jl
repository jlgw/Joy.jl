#Some constructs shamelessly stolen from TerminalMenus

#This needs to be reconsidered
if !isdefined(:self)
    const self = init([""])
    handle_raw(self, 'j')
    handle_raw(self, 'w')
end

function run(b::Buffer)
    b.state[:log] = ""
    r = read(STDIN, Char)
    handle_raw(b, r)
    move_sys_cursor(1,1)
    render(b)
    if mode(b)==command_mode
        write(STDOUT, string(":", b.state[:command]))
    elseif mode(b)==search_mode
        write(STDOUT, string("/", b.state[:search]))
    else
        move_sys_cursor(b.cursor.pos[1]-top(b)+1, b.cursor.pos[2]-left(b)+1)
    end
end

function attach(b::Buffer)
    term = Base.REPL.Terminals.TTYTerminal(get(ENV, "TERM", "dumb"), STDIN, STDOUT, STDERR)
    Base.REPL.raw!(term, true)
    b.state[:running] = "true"
    move_sys_cursor(1,1)
    render(b)
    move_sys_cursor(1,1)
    while b.state[:running]=="true"
        Base.invokelatest(run, b)
    end
    finalize(b)
    b
end
function finalize(b::Buffer)
    clear_screen()
    term = Base.REPL.Terminals.TTYTerminal(get(ENV, "TERM", "dumb"), STDIN, STDOUT, STDERR)
    Base.REPL.raw!(term, false)
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

w = Save();
q = Quit(); #Pretty amusing bug - reloading this file without the ; exits the editor since show() is called on q
1
