# Joy

[![Build Status](https://travis-ci.org/lancebeet/Joy.jl.svg?branch=master)](https://travis-ci.org/lancebeet/Joy.jl)

[![Coverage Status](https://coveralls.io/repos/lancebeet/Joy.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/lancebeet/Joy.jl?branch=master)

[![codecov.io](http://codecov.io/github/lancebeet/Joy.jl/coverage.svg?branch=master)](http://codecov.io/github/lancebeet/Joy.jl?branch=master)

Joy is a modal line-based text editor written in Julia. This is a toy project; it is not a full-fledged text editor and parts of the foundation still need to be thought out. The goal of the project is a modal editor implemented and extensible in Julia.

## How to install
```julia
julia> Pkg.clone("https://github.com/lancebeet/Joy.jl")
```

## How to use
To open existing text file:
```julia
julia> using Joy
julia> buffer = Joy.open("textfile")
```
To exit:
```julia
:quit()
```
To save:
```julia
:save("filename")
```
Reattaching to an existing buffer from the REPL:
```julia
julia> Joy.attach(buffer)
```

vi-like movement

<img src="movement.gif" style="width: 500px;"/>

Command mode for evaluation of Julia expressions

<img src="command.gif" style="width: 500px;"/>

Applying arbitrary Julia maps to the entire buffer

<img src="mappings.gif" style="width: 500px;"/>
