using Joy
using Base.Test

orig = readlines("file")
# write your own tests here

@test Joy.parse_n(['a','b', 'c', '2', '3']) == 23
@test Joy.parse_n(['a','1', 'b', 'c', '3']) == 3
@test Joy.parse_n(['a','1', 'b', '1', 'c']) == 1
@test Joy.parse_n(['a']) == 1
@test Joy.parse_n([]) == 1

buffer = Joy.self
Joy.open("file", buffer)
Joy.handle_raw(buffer, 'j')
@test Joy.line(buffer) == orig[2]
Joy.replay(buffer, "2j")
@test Joy.line(buffer) == orig[4]
Joy.replay(buffer, "dd")
@test Joy.line(buffer) == orig[5]
