using LibreFem

const LF = LibreFem

function main()
    runner = LF.Runner(file="test2.edp", graphics=LF.no, output=true, verbosity=0)
    process = LF.run(runner)
    sleep(1)
    if process_exited(process)
        return process
    end

    x = 2
    y = 3.0
    z = 1.0im

    println("[JL]: (write) i  = ", x)
    println("[JL]: (write) f = ", y)
    println("[JL]: (write) c = ", z)

    LF.write(runner, "i", x)  # en Python seria runner.write( "i", x)
    LF.write(runner, "f", y)
    LF.write(runner, "c", z)
    LF.post(runner)  # 1

    LF.wait(runner)  # 2
    z = LF.read(runner, "c")
    x = LF.read(runner, "i")
    y = LF.read(runner, "f")

    println("[JL]: (read) i  = ", x)
    println("[JL]: (read) f = ", y)
    println("[JL]: (read) c = ", z)

    LF.post(runner)  # 3
    LF.wait(runner)  # 4
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
    LF.post(runner)  # 5

    process
end

@time process = main()
wait(process)
println("FreeFem closed (", process.exitcode, ")")
