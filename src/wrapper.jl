module LibMmapSemaphore

using Scratch

const librefem_libdir = Ref{String}()
const libff_mmap_semaphore = Ref{String}()

mutable struct Global{T}
    x::Ptr{T}
    Global{T}() where {T} = new{T}(C_NULL)
end

Base.eltype(::Global{T}) where {T} = T

@inline function Base.getindex(g::Global{T}) where {T}
    @boundscheck g.x == C_NULL && throw(BoundsError(C_NULL))
    unsafe_load(g.x)
end

@inline function Base.setindex!(g::Global{T}, v) where {T}
    @boundscheck g.x == C_NULL && throw(BoundsError(C_NULL))
    unsafe_store!(g.x, v)
end

const ff_mmap_sem_verb = Global{Clong}()

function __init__()
    librefem_libdir[] = joinpath(@get_scratch!("libff_mmap_semaphore"), "lib")
    libff_mmap_semaphore[] = joinpath(librefem_libdir[], "libff-mmap-semaphore.so")
    ff_mmap_sem_verb.x = @eval Core.Intrinsics.cglobal((:ff_mmap_sem_verb, libff_mmap_semaphore[]), eltype(ff_mmap_sem_verb))
end


# typedef union
# {
#   char __size[__SIZEOF_SEM_T];
#   long int __align;
# } sem_t;

mutable struct Csem_t
    align::Clong
end

mutable struct Cff_sem
    sem::Ptr{Csem_t}
    const nm::Ptr{Cchar}
    creat::Cint
end

mutable struct Cff_mmap
    len::Csize_t
    const nm::Ptr{Cchar}
    fd::Cint
    map::Ptr{Cvoid}
    isnew::Cint
end

mutable struct Cff_pmmap
    m::Ptr{Cff_mmap}
end
mutable struct Cff_psem
    s::Ptr{Cff_sem}
end

# ff_Psem ffsem_malloc();
ffsem_malloc() = @ccall libff_mmap_semaphore[].ffsem_malloc()::Cff_psem

