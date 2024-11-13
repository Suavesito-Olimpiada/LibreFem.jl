include("wrapper.jl")

using .LibFFMmapSemaphore

const libffms = LibFFMmapSemaphore

setlogging!(flag::Bool) = libffms.ff_mmap_sem_verb[] = UInt(flag)

export FFSem, FFMmap

struct FFSem
    sem::libffms.Cff_psem
end

"""
    FFSem(name::String, create=true)

Creates `FFSem` with name `name`. By default it creates a new one, is specified
in the second argument (`create`).

# Examples
``` julia-repl
julia> FFSem("worker1")
FFSem(Main.LibFFMmapSemaphore.Cff_psem(Ptr{Main.LibFFMmapSemaphore.Cff_sem} @0x000000000922e510))
```
"""
function FFSem(name::String, create=true)
    sem = FFSem(libffms.ffsem_malloc())
    libffms.ffsem_init(sem.sem, name, create)
    finalizer(libffms.ffsem_del, sem.sem)
    sem
end

delete!(s::FFSem) = libffms.ffsem_del(s.sem)
destroy!(s::FFSem) = libffms.ffsem_destroy(s.sem)
init0!(s::FFSem) = libffms.ffsem_init0(s.sem)
init!(s::FFSem, name, create=false) = libffms.ffsem_init(s.sem, name, create)

post(s::FFSem) = libffms.ffsem_post(s.sem)
wait(s::FFSem) = libffms.ffsem_wait(s.sem)
trywait(s::FFSem) = libffms.ffsem_trywait(s.sem)


struct FFMmap
    mmap::libffms.Cff_pmmap
    name::String
    cache::Vector{UInt8}
end

"""
    FFMmap(name::String, size)

Creates `FFMmap` with name `name`, and size `size` in bytes.

# Examples
``` julia-repl
julia> FFMmap("shared-data", 1024);
```
"""
function FFMmap(name::String, size)
    mmap = FFMmap(libffms.ffmmap_malloc(), name, zeros(size))
    libffms.ffmmap_init(mmap.mmap, name, size)
    finalizer(libffms.ffmmap_del, mmap.mmap)
    mmap
end

delete!(mmap::FFMmap) = libffms.ffmmap_del(mmap.mmap)
destroy!(mmap::FFMmap) = libffms.ffmmap_destroy(mmap.mmap)
init0!(mmap::FFMmap) = libffms.ffmmap_init0(mmap.mmap)
msync(mmap::FFMmap, offset, size) = libffms.ffmmap_msync(mmap.mmap, offset, size)
init!(mmap::FFMmap, name, size) = libffms.ffmmap_init(mmap.mmap, name, size)

"""
    read(mmap::FFMmap, nbytes::Int, offset::Int)

Read `nbytes` from `mmap` starting from `offset`.
"""
function read(mmap::FFMmap, nbytes::Int, offset::Int)
    nbytes > 0 || throw(ArgumentError("Number of bytes must be positive."))
    data = @view(mmap.cache[(offset+1):(offset+nbytes)])
    ret = libffms.ffmmap_read(mmap.mmap, data, nbytes, offset)
    if ret != nbytes
        throw(EOFError())
    end
    data
end

"""
    read(mmap::FFMmap, ::Type{T}, offset::Int) where {T<:FFBasicTypes}

Read `sizeof(T)` bytes from `mmap` starting from `offset`. Returns it of type `T`.
"""
read(mmap::FFMmap, ::Type{T}, offset::Int) where {T} =
    first(reinterpret(T, read(mmap, sizeof(T), offset)))

"""
    read(mmap::FFMmap, ::Type{String}, offset::Int)

Read a string from `mmap` starting at `offset`. Returns it as `String`.
The binary format is `(nbytes::Int, data::Vector{Cchar})`.
"""
function read(mmap::FFMmap, ::Type{String}, offset::Int)
    # the number of bytes in the string, without '\0'
    nbytes = read(mmap, Int, offset)
    unsafe_string(pointer(read(mmap, nbytes, offset + sizeof(Int))), nbytes)
end

"""
    read(mmap::FFMmap, ::Type{T}, size::NTuple(N, Int), offset::Int) where {T<:FFBasicTypes}

Read `prod(size)*sizeof(T)` bytes from `mmap` starting from `offset`. Returns an array of type
`T` and shape `size`.
"""
read(mmap::FFMmap, ::Type{T}, size::NTuple{N,Int}, offset::Int) where {N,T<:FFBasicTypes} =
    reshape(reinterpret(T, read(mmap, prod(size) * sizeof(T), offset)), size)

"""
    read!(mmap::FFMmap, arr::AbstractVecOrMat{T}, offset::Int) where {T<:FFBasicTypes}

Read `sizeof(T)*length(arr)` bytes from `mmap` starting from `offset`. Returns `arr`.
"""
function read!(mmap::FFMmap, arr::AbstractVecOrMat{T}, offset::Int) where {T<:FFBasicTypes}
    nbytes = sizeof(T)*length(arr)
    ret = libffms.ffmmap_read(mmap.mmap, arr, nbytes, offset)
    if ret != nbytes
        throw(EOFError())
    end
    arr
end

"""
    write(mmap::FFMmap, data, offset::Int)

Write `sizeof(data)` bytes to `mmap` starting from `offset`. Returns `data`.
"""
function write(mmap::FFMmap, data, offset::Int)
    nbytes = sizeof(data)
    ret = GC.@preserve data libffms.ffmmap_write(mmap.mmap, Ref(data), nbytes, offset)
    if ret != nbytes
        throw(EOFError())
    end
    data
end

"""
    write(mmap::FFMmap, data::String, offset::Int)

Write a string from `mmap` starting from `offset`. Returns `data`.
The binary format is `(nbytes::Int, data::Vector{Cchar})`.
"""
function write(mmap::FFMmap, data::String, offset::Int)
    nbytes = sizeof(data)
    write(mmap, nbytes, offset)
    ret = GC.@preserve data libffms.ffmmap_write(mmap.mmap, pointer(data), nbytes, offset + sizeof(Int))
    if ret != nbytes
        throw(EOFError())
    end
    data
end

"""
    write(mmap::FFMmap, arr::AbstractVecOrMat{T}, offset::Int) where {T<:FFBasicTypes}

Write `length(arr)*sizeof(T)` bytes to `mmap` starting from `offset`. Returns `arr`.
"""
function write(mmap::FFMmap, arr::AbstractVecOrMat{T}, offset::Int) where {T<:FFBasicTypes}
    nbytes = length(arr)*sizeof(T)
    ret = GC.@preserve arr libffms.ffmmap_write(mmap.mmap, arr, nbytes, offset)
    if ret != nbytes
        throw(EOFError())
    end
    arr
end
