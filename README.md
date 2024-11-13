# LibreFem.jl

This library is an IPC connection between FreeFEM y Julia. It works using
a shared memory map and semaphores.

Check the examples in `test`, all of them should be able to run as follows

 1. First, get the code and setup the environment,

    ```
    $ git clone "https://github.com/Suavesito-Olimpiada/LibreFem.jl"
    $ cd LibreFem.jl/test/
    $ julia -q --project=. -e "using Pkg; Pkg.instantiate()"
    ```

 2. Then they should run in this environment,

    ```
    $ julia -q --project=. test1.jl
    $ julia -q --project=. test2.jl
    $ julia -q --project=. test3.jl
    $ julia -q --project=. test_main.jl
    ```

## Libraries

The files `lib/libff-mmap-semaphore.{so,dll,dylib}`,
`lib/mmap-semaphore.{so,dll,dylib}` need to exist, check out
[`lib/README.md`](lib/README.md).
