setlogging!(flag::Bool) = libffms.ff_mmap_sem_verb[] = UInt(flag)

struct Sem
    sem::libffms.Cff_psem
end

"""
    Sem(name::String, create=true)

Creates `Sem` with name `name`. By default it creates a new one, is specified
in the second argument (`create`).

# Examples
``` julia-repl
julia> Sem("worker1")
Sem(Main.LibMmapSemaphore.Cff_psem(Ptr{Main.LibMmapSemaphore.Cff_sem} @0x000000000922e510))
```
"""
function Sem(name::String, create=true)
    sem = Sem(libffms.ffsem_malloc())
    libffms.ffsem_init(sem.sem, name, create)
    finalizer(libffms.ffsem_del, sem.sem)
    sem
end

delete!(s::Sem) = libffms.ffsem_del(s.sem)
destroy!(s::Sem) = libffms.ffsem_destroy(s.sem)
init0!(s::Sem) = libffms.ffsem_init0(s.sem)
init!(s::Sem, name, create=false) = libffms.ffsem_init(s.sem, name, create)

post(s::Sem) = libffms.ffsem_post(s.sem)
wait(s::Sem) = libffms.ffsem_wait(s.sem)
trywait(s::Sem) = libffms.ffsem_trywait(s.sem)


struct Mmap
    mmap::libffms.Cff_pmmap
    path::String
    cache::Vector{UInt8}
end

"""
    Mmap(path::String, size)

Creates `Mmap` in file `path`, and size `size` in bytes.

# Examples
``` julia-repl
julia> Mmap("shared-data", 1024);
```
"""
function Mmap(path::String, size)
    mmap = Mmap(libffms.ffmmap_malloc(), path, zeros(size))
    libffms.ffmmap_init(mmap.mmap, path, size)
    finalizer(libffms.ffmmap_del, mmap.mmap)
    mmap
end

delete!(mmap::Mmap) = libffms.ffmmap_del(mmap.mmap)
destroy!(mmap::Mmap) = libffms.ffmmap_destroy(mmap.mmap)
init0!(mmap::Mmap) = libffms.ffmmap_init0(mmap.mmap)
msync(mmap::Mmap, offset, size) = libffms.ffmmap_msync(mmap.mmap, offset, size)
init!(mmap::Mmap, path, size) = libffms.ffmmap_init(mmap.mmap, path, size)

"""
    read(mmap::Mmap, nbytes::Int, offset::Int)

Read `nbytes` from `mmap` starting from `offset`.
"""
function read(mmap::Mmap, nbytes::Int, offset::Int)
    nbytes > 0 || throw(ArgumentError("Number of bytes must be positive."))
    data = @view(mmap.cache[(offset+1):(offset+nbytes)])
    ret = libffms.ffmmap_read(mmap.mmap, data, nbytes, offset)
    if ret != nbytes
        throw(EOFError())
    end
    data
end

"""
    read(mmap::Mmap, ::Type{T}, offset::Int) where {T<:BasicTypes}

Read `sizeof(T)` bytes from `mmap` starting from `offset`. Returns it of type `T`.
"""
read(mmap::Mmap, ::Type{T}, offset::Int) where {T} =
    first(reinterpret(T, read(mmap, sizeof(T), offset)))

"""
    read(mmap::Mmap, ::Type{String}, offset::Int)

Read a string from `mmap` starting at `offset`. Returns it as `String`.
The binary format is `(nbytes::Int, data::Vector{Cchar})`.
"""
function read(mmap::Mmap, ::Type{String}, offset::Int)
    # the number of bytes in the string, without '\0'
    nbytes = read(mmap, Int, offset)
    unsafe_string(pointer(read(mmap, nbytes, offset + sizeof(Int))), nbytes)
end

"""
    read(mmap::Mmap, ::Type{T}, size::NTuple(N, Int), offset::Int) where {T<:BasicTypes}

Read `prod(size)*sizeof(T)` bytes from `mmap` starting from `offset`. Returns an array of type
`T` and shape `size`.
"""
read(mmap::Mmap, ::Type{T}, size::NTuple{N,Int}, offset::Int) where {N,T<:BasicTypes} =
    reshape(reinterpret(T, read(mmap, prod(size) * sizeof(T), offset)), size)

"""
    read!(mmap::Mmap, arr::AbstractVecOrMat{T}, offset::Int) where {T<:BasicTypes}

Read `sizeof(T)*length(arr)` bytes from `mmap` starting from `offset`. Returns `arr`.
"""
function read!(mmap::Mmap, arr::AbstractVecOrMat{T}, offset::Int) where {T<:BasicTypes}
    nbytes = sizeof(T)*length(arr)
    ret = libffms.ffmmap_read(mmap.mmap, arr, nbytes, offset)
    if ret != nbytes
        throw(EOFError())
    end
    arr
end

"""
    write(mmap::Mmap, data, offset::Int)

Write `sizeof(data)` bytes to `mmap` starting from `offset`. Returns `data`.
"""
function write(mmap::Mmap, data, offset::Int)
    nbytes = sizeof(data)
    ret = GC.@preserve data libffms.ffmmap_write(mmap.mmap, Ref(data), nbytes, offset)
    if ret != nbytes
        throw(EOFError())
    end
    data
end

"""
    write(mmap::Mmap, data::String, offset::Int)

Write a string from `mmap` starting from `offset`. Returns `data`.
The binary format is `(nbytes::Int, data::Vector{Cchar})`.
"""
function write(mmap::Mmap, data::String, offset::Int)
    nbytes = sizeof(data)
    write(mmap, nbytes, offset)
    ret = GC.@preserve data libffms.ffmmap_write(mmap.mmap, pointer(data), nbytes, offset + sizeof(Int))
    if ret != nbytes
        throw(EOFError())
    end
    data
end

"""
    write(mmap::Mmap, arr::AbstractVecOrMat{T}, offset::Int) where {T<:BasicTypes}

Write `length(arr)*sizeof(T)` bytes to `mmap` starting from `offset`. Returns `arr`.
"""
function write(mmap::Mmap, arr::AbstractVecOrMat{T}, offset::Int) where {T<:BasicTypes}
    nbytes = length(arr)*sizeof(T)
    ret = GC.@preserve arr libffms.ffmmap_write(mmap.mmap, arr, nbytes, offset)
    if ret != nbytes
        throw(EOFError())
    end
    arr
end
