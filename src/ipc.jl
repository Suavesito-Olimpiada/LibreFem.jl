# high level global definitions for plug-and-play

struct VarDecl
    offset::Int
    type::Int
    n::Int
    m::Int
end

struct IPC
    size::Int
    mmap::Mmap
    semjl::Sem
    semff::Sem
    vars::Dict{String,VarDecl} # name => offset, tag, (size,)
end

IPC(nmmap, memory, nsemjl, nsemff) =
    IPC(0, Mmap(nmmap, memory), Sem(nsemjl), Sem(nsemff), Dict{String,VarDecl}())

function varsize(vard::VarDecl)
    typesize = (vard.type == 1 || vard.type == 2) ? 8 : (vard.type == 4 ? 16 : -1)
    isvec = (vard.n != 0)
    ismat = (vard.n != 0 && vard.m != 0)
    typesize * (ismat ? vard.n * vard.m : (isvec ? vard.n : 1))
end

function register_vars(ipc::IPC)
    wait(ipc.semff)
    declsize = read(ipc.mmap, Int, 0)
    decloffset = 128
    offset = 128
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
    !isnothing(T) || throw(ArgumentError("wrong tagtype saved for \"$name\" variable"))
    val = if (var.n, var.m) == (0, 0)
        read(ipc.mmap, T, var.offset)::T
    elseif (var.n, 0) >= (var.n, var.m)
        read(ipc.mmap, T, (var.n,), var.offset)::AbstractVector{T}
    elseif (var.n, var.m) > (0, 0)
        read(ipc.mmap, T, (var.n, var.m), var.offset)::AbstractMatrix{T}
    end
    return copy(val)
end

write(ipc::IPC, val, name::String) =
    write(ipc.mmap, val, ipc.vars[name].offset)
