using WhyNotEqual: whynot
using Test
using Accessors
import WhyNotEqual as WN

function cmp_error(obj1, obj2)
    error("bad")
end

@test whynot(==, 1,1) isa WN.TheSame
@test whynot(Returns(true), 1,1) isa WN.TheSame
@test whynot(isequal, 1,1) isa WN.TheSame
@test whynot(===, 1,1) isa WN.TheSame
@test whynot(cmp_error, 1,1) isa WN.CmpRaisedException
@test whynot(Returns(false), 1,1) isa WN.DifferentAndNoChildren

@test whynot(==, 1,1.0) isa WN.TheSame
@test whynot(isequal, 1,1.0) isa WN.TheSame
@test whynot(===, 1,1.0) isa WN.DifferentAndNoChildren
@test whynot(cmp_error, 1,1.0) isa WN.CmpRaisedException

@test whynot(==, [1], [1,2]) isa WN.DifferentAxes


@test whynot(==, Dict(1=>1), Dict(2=>1)) isa WN.ChildOnlyPresentInOne
whynot(==, Dict(1=>1), Dict()).lens === (@optic _[1])

