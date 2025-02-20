module LibreFem

using FilePathsBase

"""
    const BasicTypes = Union{Float64,Int64,ComplexF64}

The only types that are currently supported to communicate with FreeFem.
"""
const BasicTypes = Union{Float64,Int64,ComplexF64}

const librefem_libdir = Ref{String}()
const librefem_edp = joinpath(@__DIR__, "librefem.edp")

include("wrapper.jl")

using .LibMmapSemaphore

const libffms = LibMmapSemaphore

function __init__()
    librefem_libdir[] = libffms.librefem_libdir[]
end

include("mmap_semaphore.jl")
include("ipc.jl")
include("runner.jl")

end # module FreeFem
