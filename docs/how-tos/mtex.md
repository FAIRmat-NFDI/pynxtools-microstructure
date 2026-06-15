# Configure `mtex`

The `pynxtools-microstructure` plugin for `pynxtools` connects the Matlab software `mtex-toolbox/mtex` for orientation and texture analysis to `pynxtools` and thus optionally to the `NOMAD` research data management system. The software `pynxtools-microstructure` provides functionalities to export Matlab class objects from `MTex` to an HDF5 files that follows the NeXus data model, specifically contributed base classes such as `NXmicrostructure`, `NXem_ebsd`, and the `NXem` application definition. We connect `MTex` to `pynxtools-microstructure` via a GitHub submodule.

Instead of connecting to the `mtex-toolbox/mtex` GitHub repository directly, we opted to work with a FAIRmat/NOMAD-specific fork. This fork we update when necessary, tracking the `develop` branch of `MTex` and the `FAIRmat-NFDI/mtex` forks respectively by default. The fork is imported with a git submodule.

`pynxtools-microstructure` provides two key software tools: The first, located in `src/pynxtools_microstructure/matlab`, yields `MTex`-specific `MATLAB` code for exporting Matlab class objects to a NeXus/HDF5 file. This tool implements two functionalities: `src/pynxtools_microstructure/matlab/mtex/extern/hdfutils`, Matlab scripts to write HDF5 files (with file name ending `.mtex.h5`) and `src/pynxtools_microstructure/matlab/mtex/extern/scripts/Markus`, Matlab scripts that implement the respective `MTex` calls. The second key software tool is located in `src/pynxtools_microstructure`. This tool is Python code that implements a reader for the above-mentioned NeXus/HDF5 files from `MTex` using the user scripts from the first key software tool. The second key software tool uses the `dataconverter` of `pynxtools` to convert this NeXus/HDF5 file. The second tool assures that the NeXus/HDF5 follows typical conventions used by other `pynxtools` plugins and implements a few other functionalities which the above-mentioned `hdfutils` Matlab scripts does not implement yet.

The main reason for this double structure is that it is tricky and not generally considered robust how to force Matlab into using a specific version of its HDF5 library, specifically a version that offers multithreaded compression capabilities. Instead, Mathworks ships each Matlab version with a specific version of HDF5. These versions are typically not compiled, though, against advanced compression libraries like `blosc2`. Therefore, using HDF5 in Matlab in most practical cases and simple cases means working with the sequential compression `deflate` compression algorithm. Enabling a usage of advanced compression algorithms was another motivation connect to `MTex` via a fork `MTex`.

## How to update `FAIRmat-NFDI/mtex` when changes occur on the official `mtex-toolbox` side

Exemplified for updating the FAIRmat-NFDI fork's `develop` branch with the official `MTex` repository's `develop` branch (our current choice).

```bash
git clone https://github.com/FAIRmat-NFDI/mtex.git
cd mtex
git checkout develop
git remote add upstream https://github.com/mtex-toolbox/mtex.git
# git remote -v
git fetch upstream
git merge upstream/develop
git push
```

## How to update `pynxtools-microstructure` to use a specific commit of the `FAIRmat-NFDI/mtex` fork

```bash
git clone https://github.com/FAIRmat-NFDI/pynxtools-microstructure.git
git submodule sync --recursive
git submodule update --init --recursive --jobs=4
cd pynxtools-microstructure/src/pynxtools_microstructure/mtex
git fetch
git pull
# get latest commit id via e.g. `git log`
cd ../../../
./scripts/mtex.sh checkout <COMMITID>
# followed by the typical git add, commit pattern
```






