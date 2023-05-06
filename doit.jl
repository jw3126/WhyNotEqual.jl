# using WhyNotEqual
# struct AB;a;b;end
expected = (
    v = (hello=:world, language=:julia),
    w = 42,
    x = [1,2,3,4,5],
    y = AB(1,2),
    z = Dict(AB(1,2)=>3, AB(2,3)=>AB(3, ())),
    zz = (foo=collect(1:100), bar=:bar),
)
result = (
    v = (hello=:world, language=:julia),
    w = 42,
    x = [1,2,3,4,5],
    y = AB(1,2),
    z = Dict(AB(1,2)=>3, AB(2,3)=>AB(4, ())),
    zz = (foo=collect(1:100), bar=:bar),
)

# using Test
# @test expected == result

# whynot(==, expected, result)
lens = whynot(==, expected, result).lens
@show lens
@show lens(expected)
@show lens(result)
