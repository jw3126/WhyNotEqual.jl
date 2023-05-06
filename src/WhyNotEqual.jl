module WhyNotEqual
export whynot

using CompositionsBase: decompose
using Accessors

abstract type ChildrenT end
struct KeysT <: ChildrenT end
struct PropsT <: ChildrenT end
struct NoChildrenT <: ChildrenT end

ChildrenT(::AbstractDict) = KeysT()
ChildrenT(::AbstractArray) = KeysT()
ChildrenT(::Tuple) = KeysT()
ChildrenT(::Any) = PropsT()
ChildrenT(::Number) = NoChildrenT()
ChildrenT(::Symbol) = NoChildrenT()
ChildrenT(::AbstractString) = NoChildrenT()

function whynot(obj1, obj2)
    whynot(==, obj1, obj2)
end

struct TheSame end

function Base.show(io::IO, ::TheSame)
    print(io, "TheSame: Both objects are actually the same.")
end

struct ChildrenTraitMismatch
    obj1
    obj2
    lens
end

function normalize_lens(lens)
    pieces = decompose(lens)
    pieces2 = filter(pieces) do p
        p !== identity
    end
    if isempty(pieces)
        identity
    else
        (∘)(pieces2...)
    end
end
function compose(l1, l2) 
    normalize_lens(l1 ∘ l2)
end


function _show_prologue(io::IO, res)
    T = nameof(typeof(res))
    println(io, "$T: When applying `lens` to both objects, we get `obj1` and `obj2`.")
end
function _show_vals(io, res)
    println(io, "lens: ", repr(res.lens))
    println(io, "obj1: ", repr(res.obj1))
    println(io, "obj2: ", repr(res.obj2))    
end
function Base.show(io::IO, res::ChildrenTraitMismatch)
    _show_prologue(io, res)
    println(io, "These have different child traits.")
    t1 = ChildrenT(res.obj1)
    t2 = ChildrenT(res.obj2)
    println(io, "ChildrenT(obj1) = ", t1)
    println(io, "ChildrenT(obj2) = ", t2)
end

struct CmpRaisedException
    obj1
    obj2
    lens
    exception
    stacktrace
end

function Base.show(io::IO, res::CmpRaisedException)
    _show_prologue(io, res)
    println(io, "When trying to compare obj1 and obj2 an exception was thrown ")
    _show_vals(io, res)
    println(io, "Exception: ", res.exception)
    println(io, "Stacktrace: ", res.stacktrace)
end

struct DifferentButSameChildren
    obj1
    obj2
    lens
end

function Base.show(io::IO, res::DifferentButSameChildren)
    _show_prologue(io, res)
    println(io, "obj1 and obj2 are different, but their children are all the same.")
    _show_vals(io, res)
end


struct DifferentAndNoChildren
    obj1
    obj2
    lens
end

function Base.show(io::IO, res::DifferentAndNoChildren)
    _show_prologue(io, res)
    println(io, "obj1 and obj2 are different, but they don't have any children.")
    _show_vals(io, res)
end

struct ChildOnlyPresentInOne
    obj1
    obj2
    lens
    childlens
end

function Base.show(io::IO, res::ChildOnlyPresentInOne)
    _show_prologue(io, res)
    println(io, "obj1 and obj2 are different, there is a child present in only one of them.")
    _show_vals(io, res)
    println(io, "ChildLens: ", res.childlens)
end

struct DifferentAxes
    obj1
    obj2
    lens
end

function Base.show(io::IO, res::DifferentAxes)
    _show_prologue(io, res)
    println(io, "obj1 and obj2 are different, they have different axes.")
    println(io, "axes(obj1): ", axes(res.obj1))
    println(io, "axes(obj2): ", axes(res.obj2))
end

function whynot(cmp, obj1, obj2)
    _whynot(cmp, obj1, obj2, identity)
end

function trycmp(cmp, obj1, obj2, lens)::Union{Bool, CmpRaisedException}
    same = false
    try 
        same = cmp(obj1, obj2)
    catch err
        return CmpRaisedException(obj1, obj2, lens, err, stacktrace())
    end
    return same
end

function _whynot(cmp, obj1, obj2, lens)
    same = trycmp(cmp, obj1, obj2, lens)
    if same isa CmpRaisedException
        return same
    elseif same
        return TheSame()
    end
    trait1 = ChildrenT(obj1)
    trait2 = ChildrenT(obj2)
    if trait1 !== trait2
        return ChildrenTraitMismatch(obj1, obj2, lens)
    end
    res = _whynot(cmp, obj1, obj2, lens, trait1)
    if res === TheSame()
        return DifferentButSameChildren(obj1, obj2, lens)
    else
        return res
    end
end

function _whynot(cmp, obj1::AbstractArray, obj2::AbstractArray, lens, trait::KeysT)
    same = trycmp(cmp, axes(obj1), axes(obj2), compose(axes,lens))
    if same isa CmpRaisedException
        return same
    elseif !same
        return DifferentAxes(obj1, obj2, lens)
        # return TheSame()
    end
    indices = eachindex(obj1, obj2) 
    if isempty(indices)
        return DifferentAndNoChildren(obj1, obj2, lens)
    end
    for i in indices
        res = _whynot(cmp, obj1[i], obj2[i], compose(@optic(_[i]), lens))
        if !(res isa TheSame)
            return res
        end
    end
    return DifferentButSameChildren(obj1, obj2, lens)
end

function _whynot(cmp, obj1, obj2, lens, trait::PropsT)
    props1 = propertynames(obj1)
    props2 = propertynames(obj2)

    for pname in props1
        if !(pname in props2)
            return ChildOnlyPresentInOne(obj1, obj2, lens, PropertyLens(pname))
        end
    end
    for pname in props2
        if !(pname in props1)
            return ChildOnlyPresentInOne(obj1, obj2, lens, PropertyLens(pname))
        end
    end
    if isempty(props1)
        return DifferentAndNoChildren(obj1, obj2, lens)
    end
    for pname in props1
        childlens = PropertyLens(pname)
        res = _whynot(cmp, childlens(obj1), childlens(obj2), compose(childlens, lens))
        if !(res isa TheSame)
            return res
        end
    end
    return DifferentButSameChildren(obj1, obj2, lens)
end

function _whynot(cmp, obj1, obj2, lens, trait::KeysT)
    keys1 = keys(obj1)
    keys2 = keys(obj2)

    for key in keys1
        if !(key in keys2)
            return ChildOnlyPresentInOne(obj1, obj2, lens, IndexLens((key,)))
        end
    end
    for key in keys2
        if !(key in keys1)
            return ChildOnlyPresentInOne(obj1, obj2, lens, IndexLens((key,)))
        end
    end
    if isempty(keys1)
        return DifferentAndNoChildren(obj1, obj2, lens)
    end
    for key in keys1
        childlens = IndexLens((key,))
        res = _whynot(cmp, childlens(obj1), childlens(obj2), compose(childlens, lens))
        if !(res isa TheSame)
            return res
        end
    end
    return DifferentButSameChildren(obj1, obj2, lens)
end

function _whynot(cmp, obj1, obj2, lens, trait::NoChildrenT)
    DifferentAndNoChildren(obj1, obj2, lens)
end



end#module
