using LibreFem

const LF = LibreFem

function main()
    semff = FFSem("ff-worker1")
    semjl = FFSem("jl-main1")
    shd = FFMmap("shared-data", 1024)

    status = 1
    LF.write(shd, status, 8)
    LF.msync(shd, 0, 32)

    # run _after_ setting up semaphores and memory map
    # we won't use the default mmap and semaphores, instead our own
    options = FFOptions(graphics=LF.no, output=true, verbosity=0)
    runner = FFRunner(;sourcefile="test_worker.edp", options, config=nothing)
    process = run(runner)
    if Base.process_exited(process)
        return process
    end

    println("jl: before wait")
    println("jl: before wait 0 ff")

    LF.wait(semff)

    for i in 0:9
        println(" iter : $i")
        cff = 10.0 + i
        LF.write(shd, cff, 0)
        LF.post(semjl)

        println(" jl: before wait 2")
        LF.wait(semff)

        rff = LF.read(shd, Float64, 16)
        println(" iter = ", i, " rff = ", rff)
    end

    status = 0
    LF.write(shd, status, 8)
    LF.post(semjl)
    println("End main")
    LF.wait(semff)
    process
end

@time process = main()
while !Base.process_exited(process)
    sleep(1e-2) # wait for FreeFEM closing
end
println("FreeFEM sucessfully closed")
