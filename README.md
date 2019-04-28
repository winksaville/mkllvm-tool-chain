# Build llvm sources

The ./Makefile provides allowing multiple versions of llvm to be built and
tested. Various variables/parameters need to be set which can be done directly
on the command line or set in \*.cfg files and passed to the makefile by
setting LLVM_CFG=XXX.cfg on the command line or export into the environment.

See [llvm getting started](http://llvm.org/docs/GettingStarted.html) for more
information on building llvm.

## Prerequesites
  * gcc 6+
  * cmake
  * ninja &| make
  * gold, bfd &| lld

## simple.sh

The bash script is a very simple script that builds the
llvm toochain. Modify/use it to build your own simple script.

Simple builds llvm;clang;compiler-rt in src/build-${id} with
logs in src/log-${id].txt and install in ~/local-${id}

```
$ ./simple.sh
Usage: ./simple.sh id
 Missing id

$ make get-submodule
$ ./simple.sh xyz
++ cmake ../llvm -G Ninja '-DLLVM_ENABLE_PROJECTS=clang;compiler-rt' -DCMAKE_INSTALL_PREFIX=/home/wink/local-xyz -DCMAKE_BUILD_TYPE=Release -DLLVM_USE_LINKER=gold
CMake Deprecation Warning at CMakeLists.txt:14 (cmake_policy):
  The OLD behavior for policy CMP0051 will be removed from a future version
  of CMake.

  The cmake-policies(7) manual explains that the OLD behaviors of all
  policies are deprecated and that a policy should be set to OLD only under
  specific short-term circumstances.  Projects should be ported to the NEW
  behavior and not rely on setting a policy to OLD.


-- The C compiler identification is GNU 8.3.0
-- The CXX compiler identification is GNU 8.3.0
...
```

## Build and install in one step
For options See `make help` or ./Makefile

Build llvm as defined by the commit associated with lib/llvm/src submodule:
```
make -j12
```
Example over riding some defaults
```
make -j6 LLVM_BUILD_ENGINE=Ninja LLVM_BUILD_TYPE=Debug
```

## Rebuild current src
Use the same options as the initial 'all' build
```
make -j12 rebuild LLVM_BUILD_ENGINE=Ninja LLVM_BUILD_TYPE=Debug
```
## Install after a rebuild
Use the same options as the initial 'all' build
```
make install LLVM_BUILD_ENGINE=Ninja LLVM_BUILD_TYPE=Debug
```
## Clean
Clean binaries
```
make clean
```
## Distributation Clean
Clean binaries and sources
```
make distclean
```
### Changing the commit associated with llvm-default.cfg

When LLVM_CFG is not specified or it is llvm-default.cfg the commit associated with the submodule is checked out as the llvm source to be built. To change to a different commit, for instance a tag `llvmorg-8.0.0` do something like:
```
git clone --recurse-submodules  https://github.com/<you>/mkllvm-tool-chain
cd mkllvm-tool-chain
git checkout -b update-lib-llvm-src-to-llvmorg-8.0.0
(cd src ; git checkout llvmorg-8.0.0)
git commit -m "Update src to llvmorg-8.0.0"
git push origin update-src-to-llvmorg-8.0.0
```
