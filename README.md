# Make llvm tool-chain

**See "make help" for more information.**

As an example, this will get the sources,  build master and install:
```bash
CC=clang CXX=clang++ make build branch=master
```

This will "build" all sub-projects for release/8.x
```bash
$ make build branch=release/8.x sub-projects="clang;clang-tools-extra;libcxx;libcxxabi;libunwind;lldb;compiler-rt;lld;polly;debuginfo-tests"
```

To rebuild the current sources and install
```bash
CC=clang CXX=clang++ make rebuild
```

To build the current sources
```bash
CC=clang CXX=clang++ make buildit
```

To install the more recently generated code
```bash
CC=clang CXX=clang++ make install
```

# clean

Remove build and install artifacts but leaves src untouched
```bash
make clean
```

# distclean

Remove all artifacts and next build will clone the sources
```bash
make distclean
```

# Notes

This fetches and makes the llvm tool chain. At this point
it's probably overkill as its now relatively easy to make it because
of the mono github repo at https://github.com/llvm/llvm-project

The following works and builds everything:

```
 $ git clone git@github.com:winksaville/llvm-project
 $ cd llvm-project
 $ mkdir build
 $ cd build
 $ CC=clang CXX=clang++ cmake -G Ninja -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;libcxx;libcxxabi;libunwind;compiler-rt;lld;lldb;polly;debuginfo-tests" -DLLVM_USE_LINKER=gold -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_INSTALL_PREFIX=$HOME/prgs/llvm-project/install -DCMAKE_BUILD_TYPE=RelWithDebInfo ../llvm
 $ ninja
 $ ninja check-all
 $ ninja install
```
