module LibreFem

using FilePathsBase

"""
    const FFBasicTypes = Union{Float64,Int64,ComplexF64}

The only types that are currently supported to communicate with FreeFem.
"""
const FFBasicTypes = Union{Float64,Int64,ComplexF64}
const basic_types = (Float64,Int64,ComplexF64)

const librefem_edp = "$(@__DIR__)/librefem.edp"

include("mmap_semaphore.jl")
include("ipc.jl")
include("runner.jl")

end # module FreeFem
