using Joy
using Base.Test

# write your own tests here

@test Joy.parse_n(['a','b', 'c', '2', '3']) == 23
@test Joy.parse_n(['a','1', 'b', 'c', '3']) == 3
@test Joy.parse_n(['a','1', 'b', '1', 'c']) == 1
@test Joy.parse_n(['a']) == 1
@test Joy.parse_n([]) == 1
