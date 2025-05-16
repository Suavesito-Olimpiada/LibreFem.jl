using Base: Process

@enum Option empty = -1 yes = 0 no = 1

@kwdef struct Options
    mpi = false       # parallel
    np = 2            # number of processes
    verbosity = -1    # verbosity
    graphics = empty  # graphics
    output = true     # output
    cd = false        # cd
    cdtmp = false     # cdtmp
    jc = false        # jc
    wait = empty      # wait
    check_plugin = "" # check_plugin
end
# Options(output=false, verbosity=0)

mutable struct Runner
    freefem::Cmd
    path::String
    options::Options
    const config::@NamedTuple{id::UInt, memory::Int}
    ipc::IPC
    started::Bool
    process::Process
    function Runner(; source="", file="", mpi=false, np=2, output=false, verbosity=0, graphics=empty, cd=false,
        cdtmp=false, jc=false, wait=empty, check_plugin="",
        config::Union{Nothing,@NamedTuple{id::UInt, memory::Int}}=(; id=time_ns(),
            memory=8 * 1 << 20))  # 8MB
        options = Options(; mpi, np, output, verbosity, graphics, cd, cdtmp, jc, wait, check_plugin)
        # source and file are mutually exclusive
        if (isempty(source) & isempty(file)) | (!isempty(source) & !isempty(file))
            throw(ArgumentError("source and file cannot be both set or empty."))
        end
        # temporary file to write the program
        path, io = mktemp()
        if !isempty(file)
            source = String(Base.read(file))
        end
        # add include to librefem.edp library and suround code with error handling
        source = "include \"" * librefem_edp * "\";\n" *
                 "try {\n" *
                 source * "\n" *
                 "} catch (...) { cout << \"[FF]: (closing) Ending LibreFem. Bye!\" << endl; }"
        # write and make sure it hits disk
        Base.write(io, source)
        Base.flush(io)
        configv = something(config, (; id=time_ns(), memory=128))
        mmappath = tempname()
        freefem = generate_command(path, mmappath, options, configv)
        ipc = IPC(
            mmappath,
            configv.memory,
            "semffi-$(configv.id)",
            "semff-$(configv.id)",
        )
        runner = new(freefem, path, options, configv, ipc, false)
        finalizer(r -> r.started && Base.kill(r.process), runner)
        runner
    end
end

generate_command(path, mmappath, options::Options, ipc::@NamedTuple{id::UInt, memory::Int}) =
    addenv(Cmd(convert(Vector{String}, split(string(
            options.mpi ? "FreeFem++ -f " : "mpirun -np $(options.np) FreeFem++-mpi -f ",
            string(Path(path)),
            options.verbosity < 0 ? "" : " -v $(clamp(options.verbosity, 0, 10^6))",
            options.graphics == empty ? "" : options.graphics == yes ? " -wg" : " -nw",
            options.output ? "" : " -ns", # or "-ne"
            options.cd ? " -cd" : "",
            options.cdtmp ? " -cdtmp" : "",
            options.jc ? " -jc" : "",
            options.wait == empty ? "" : options.wait == yes ? " -wait" : " -nowait",
            isempty(options.check_plugin) ? "" : " -check_plugin " * options.check_plugin,
            " -id $(ipc.id)",
            " -mem $(ipc.memory)",
            " -mmap $(mmappath)",
        )))), "FF_LOADPATH" => "$(librefem_libdir[]);;")

function Base.run(ff::Runner, args...)
    if ff.started
        kill(ff.process)
    end
    ff.process = if length(args) == 0
        Base.run(ff.freefem, stdin, stdout, stderr; wait=false)
    else
        Base.run(ff.freefem, args...; wait=false)
    end
    ff.started = true
    ff.ipc = register_vars(ff.ipc)
    return ff.process
end

function Base.kill(ff::Runner, signum=Base.SIGTERM)
    kill(ff.process, signum)
    # TODO: clean semaphores and memory map
end

run(ff::Runner, args...) = Base.run(ff, args...)

function wait(runner::Runner)
    if runner.started && process_exited(runner.process)
        throw(ArgumentError("FreeFem process not running"))
    end
    wait(runner.ipc.semff)
end

post(runner::Runner) = post(runner.ipc.semjl)

read(runner::Runner, name::String) = read(runner.ipc, name)
write(runner::Runner, name::String, val) = write(runner.ipc, val, name)
