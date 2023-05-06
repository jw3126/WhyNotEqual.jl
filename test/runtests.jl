# module RunTests
using WhyNotEqual
using Test
import WhyNotEqual as WN
using OffsetArrays

function cmp_error(obj1, obj2)
    error("bad")
end

mutable struct MAB
    a
    b
end

struct AB
    a
    b
end

struct MyArray{T,N} <: AbstractArray{T,N}
    data::Array{T,N}
    hidden
end
Base.axes(o::MyArray) = axes(o.data)
Base.size(o::MyArray) = size(o.data)
Base.getindex(o::MyArray, i...) = o.data[i...]
function Base.:(==)(o1::MyArray, o2::MyArray) 
    (o1.hidden == o2.hidden) &&
    (o1.data == o2.data)
end

@testset "oneliners" begin
    @test whynot(==, "","") isa WN.TheSame
    @test whynot(==, "a","b") isa WN.DifferentAndNoChildren
    @test whynot(==, 1,1) isa WN.TheSame
    @test whynot(Returns(true), 1,1) isa WN.TheSame
    @test whynot(isequal, 1,1) isa WN.TheSame
    @test whynot(isequal, NaN,NaN) isa WN.TheSame
    @test whynot(==, NaN,NaN) isa WN.DifferentAndNoChildren
    @test whynot(===, 1,1) isa WN.TheSame
    @test whynot(cmp_error, 1,1) isa WN.CmpRaisedException
    @test whynot(Returns(false), 1,1) isa WN.DifferentAndNoChildren
    @test whynot(==, MAB(1,2), MAB(1,2)) isa WN.DifferentButSameChildren
    @test whynot(==, (MAB(1,2),), (MAB(1,2),)) isa WN.DifferentButSameChildren
    @test whynot(==, (MAB(1,2),), (MAB(1,2),)) isa WN.DifferentButSameChildren
    @test whynot(==, MyArray([1,2],3), MyArray([1,2],4)) isa WN.DifferentButSameChildren


    @test whynot(==, 1,1.0) isa WN.TheSame
    @test whynot(isequal, 1,1.0) isa WN.TheSame
    @test whynot(===, 1,1.0) isa WN.DifferentAndNoChildren
    @test whynot(cmp_error, 1,1.0) isa WN.CmpRaisedException

    @test whynot(==, [1], [1,2]) isa WN.DifferentAxes
    @test whynot(==, [1], ones(2,2)) isa WN.DifferentAxes

    @test whynot(==, Dict(1=>1), Dict(2=>1)) isa WN.ChildOnlyPresentInOne
    @test whynot(==, Dict(1=>1), Dict()).lens === identity

    @test whynot(==, [1], OffsetArray([1,2],2:3)) isa WN.DifferentAxes
    @test whynot(==, OffsetArray([1,2], 3:4), OffsetArray([1,2],2:3)) isa WN.DifferentAxes
    @test whynot(==, OffsetArray([1,2], 3:4), OffsetArray([1,2],3:4)) isa WN.TheSame
    @test whynot(isequal, OffsetArray([NaN,2], 3:4), OffsetArray([NaN,2],3:4)) isa WN.TheSame
    @test whynot(==, OffsetArray([NaN,2], 3:4), OffsetArray([NaN,2],3:4)) isa WN.DifferentAndNoChildren
end

@testset "show" begin
    res =  whynot(==, 1,1)
    @test res isa WN.TheSame
    @test !hasproperty(res, :lens)
    @test sprint(show, res) == "TheSame: Both objects are actually the same."

    res = whynot(cmp_error, 1,1) 
    @test res isa WN.CmpRaisedException
    @test res.lens === identity
    @test occursin("bad", sprint(show, whynot(cmp_error, 1,1)))

    res = whynot(Returns(false), :asd, :asd)
    @test res isa WN.DifferentAndNoChildren
    @test res.lens === identity
    @test occursin(":asd", sprint(show, res))

    res = whynot(==, (a=Dict(:mykey=>2), b=2),  (a=Dict(), b=2))
    @test res isa WN.ChildOnlyPresentInOne
    @test res.lens === (@optic _.a)
    @test occursin(":mykey", sprint(show, res))

    res = whynot(==, (x=[1],), (x=[1,2],) )
    @test res isa WN.DifferentAxes
    @test res.lens === (@optic _.x)
    @test occursin(string(axes([1])), sprint(show, res))
    @test occursin(string(axes([1,2])), sprint(show, res))

    res =  whynot((MAB(1,2),), (MAB(1,2),))
    @test res isa WN.DifferentButSameChildren
    @test occursin("are different, but their children are all the same.", sprint(show, res))
    @test res.lens === (@optic _[1])

    res = whynot(==, AB(1,2), AB(1,[2]))
    @test res isa WN.ChildrenTraitMismatch
    @test occursin("These have different child traits.", sprint(show, res))

end

@test whynot(==, AB(1,2), AB(1,2)) isa WN.TheSame
@test whynot(==, AB(1,2), AB(1,3)).lens === (@optic _.b)
@test whynot(==, AB(1,AB(2,3)), AB(1,AB(3,3))).lens === @optic _.b.a
@test whynot(==, AB(1,AB(2,AB(3,4))), AB(1,AB(2,AB(3,AB(4,5))))).lens === (@optic _.b.b.b)

@test whynot(==, AB(1,2), AB(1,[2])) isa WN.ChildrenTraitMismatch
@test whynot(==, AB(1,2), AB(1,[2])).lens === (@optic _.b)

@testset "readme" begin
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

    res = whynot(==, expected, result)
    @test res isa WN.DifferentAndNoChildren
    @test res.lens === (@optic _.z[AB(2, 3)].a)

end

# end#module
