# WhyNotEqual

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jw3126.github.io/WhyNotEqual.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jw3126.github.io/WhyNotEqual.jl/dev/)
[![Build Status](https://github.com/jw3126/WhyNotEqual.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jw3126/WhyNotEqual.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jw3126/WhyNotEqual.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jw3126/WhyNotEqual.jl)

Quickly find out why two complicated expressions are not equal.
# Usage

Ever encountered a situation like this:

```julia
@test expected == result
Test Failed at /home/jan/.julia/dev/WhyNotEqual/doit.jl:21
  Expression: expected == result
   Evaluated: (v = (hello = :world, language = :julia), w = 42, x = [1, 2, 3, 4, 5], y = AB(1, 2), 
z = Dict{AB, Any}(AB(2, 3) => AB(3, ()), AB(1, 2) => 3), zz = (foo = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10
  …  91, 92, 93, 94, 95, 96, 97, 98, 99, 100], bar = :bar)) == (v = (hello = :world, language = :ju
lia), w = 42, x = [1, 2, 3, 4, 5], y = AB(1, 2), z = Dict{AB, Any}(AB(2, 3) => AB(4, ()), AB(1, 2) 
=> 3), zz = (foo = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10  …  91, 92, 93, 94, 95, 96, 97, 98, 99, 100], bar
 = :bar))
ERROR: LoadError: There was an error during testing
```
Can you spot the difference? This package can do it for you:

```julia
using WhyNotEqual
whynot(==, expected, result)
```
```
DifferentAndNoChildren: When applying `lens` to both objects, we get `obj1` and `obj2`.
obj1 and obj2 are different, but they don't have any children.
lens: (@optic _.z[AB(2, 3)].a)
obj1: 3
obj2: 4
```
Of course you also have programmatic access to this data
```julia
lens = whynot(==, expected, result).lens
@show lens
@show lens(expected)
@show lens(result)
```

```
lens = (@optic _.z[AB(2, 3)].a)
lens(expected) = 3
lens(result) = 4
4
```
