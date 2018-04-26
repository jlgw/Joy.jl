module Joy

include("base.jl")
include("string_utils.jl")
include("utils.jl")
include("words.jl")
include("syntax.jl")

include("modes/movements.jl")
include("modes/normal.jl")
include("modes/insert.jl")
include("modes/calls.jl")
include("modes/command.jl")
include("modes/search.jl")

include("config.jl")
include("spelling.jl")
isfile("$(homedir())/.joyrc.jl") && include("$(homedir())/.joyrc.jl")

include("editor.jl")

end
