using LibreFem

using Printf

const LF = LibreFem

function main()
    semjl = LF.Sem("ff-main1")
    semff = LF.Sem("ff-worker1")
    shd   = LF.Mmap("shared-data", 1024)

    # run _after_ setting up semaphores and memory map
    # we won't use the default mmap and semaphores, instead our own
    runner = LF.Runner(;file="test1.edp", config=nothing, graphics=LF.no, output=true, verbosity=0)
    process = LF.run(runner)
    println(process)
    sleep(1)
    if Base.process_exited(process)
        return process
    end

    # send and receive various data types
    #   value   Julia               FreeFEM  size
    i = 2     # Int64            -> int      8  bytes
    f = 3.0   # Float64          -> real     8  bytes
    c = 1.0im # Complex{Float64} -> complex  16 bytes
    s = "str" # String           -> string   3(4) bytes

    println("[JL]: (write) i  = ", i)
    println("[JL]: (write) f = ", f)
    println("[JL]: (write) c = ", c)
    println("[JL]: (write) s = ", s)

    # send data Julia -> FreeFEM, posting on semjl
    LF.write(shd, i, 0)  # offset is 0
    LF.write(shd, f, 8)  # offset is 8, after Int64
    LF.write(shd, c, 16) # offset is 16, after Int64
    LF.write(shd, s, 32) # offset is 32, after Complex{Float64}
    LF.post(semjl)  # Julia side (semjl) already sent the data

    # receive data Julia <- FreeFEM, waiting on semff
    LF.wait(semff)  # wait for FreeFEM side to send the data
    c = LF.read(shd, typeof(c), 0)  # offset is 16; typeof(c) == Complex{Float64}
    i = LF.read(shd, typeof(i), 16) # offset is 8; typeof(i) == Int64
    f = LF.read(shd, typeof(f), 24) # offset is 8; typeof(f) == Float64
    s = LF.read(shd, typeof(s), 32)

    println("[JL]: (read) i  = ", i)
    println("[JL]: (read) f = ", f)
    println("[JL]: (read) c = ", c)
    println("[JL]: (read) s = ", s)

    # notify freefem to overwrite in the mmap after having read the data
    LF.post(semjl)

    println("[JL]: (test)")

    n = 0
    m = 0
    LF.wait(semff)
    n = LF.read(shd, Int64, 0)
    m = LF.read(shd, Int64, 8)
    println("[JL]: (test) n = ", n, ", m = ", m)
    arr = LF.read(shd, Float64, (n,), 8+8)
    mat = LF.read(shd, Float64, (n,m), 8+8+8n)

    # create and array and read the information in it
    # arr = Vector{Float64}(undef, n)
    # LF..read!(shd, arr, 8+8)
    # arr = Matrix{Float64}(undef, n, m)
    # LF..read!(shd, arr, 8+8+8n)

    println("[JL]: (read) n   = ", n)
    println("[JL]: (read) m   = ", m)
    println("[JL]: (read) arr = ", arr)
    print("[JL]: (read) mat = ")
    display(mat)

    for i in n:-1:1
        arr[i] = i
    end

    # column first
    for j in 1:m
        for i in 1:n
            mat[i, m-j+1] = (j-i)*(j+i)
        end
    end

    println("[JL]: (write) arr = ", arr)
    print("[JL]: (write) mat = ")
    display(mat)

    LF.write(shd, arr, 8+8)
    LF.write(shd, mat, 8+8+8n)
    LF.post(semjl)

    process
end

@time process = main()
wait(process)
println("FreeFem closed (", process.exitcode, ")")
