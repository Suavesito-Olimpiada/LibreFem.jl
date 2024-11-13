@enum Option empty = -1 yes = 0 no = 1

export FFRunner, FFOptions

"""
"""
@kwdef struct FFOptions
    verbosity = -1    # verbosity
    graphics = empty  # graphics
    output = true     # output
    cd = false        # cd
    cdtmp = false     # cdtmp
    jc = false        # jc
    wait = empty      # wait
    check_plugin = "" # check_plugin
end
# FFOptions(output=false, verbosity=0)

struct FFRunner
    freefem::Cmd
    path::String
    options::FFOptions
    config::Union{Nothing,@NamedTuple{id::UInt, memory::Int}}
    ipc::Ref{FFIPC}
    function FFRunner(;
            source="",
            sourcefile="",
            options=FFOptions(output=false, verbosity=0),
            config::Union{Nothing,@NamedTuple{id::UInt, memory::Int}}=(;id=time_ns(), memory=8*1<<20))  # 8MB
        # source and sourcefile are mutually exclusive
        if (isempty(source) & isempty(sourcefile)) | (!isempty(source) & !isempty(sourcefile))
            throw(ArgumentError("source and sourcefile cannot be both set or empty."))
        end
        # temporary file to write the program
        path, io = mktemp()
        if !isempty(sourcefile)
            source = String(Base.read(sourcefile))
        end
        # add include to librefem.edp library and suround code with error handling
        source = "include \"" * librefem_edp * "\";\n" *
            "try {\n" *
            source * "\n" *
            "} catch (...) { cout << \"[FF]: (closing) Ending LibreFem. Bye!\" << endl; }"
        # write and make sure it hits disk
        Base.write(io, source)
        Base.flush(io)
        configv = something(config, (;id=UInt(0), memory=64))
        freefem = generate_command(path, options, configv)
        ipc = FFIPC(
            "global-shared-mmap-$(configv.id)",
            configv.memory,
            "global-shared-semffi-$(configv.id)",
            "global-shared-semff-$(configv.id)",
        )
        new(freefem, path, options, config, Ref(ipc))
    end
end

generate_command(path, options::FFOptions, ipc::@NamedTuple{id::UInt, memory::Int}) =
    Cmd(convert(Vector{String}, split(string(
        "FreeFem++ -f ",
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
    ))))

function Base.run(ff::FFRunner, args...)
    process = if length(args) == 0
        run(ff.freefem, stdin, stdout, stderr; wait=false)
    else
        run(ff.freefem, args...; wait=false)
    end
    if !isnothing(ff.config)
        ff.ipc[] = register_vars(ff.ipc[])
    end
    return process
end

wait(runner::FFRunner) = wait(runner.ipc[].semff)
post(runner::FFRunner) = post(runner.ipc[].semjl)

read(runner::FFRunner, name::String) = read(runner.ipc[], name)
write(runner::FFRunner, name::String, val) = write(runner.ipc[], val, name)
