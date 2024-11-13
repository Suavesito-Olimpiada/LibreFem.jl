using LibreFem

const LF = LibreFem

function main()
    options = FFOptions(graphics=LF.no, output=true, verbosity=0)
    runner = FFRunner(;sourcefile="test2.edp", options)
    process = run(runner)
    if Base.process_exited(process)
        return process
    end

    x = 2
    y = 3.0
    z = 1.0im

    println("[JL]: (write) i  = ", x)
    println("[JL]: (write) f = ", y)
    println("[JL]: (write) c = ", z)

    LF.write(runner, "i", x)
    LF.write(runner, "f", y)
    LF.write(runner, "c", z)
    LF.post(runner)

    LF.wait(runner)
    z = LF.read(runner, "c")
    x = LF.read(runner, "i")
    y = LF.read(runner, "f")

    println("[JL]: (read) i  = ", x)
    println("[JL]: (read) f = ", y)
    println("[JL]: (read) c = ", z)

    LF.wait(runner)
    arr = LF.read(runner, "arr")
    mat = LF.read(runner, "mat")
    n, m = size(mat)

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

    LF.write(runner, "arr", arr)
    LF.write(runner, "mat", mat)
    LF.post(runner)

    process
end

@time process = main()
while !Base.process_exited(process)
    sleep(0.1) # wait for FreeFem closing
end
println("FreeFem closed (", process.exitcode, ")")
