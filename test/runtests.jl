using WhyNotEqual: whynot
using Test
using Accessors
import WhyNotEqual as WN

function cmp_error(obj1, obj2)
    error("bad")
end

mutable struct MAB
    a
    b
end

@testset "oneliners" begin
    @test whynot(==, 1,1) isa WN.TheSame
    @test whynot(Returns(true), 1,1) isa WN.TheSame
    @test whynot(isequal, 1,1) isa WN.TheSame
    @test whynot(===, 1,1) isa WN.TheSame
    @test whynot(cmp_error, 1,1) isa WN.CmpRaisedException
    @test whynot(Returns(false), 1,1) isa WN.DifferentAndNoChildren
    @test whynot(MAB(1,2), MAB(1,2)) isa WN.DifferentButSameChildren


    @test whynot(==, 1,1.0) isa WN.TheSame
    @test whynot(isequal, 1,1.0) isa WN.TheSame
    @test whynot(===, 1,1.0) isa WN.DifferentAndNoChildren
    @test whynot(cmp_error, 1,1.0) isa WN.CmpRaisedException

    @test whynot(==, [1], [1,2]) isa WN.DifferentAxes
    @test whynot(==, [1], ones(2,2)) isa WN.DifferentAxes

    @test whynot(==, Dict(1=>1), Dict(2=>1)) isa WN.ChildOnlyPresentInOne
    whynot(==, Dict(1=>1), Dict()).lens === (@optic _[1])
end


@testset "show" begin
    res =  whynot(==, 1,1)
    @test res isa WN.TheSame
    @test sprint(show, res) == "TheSame: Both objects are actually the same."

    res = whynot(cmp_error, 1,1) 
    @test res isa WN.CmpRaisedException
    @test occursin("bad", sprint(show, whynot(cmp_error, 1,1)))

    res = whynot(Returns(false), :asd, :asd)
    @test res isa WN.DifferentAndNoChildren
    @test occursin(":asd", sprint(show, res))

    res = whynot(==, (a=Dict(:mykey=>2), b=2),  (a=Dict(), b=2))
    @test res isa WN.ChildOnlyPresentInOne
    @test occursin(":mykey", sprint(show, res))

    res = whynot(==, (x=[1],), (x=[1,2],) )
    @test res isa WN.DifferentAxes
    @test occursin(string(axes([1])), sprint(show, res))
    @test occursin(string(axes([1,2])), sprint(show, res))

    res =  whynot((MAB(1,2),), (MAB(1,2),))
    @test res isa WN.DifferentButSameChildren
end

struct AB
    a
    b
end

@test whynot(==, AB(1,2), AB(1,2)) isa WN.TheSame
@test whynot(==, AB(1,2), AB(1,3)).lens === (@optic _.b) ∘ identity # TODO better lens normalization
@test whynot(==, AB(1,AB(2,3)), AB(1,AB(3,3))).lens === (@optic _.a) ∘ ((@optic _.b) ∘ identity) # TODO better lens normalization

@test whynot(==, AB(1,2), AB(1,[2])) isa WN.ChildrenTraitMismatch
@test whynot(==, AB(1,2), AB(1,[2])).lens === (@optic _.b) ∘ identity # TODO better lens normalization

