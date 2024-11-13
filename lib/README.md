# Libraries

This library is the connection between FreeFEM y Julia. It's three files

  - `libff-mmap-semaphore.h`, and
  - `libff-mmap-semaphore.c`.
  - `ff-mmap-semaphore.cpp`.

The file `ff-mmap-semaphore.cpp` is the implementation of the plugin from
FreeFEM side.

## Compilation

The library is shipped in two files `libff-mmap-semaphore.cpp` and
`libff-mmap-semaphore.c`. For compiling to two shared libraries you need to do

```
    $ cc -shared -fPIC -o libff-mmap-semaphore.so libff-mmap-semaphore.c
    $ ff-c++ -auto mmap-semaphore-sv.cpp
    $ rm *.o
```

This will generate `libff-mmap-semaphore.{so,dll,dylib}`, loaded from the Julia side; and
`ff-mmap-semaphore.{so,dll,dylib}`, loaded from the FreeFem side.
