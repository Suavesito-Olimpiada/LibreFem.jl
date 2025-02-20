using Scratch

const LibreFem = Base.UUID("c261beb8-f411-4acc-bf3f-9b846d8b6f19")

scratchdir = get_scratch!(LibreFem, "libff_mmap_semaphore")
libdir = joinpath(scratchdir, "lib")
sourcedir = joinpath(@__DIR__, "..", "lib")

cp(sourcedir, libdir, force=true)
codepath = joinpath(libdir, "libff-mmap-semaphore.c")
pluginpath = joinpath(libdir, "mmap-semaphore-sv.cpp")
cd(libdir)
libpath = joinpath(libdir, "libff-mmap-semaphore.so")
run(`cc -shared -fPIC -pthread -o $(libpath) $(codepath)`)
run(`ff-c++ -auto $(pluginpath)`)
