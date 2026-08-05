# libMad
`libMad` is a metapackage used to compile a shared library which contains a c interface for MadNLP.
It is currently _very much_ a work in progress.

## Installation
`libMad` can be either installed from source or from a release tarball.

### Source build
Given you have the required build software installed (namly `Julia 1.12+` and the [`JuliaC.jl` package](https://github.com/JuliaLang/JuliaC.jl), then `libMad` can be installed from source using:
```bash
mkdir build && cd build && cmake -DCMAKE_INSTALL_PREFIX=<path/to/install/to> .. && make install
```

### Release Versions
The best way to use `libMad` currently is by downloading the bundled releases available through the [Github Releases page](https://github.com/MadNLP/libMad/releases).
These tarballs contain the full stand-alone bundle of libraries necessary to use `libMad` on the three supported platforms.
In order to install them simply untar and add the path to the correct search path for your platform: `PATH` on windows, `LD_LIBRARY_PATH` on gnu/linux, and `DYLD_LIBRARY_PATH` on macos.
If using libMad from `CasADi >=v3.8.0` (which is currently in prerelease) this should be sufficient for the `CasADi` plugin loader to to load the `madnlp` and `ccopt` plugin correctly.

If you wish to use the GPU accelerated solvers in `madnlp` you need to do same with the `-cuda` release tarball.
This includes the code required to use the `CUDSSSolver` functionality.
You will need to provide system installs of the `CUDA` runtime, `CUDA` driver, and `CUDA` compiler binaries.
The GPU accelerated functionality inherits the promises of `CUDA.jl` insofar that we test primarily on GNU/linux but it _should_ work on windows as well.

## Current known issues and their workarounds:
As it currently stands we require several environment variables to be set when using libMad, to handle several issues coming from upstream Julia packages. 

### General
The following are necessary for any interface:

1. `JULIA_HSL_LIBRARY_PATH="path/to/hsl/lib"` This is necessary to use the HSL linear system solvers: `Ma*7Solver`.

### CUDA
1. `JULIA_CUDA_USE_COMPAT="false"` This is necessary to make sure that `CUDA_Driver_jll` does not attempt to fork a second julia process which fails as the binary does not exist.
2. `JULIA_CUDSS_LIBRARY_PATH="path/to/cudss/lib"` This may be necessary if the `CUDA_Runtime_Discovery` package cannot find the cuDSS libraries.

### FFI in other languages
And then several language specific issues may occur if the shared library is loaded through, e.g., the CasADi interface for python or Matlab:

#### Python
If using the library through a python interface on GNU/linux it may be necessary to set the following preload: `LD_PRELOAD="/path/to/libmad/bundle/julia/libssl.so"`.
This is necessary as python may load a different version of `libssl` than the one that `libMad` was compiled against. This leads to a failure during dynamic loading and a crash.

#### Matlab
If using the library through a matlab interface on GNU/linux it is necessary to set the following preload:

1. `LD_PRELOAD="/path/to/libmad/bundle/julia/libunwind.so"` This is necessary because Matlab ships it's own modified version of `libunwind` which causes segfaults during backtrace generation in `libMad`. **Be warned that this breaks the Matlab debugger, causing hard-crashes when attempting to open the debugger.**

## Current development
Requires `Julia 1.12+` and the [`JuliaC.jl` package](https://github.com/JuliaLang/JuliaC.jl).
The `JuliaC.jl` app should be installed and a work around for [JuliacLang/JuliaC.jl#13](https://github.com/JuliaLang/JuliaC.jl/issues/13) implemented, i.e., add `:$JULIA_LOAD_PATH` to the shim where the `JULIA_LOAD_PATH` is loaded.
Checks for these requirements are not currently failing the cmake.
To build:
```bash
mkdir build
cd build
cmake ..
make
```
Which makes the library as well as a basic executable.