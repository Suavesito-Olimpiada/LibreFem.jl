# high level global definitions for plug-and-play

# for now the declaration of a variable only stores the offset to the first byte, the type
# and the size $(n, m)$ (might be (0,0) for scalar, (n,0) for vector, or (n,m) for matrix)
struct VarDecl
    offset::Int
    type::Int
    n::Int
    m::Int
end

# the IPC struct stores the memory map, the semaphore to signal from Julia to FreeFem and
# from FreeFem to Julia, the size of the memory map and the pairs of names to variable
# declarations
struct IPC
    size::Int
    mmap::Mmap
    semjl::Sem
    semff::Sem
    vars::Dict{String,VarDecl} # name => offset, tag, (size,)
end

IPC(nmmap, memory, nsemjl, nsemff) =
    IPC(0, Mmap(nmmap, memory), Sem(nsemjl), Sem(nsemff), Dict{String,VarDecl}())

# In the next section is defined the IPC protocol for exchanging memory objects supported by
# the `mmap-semaphore-sv` plugin for FreeFem. Currently only the next types are supported
# for sending data
#
#   - int               ->  Int64
#   - real              ->  Float64
#   - complex           ->  ComplexF64
#   - int[int]          ->  Vector{Int64}
#   - real[int]         ->  Vector{Float64}
#   - complex[int]      ->  Vector{ComplexF64}
#   - int[int,int]      ->  Matrix{Int64}
#   - real[int,int]     ->  Matrix{Float64}
#   - complex[int,int]  ->  Matrix{ComplexF64}
#
# It is possible to send a string, but that is only used to syncronize the names of the
# variables. Tha ABI for sending strings (string => String) is [size|data].

# this routine checks if the variable declared is a vector, a matrix or a scalar
# ang returns the size of the variable in bytes ()
function varsize(vard::VarDecl)
    # type 1 (001) is Int, 2 (010) is Float64, and 4 (100) is ComplexF64.
    typesize = (vard.type == 1 || vard.type == 2) ? 8 : (vard.type == 4 ? 16 : -1)
    isvec = (vard.n != 0)
    ismat = (vard.n != 0 && vard.m != 0)
    typesize * (ismat ? vard.n * vard.m : (isvec ? vard.n : 1))
end

# the protocol to register vars is 
function register_vars(ipc::IPC)
    wait(ipc.semff)
    declsize = read(ipc.mmap, Int, 0)
    decloffset = 8
    offset = 8
    vars = Dict{String,VarDecl}()
    while decloffset < declsize
        vard = read(ipc.mmap, VarDecl, decloffset)::VarDecl
        name = read(ipc.mmap, String, decloffset + sizeof(VarDecl))::String
        size = varsize(vard)
        nbytes = vard.offset
        var = VarDecl(offset, vard.type, vard.n, vard.m)
        vars[name] = var
        decloffset += nbytes
        offset += size
    end
    IPC(offset, ipc.mmap, ipc.semjl, ipc.semff, vars)
end

function lfeltype(tag)
    if tag == 1
        Int
    elseif tag == 2
        Float64
    elseif tag == 4
        ComplexF64
    end
end

function read(ipc::IPC, name::String)
    var = ipc.vars[name]
    T = lfeltype(var.type)
    if isnothing(T)
        throw(ArgumentError("wrong tagtype saved for \"$name\" variable"))
    end
    val = if (var.n, var.m) == (0, 0)
        read(ipc.mmap, T, var.offset)::T
    elseif (var.n, 0) >= (var.n, var.m)
        read(ipc.mmap, T, (var.n,), var.offset)::AbstractVector{T}
    elseif (var.n, var.m) > (0, 0)
        read(ipc.mmap, T, (var.n, var.m), var.offset)::AbstractMatrix{T}
    end
    return copy(val)
end

function _check_array(arr::VecOrMat{T}, var::VarDecl, name::String) where {T}
    S = lfeltype(var.type)
    if isnothing(S)
        throw(ArgumentError("wrong tagtype saved for \"$name\" variable"))
    end
    sz = iszero(var.n) ? () : (iszero(var.m) ? (var.n,) : (var.n, var.m))
    if isempty(sz)
        throw(ArgumentError("read! is only for vector and matrices"))
    end
    if sz != size(arr)
        throw(ArgumentError("wrong dimentions for array arr, it must have been $S"))
    end
end

function read!(ipc::IPC, arr::VecOrMat, name::String)
    var = ipc.vars[name]
    _check_array(arr, var, name)
    read!(ipc.mmap, arr, var.offset)
    return arr
end

write(ipc::IPC, val, name::String) =
    write(ipc.mmap, val, ipc.vars[name].offset)
