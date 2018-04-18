using Joy
using Base.Test

orig = readlines("file")

@testset "Numerical argument parser" begin
    @test Joy.parse_n(['a','b', 'c', '2', '3']) == 23
    @test Joy.parse_n(['a','1', 'b', 'c', '3']) == 3
    @test Joy.parse_n(['a','1', 'b', '1', 'c']) == 1
    @test Joy.parse_n(['a']) == 1
    @test Joy.parse_n([]) == 1
end

@testset "Find symbol" begin
    @test Joy.findsymbol("Lörem ipsum dolor sit amet", 'i', 1) == 7
    @test Joy.findsymbol("Lörem ipsum dolor sit amet", 'i', 2) == 20
end

buffer = Joy.self
Joy.open(buffer, "file")

@testset "Movements, keybindings, delete" begin
    Joy.handle_raw(buffer, 'j')
    @test Joy.line(buffer) == orig[2]
    Joy.replay(buffer, "2j")
    @test Joy.line(buffer) == orig[4]
    Joy.replay(buffer, "dd")
    @test Joy.line(buffer) == orig[5]
    Joy.replay(buffer, "gg")
    Joy.replay(buffer, "i\r\r\e")
    Joy.replay(buffer, "kia\e")
    @test Joy.line(buffer) == "a"
    cmd = ":settext(self, map(z->\"\$z \"*line(self, z), 1:height(self)))\r"
    Joy.replay(buffer, cmd)
    Joy.replay(buffer, "12gg")
    @test Joy.line(buffer)[1:2] == "12"
end

@testset "Word handling" begin
    @test Joy.nextword_pos("Lörem ipsum dolor sit amet", 2) == 7
    @test Joy.nextword_pos(" Lörem ipsum dolor sit amet") == 2
    @test Joy.nextword_pos("Lörem ipsum dolor sit amet", 4) == 19
    @test Joy.nextword_pos("(", 2) == -1
    Joy.open(buffer, "file")
    Joy.replay(buffer, "99k99h")
    Joy.replay(buffer, "wwww")
    @test Joy.line(buffer)[Joy.x(buffer):Joy.x(buffer)+2] == "sit"
    Joy.replay(buffer, "50hW")
    @test Joy.line(buffer)[Joy.x(buffer):Joy.x(buffer)+4] == "ipsum"
    Joy.replay(buffer, "j10w")
    @test Joy.line(buffer) == ""
    Joy.replay(buffer, "e")
    @test Joy.line(buffer)[Joy.x(buffer)] == 't'
    Joy.replay(buffer, "3b")
    @test Joy.line(buffer)[Joy.x(buffer)] == 'a'
end

@testset "Delete mode" begin
    Joy.replay(buffer, "99k99h")
    Joy.replay(buffer, "dw")
    @test buffer.text[1][1] == orig[1][2]
    Joy.replay(buffer, "2dw")
    @test buffer.text[1][1] == orig[1][14]
    # Not perfect, should override this
    Joy.replay(buffer, "dfc")
    @test buffer.text[1][1] == 'c' 
end

@testset "Yank/Paste" begin
    Joy.replay(buffer, "99k99h")
    Joy.settext(buffer, ["c", "c"])
    Joy.paste(buffer, [1,1], "a\nb")
    @test buffer.text == ["ca", "b", "c"]
    Joy.settext(buffer, ["Lorem", "ipsum"])
    Joy.replay(buffer, "99k99h")
    Joy.replay(buffer, "\"ayw")
    @test buffer.registers['a'] == "Lorem\n"
end
@testset "Search" begin
    Joy.replay(buffer, "99k99h")
    Joy.settext(buffer, ["Lorem ipsum", "Lorem2 ipsum2"])
    Joy.replay(buffer, "/ipsum\r")
    @test Joy.pos(buffer) == [1,7]
    Joy.replay(buffer, "/ipsum2\r")
    @test Joy.pos(buffer) == [2,8]
    Joy.replay(buffer, "99k99h")
    Joy.replay(buffer, "d/Lorem2\r")
    @test buffer.text == ["Lorem2 ipsum2"]
    Joy.replay(buffer, "y/ipsum2\r")
    @test buffer.registers['"'] == "Lorem2 "
    Joy.settext(buffer, ["Lorem ipsum", "Lorem2 ipsum2"])
    Joy.replay(buffer, "99k99h")
    Joy.replay(buffer, "/ipsum\r")
    Joy.replay(buffer, "n")
    @test Joy.pos(buffer) == [2,8]
end
