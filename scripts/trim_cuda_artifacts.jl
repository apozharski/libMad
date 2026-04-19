using Pkg, Artifacts

trimmed = ["CUDA_Runtime_jll", "CUDA_Driver_jll", "CUDA_Compiler_jll", "CUDSS_jll"]

env = Pkg.Types.EnvCache(Base.active_project())

pkgs = Pkg.Operations.load_all_deps(env)

for pkg in pkgs
    if pkg.name ∉ trimmed
        continue
    end
    art = joinpath(Pkg.Operations.source_path(env.project_file, pkg), "Artifacts.toml")
    parsed_art = Artifacts.parse_toml(art)
    art_names = keys(parsed_art)
    for art_name in art_names
        hash = Artifacts.artifact_hash(art_name, art)
        if hash !== nothing # because windows is bad
            println(bytes2hex(hash.bytes)*"/*")
        end
    end
end