# void ffsem_del(ff_Psem p);
# void ffsem_del_(long *p);
ffsem_del(p::Cff_psem) = @ccall libff_mmap_semaphore[].ffsem_del(p::Cff_psem)::Cvoid
ffsem_del_(p::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffsem_del_(p::Ptr{Clong})::Cvoid

# void ffsem_destroy(ff_Psem p);
# void ffsem_destroy_(long *p);
ffsem_destroy(p::Cff_psem) = @ccall libff_mmap_semaphore[].ffsem_destroy(p::Cff_psem)::Cvoid
ffsem_destroy_(p::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffsem_destroy_(p::Ptr{Clong})::Cvoid

# void ffsem_init0(ff_Psem p);
# void ffsem_init0_(long *p);
ffsem_init0(p::Cff_psem) = @ccall libff_mmap_semaphore[].ffsem_init0(p::Cff_psem)::Cvoid
ffsem_init0_(p::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffsem_init0_(p::Ptr{Clong})::Cvoid

# void ffsem_init(ff_Psem p, const char *nmm, int crea);
# void ffsem_init_(long *p, const char *nm, int *crea, int lennm);
ffsem_init(p::Cff_psem, nmm, crea) = @ccall libff_mmap_semaphore[].ffsem_init(p::Cff_psem, nmm::Cstring, crea::Cint)::Cvoid
ffsem_init_(p::Ptr{Clong}, nmm, crea::Ptr{Cint}, lennm) = @ccall libff_mmap_semaphore[].ffsem_init_(p::Ptr{Clong}, nmm::Cstring, crea::Ptr{Cint}, lennm::Cint)::Cvoid

# long ffsem_post(ff_Psem p);
# void ffsem_post_(long *p, long *ret);
ffsem_post(p::Cff_psem) = @ccall libff_mmap_semaphore[].ffsem_post(p::Cff_psem)::Clong
ffsem_post_(p::Ptr{Clong}, ret::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffsem_post_(p::Ptr{Clong}, ret::Ptr{Clong})::Cvoid

# long ffsem_wait(ff_Psem p);
# void ffsem_wait_(long *p, long *ret);
ffsem_wait(p::Cff_psem) = @ccall libff_mmap_semaphore[].ffsem_wait(p::Cff_psem)::Clong
ffsem_wait_(p::Ptr{Clong}, ret::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffsem_wait_(p::Ptr{Clong}, ret::Ptr{Clong})::Cvoid

# long ffsem_trywait(ff_Psem p);
# void ffsem_trywait_(long *p, long *ret);
ffsem_trywait(p::Cff_psem) = @ccall libff_mmap_semaphore[].ffsem_trywait(p::Cff_psem)::Clong
ffsem_trywait_(p::Ptr{Clong}, ret::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffsem_trywait_(p::Ptr{Clong}, ret::Ptr{Clong})::Cvoid


# ff_Pmmap ffmmap_malloc();
ffmmap_malloc() = @ccall libff_mmap_semaphore[].ffmmap_malloc()::Cff_pmmap

# void ffmmap_del(ff_Pmmap p);
# void ffmmap_del_(long *p);
ffmmap_del(p::Cff_pmmap) = @ccall libff_mmap_semaphore[].ffmmap_del(p::Cff_pmmap)::Cvoid
ffmmap_del_(p::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffmmap_del_(p::Ptr{Clong})::Cvoid

# void ffmmap_destroy(ff_Pmmap p);
# void ffmmap_destroy_(long *p);
ffmmap_destroy(p::Cff_pmmap) = @ccall libff_mmap_semaphore[].ffmmap_destroy(p::Cff_pmmap)::Cvoid
ffmmap_destroy_(p::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffmmap_destroy_(p::Ptr{Clong})::Cvoid

# void ffmmap_init0(ff_Pmmap p);
# void ffmmap_init0_(long *p);
ffmmap_init0(p::Cff_pmmap) = @ccall libff_mmap_semaphore[].ffmmap_init0(p::Cff_pmmap)::Cvoid
ffmmap_init0_(p::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffmmap_init0_(p::Ptr{Clong})::Cvoid

# long ffmmap_msync(ff_Pmmap p, long off, long ln);
# void ffmmap_msync_(long *p, int *off, int *ln, long *ret);
ffmmap_msync(p::Cff_pmmap, off, ln) = @ccall libff_mmap_semaphore[].ffmmap_msync(p::Cff_pmmap, off::Clong, ln::Clong)::Clong
ffmmap_msync_(p::Ptr{Clong}, off::Ptr{Cint}, ln::Ptr{Cint}, ret::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffmmap_msync_(p::Ptr{Clong}, off::Ptr{Cint}, ln::Ptr{Cint}, ret::Ptr{Clong})::Cvoid

# void ffmmap_init(ff_Pmmap p, const char *nmm, long len);
# void ffmmap_init_(long *p, const char *nm, int *len, int lennm);
ffmmap_init(p::Cff_pmmap, name, len) = @ccall libff_mmap_semaphore[].ffmmap_init(p::Cff_pmmap, name::Cstring, len::Cint)::Cvoid
ffmmap_init_(p::Ptr{Clong}, nmm, len::Ptr{Cint}, lennm) = @ccall libff_mmap_semaphore[].ffmmap_init_(p::Ptr{Clong}, nmm::Cstring, len::Ptr{Cint}, lennm::Cint)::Cvoid

# long ffmmap_read(ff_Pmmap p, void *t, size_t n, long off);
# void ffmmap_read_(long *p, void *pt, int *ln, int *off, long *ret);
ffmmap_read(p::Cff_pmmap, t, n, off) = @ccall libff_mmap_semaphore[].ffmmap_read(p::Cff_pmmap, t::Ptr{Cvoid}, n::Csize_t, off::Clong)::Clong
ffmmap_read_(p::Ptr{Clong}, pt::Ptr{Cvoid}, ln::Ptr{Cint}, off::Ptr{Cint}, ret::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffmmap_read(p::Ptr{Clong}, pt::Ptr{Cvoid}, ln::Ptr{Cint}, off::Ptr{Clong}, ret::Ptr{Clong})::Cvoid

# long ffmmap_write(ff_Pmmap p, void *t, size_t n, long off);
# void ffmmap_write_(long *p, void *pt, int *ln, int *off, long *ret);
ffmmap_write(p::Cff_pmmap, t, n, off) = @ccall libff_mmap_semaphore[].ffmmap_write(p::Cff_pmmap, t::Ptr{Cvoid}, n::Csize_t, off::Clong)::Clong
ffmmap_write_(p::Ptr{Clong}, pt::Ref{Cvoid}, ln::Ptr{Cint}, off::Ptr{Cint}, ret::Ptr{Clong}) = @ccall libff_mmap_semaphore[].ffmmap_write(p::Ptr{Clong}, pt::Ptr{Cvoid}, ln::Ptr{Cint}, off::Ptr{Clong}, ret::Ptr{Clong})::Cvoid

end
