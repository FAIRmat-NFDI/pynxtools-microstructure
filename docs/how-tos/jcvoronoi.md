# Multithreaded `calcGrains` with `mtex`

The `calcGrains` method of `MTex` can use `jcvoronoi` to speed up the grain reconstruction process via multithreading and a faster library.
Depending on the operating system this may require though that `jcvoronoi` needs to be compiled locally so that the its `mex` extension is
overwritten. A how-to for Ubuntu 24.04. reads as follows:

Assure to have installed `build-essentials` and a C/C++ compiler e.g. the GNU `gcc/g++ compiler`

```bash
sudo apt-get update
sudo apt-get install build-essentials
```

Start Matlab with the specific version of the `libstdc++.so.6` that was used for compiling the `mexa64` file (here assuming default Linux installation location of Matlab)

```bash
LD_PRELOAD=/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/local/MATLAB/R2024b5/bin/matlab
```

See respective references for further details:

- https://de.mathworks.com/matlabcentral/answers/1907290-how-to-manually-select-the-libstdc-library-to-use-to-resolve-a-version-glibcxx_-not-found
- https://de.mathworks.com/matlabcentral/answers/643300-why-do-i-receive-the-error-libstdc-so-6-version-glibcxx_3-4-22-not-found-when-trying-to-star
- https://datalowe.com/post/matlab-mex-files/


In Matlab compile `jcvoronoi`

```bash
# navigate in Matlab to `pynxtools-microstructure/src/pynxtools_microstructure/mtex/extern/jcvoronoi`
# compile in Matlab `mex jcvoronoi_mex.cpp`
```

Move that `jcvoronoi_mex.mexa64` file into the mex directory replacing the existent one

```bash
# `pynxtools-microstructure/src/pynxtools_microstructure/mtex/mex`
```

!!! warning "Warning"
    Depending on the compiler on the target system, this `mexa64` file might be system-specific.

