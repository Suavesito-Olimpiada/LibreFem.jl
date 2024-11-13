# high level global definitions for plug-and-play

struct FFVarDecl
    offset::Int
    type::Int
    n::Int
    m::Int
end

struct FFIPC
    size::Int
    mmap::FFMmap
    semjl::FFSem
    semff::FFSem
    vars::Dict{String,FFVarDecl} # name => offset, tag, (size,)
end

FFIPC(nmmap, memory, nsemjl, nsemff) =
    FFIPC(0, FFMmap(nmmap, memory), FFSem(nsemjl), FFSem(nsemff), Dict{String,FFVarDecl}())

function varsize(vard::FFVarDecl)
    typesize = (vard.type == 1 || vard.type == 2) ? 8 : (vard.type == 4 ? 16 : -1)
    isvec = (vard.n != 0)
    ismat = (vard.n != 0 && vard.m != 0)
    typesize * (ismat ? vard.n * vard.m : (isvec ? vard.n : 1))
end

function register_vars(ipc::FFIPC)
    wait(ipc.semff)
    declsize = read(ipc.mmap, Int, 0)
    decloffset = 8
    offset = 8
    vars = Dict{String,FFVarDecl}()
    while decloffset < declsize
        vard = read(ipc.mmap, FFVarDecl, decloffset)::FFVarDecl
        name = read(ipc.mmap, String, decloffset + sizeof(FFVarDecl))::String
        size = varsize(vard)
        nbytes = vard.offset
        var = FFVarDecl(offset, vard.type, vard.n, vard.m)
        vars[name] = var
        decloffset += nbytes
        offset += size
    end
    FFIPC(offset, ipc.mmap, ipc.semjl, ipc.semff, vars)
end

function ffeltype(tag)
    if tag == 1
        Int
    elseif tag == 2
        Float64
    elseif tag == 4
        ComplexF64
    end
end

function read(ipc::FFIPC, name::String)
    var = ipc.vars[name]
    T = ffeltype(var.type)
    !isnothing(T) || throw(ArgumentError("wrong tagtype saved for \"$name\" variable"))
    val = if (var.n, var.m) == (0, 0)
        read(ipc.mmap, T, var.offset)::T
    elseif (var.n, 0) >= (var.n, var.m)
        read(ipc.mmap, T, (var.n,), var.offset)::AbstractVector{T}
    elseif (var.n, var.m) > (0, 0)
        read(ipc.mmap, T, (var.n, var.m), var.offset)::AbstractMatrix{T}
    end
    return val
end

write(ipc::FFIPC, val, name::String) =
    write(ipc.mmap, val, ipc.vars[name].offset)
