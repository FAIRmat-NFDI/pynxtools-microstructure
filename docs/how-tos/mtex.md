# Configure `mtex`

The `pynxtools-microstructure` plugin for `pynxtools` connects the Matlab software `mtex-toolbox/mtex` for orientation and texture analysis to `pynxtools` and the `NOMAD` RDM system.
It provides functionalities to export the Matlab class objects that `MTex` instantiates to an HDF5 files that follows the NeXus data model, using contributed definitions,
such as `NXmicrostructure`, and other accepted NeXus base classes like `NXem_ebsd`. We connect `MTex` to `pynxtools-microstructure` via a GitHub submodule.

Instead of connecting to the `mtex-toolbox/mtex` GitHub repository directly, we opted to work with a FAIRmat/NOMAD-specific fork that we update when necessary.
By default we track the `develop` branch of `MTex` and the `FAIRmat-NFDI/mtex` fork. This forked GitHub repository is imported by `pynxtools-microstructure`
as a submodule.

`pynxtools-microstructure` provides two key software tools: The first is located in `src/pynxtools_microstructure/matlab`, `MTex`-specific Matlab code for exporting
Matlab class objects to a NeXus/HDF5 file. This first tool implements two functionalities i) `src/pynxtools_microstructure/matlab/mtex/extern/hdfutils`, a set of
Matlab code to write HDF5 files and ii) `src/pynxtools_microstructure/matlab/mtex/extern/scripts/Markus`, Matlab scripts that implement the `MTex` calls.

The second key software tool is located in `src/pynxtools_microstructure`. This is Python code that implements a reader for the above-mentioned NeXus/HDF5 files from `MTex` using the user scripts from the first key software tool.
The second key software tool uses the `dataconverter` of `pynxtools` to convert this NeXus/HDF5 file to one that matches conventions typically used for other `pynxtools` plugins and for adding functionalities which the above-mentioned `hdfutils` Matlab code does not implement yet.

The main reason for this double structure is that it is tricky and not generally considered robust how to force Matlab into using a specific version of the HDF5 library, specifically a version that would offer multithreaded compression capabilities. Instead, Matlab versions from MathWorks are distributed their a specific version of HDF5. These versions though are typically not compiled against advanced compression libraries like `blosc2`
and thus offer merely sequential compression capabilities via `deflate`. Given that we would like to use advanced compression libraries and make additions to `MTex` motivated the current design with using an own `MTex` fork.

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






