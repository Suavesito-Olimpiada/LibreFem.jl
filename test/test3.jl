using LibreFem

const LF = LibreFem

function main()
    source =
        """
        LFNew(int,i);
        LFNew(real,f);
        LFNew(complex,c);

        int n = 3;
        int m = 5;
        LFNewV(real,arr,n);
        LFNewM(real,mat,n,m);

        LFDeclare();


        LFWait();
        LFRead(i);
        LFRead(f);
        LFRead(c);

        cout << "[FF]: (read) i = " << i << endl;
        cout << "[FF]: (read) f = " << f << endl;
        cout << "[FF]: (read) c = " << c << endl;

        i = i + i;
        f = f * f;
        c = c^2;

        cout << "[FF]: (write) i = " << i << endl;
        cout << "[FF]: (write) f = " << f << endl;
        cout << "[FF]: (write) c = " << c << endl;

        LFWrite(c);
        LFWrite(i);
        LFWrite(f);
        LFPost(); // FreeFEM side (semff) already sent the data


        for (int i = 0; i < n; ++i)
            arr(i) = i;


        for (int i = 0; i < n; ++i)
            for (int j = 0; j < m; ++j)
                mat(i,j) = (i-j)*(i+j+2);


        cout << "[FF]: (write) arr = " << arr << endl;
        cout << "[FF]: (write) mat = " << mat << endl;

        LFWriteV(arr);
        LFWriteM(mat);
        LFPost();

        LFWait();
        LFReadV(arr);
        LFReadM(mat);

        cout << "[FF]: (read) arr = " << arr << endl;
        cout << "[FF]: (read) mat = " << mat << endl;
        """

    options = FFOptions(graphics=LF.no, output=true, verbosity=0)
    runner = FFRunner(;source=source, options)
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