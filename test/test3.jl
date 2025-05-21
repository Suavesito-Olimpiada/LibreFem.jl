using LibreFem

const LF = LibreFem

function main()
    source =
    """
        int i;
        real f;
        complex c;
        LFNew(int, "i");
        LFNew(real, "f");
        LFNew(complex, "c");

        int n = 3;
        int m = 5;
        real[int] arr(n);
        real[int,int] mat(n, m);
        LFNewV(real, "arr", n);
        LFNewM(real, "mat", n, m);

        LFInit();


        LFWait();  // 1
        LFRead("i", i);
        LFRead("f", f);
        LFRead("c", c);

        cout << "[FF]: (read) i = " << i << endl;
        cout << "[FF]: (read) f = " << f << endl;
        cout << "[FF]: (read) c = " << c << endl;

        i = i + i;
        f = f * f;
        c = c^2;

        cout << "[FF]: (write) i = " << i << endl;
        cout << "[FF]: (write) f = " << f << endl;
        cout << "[FF]: (write) c = " << c << endl;

        LFWrite("c", c);
        LFWrite("i", i);
        LFWrite("f", f);
        LFPost();  // 2


        for (int i = 0; i < n; ++i)
            arr(i) = i;


        for (int i = 0; i < n; ++i)
            for (int j = 0; j < m; ++j)
                mat(i,j) = (i-j)*(i+j+2);


        cout << "[FF]: (write) arr = " << arr << endl;
        cout << "[FF]: (write) mat = " << mat << endl;

        LFWriteV("arr", arr);
        LFWriteM("mat", mat);
        LFPost();  // 3

        LFWait();  // 4
        LFReadV("arr", arr);
        LFReadM("mat", mat);

        cout << "[FF]: (read) arr = " << arr << endl;
        cout << "[FF]: (read) mat = " << mat << endl;
    """

    runner = LF.Runner(; source=source, graphics=LF.no, output=true, verbosity=0)
    process = LF.run(runner)
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
    LF.post(runner)  # 1

    LF.wait(runner)  # 2
    z = LF.read(runner, "c")
    x = LF.read(runner, "i")
    y = LF.read(runner, "f")

    println("[JL]: (read) i  = ", x)
    println("[JL]: (read) f = ", y)
    println("[JL]: (read) c = ", z)

    LF.wait(runner)  # 3
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
            mat[i, m-j+1] = (j - i) * (j + i)
        end
    end

    println("[JL]: (write) arr = ", arr)
    print("[JL]: (write) mat = ")
    display(mat)

    LF.write(runner, "arr", arr)
    LF.write(runner, "mat", mat)
    LF.post(runner)  # 4

    return process
end

@time process = main()
wait(process)
println("FreeFem closed (", process.exitcode, ")")
