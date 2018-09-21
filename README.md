# Make llvm tool-chain

**See "make help" for the most current information.**

Use llvm-config to get configuration information such as
option flags, directories for libraries and include files ...

There are a number of targets, see Makefile.
As an example, here's how to build master:
```bash
CC=clang CXX=clang++ make llvm-master
```

Here is how to build master with a verbose build
to see the complier/linker command lines:
```bash
CC=clang CXX=clang++ make verbose=true llvm-master
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

# Clone clang

For a full clone do of master:
```bash
./clone-clang.sh
```
For a shallow clone do:
```bash
./clone-clang.sh depth=1
```
For a shallow clone, branch release_50,  one branch to llvm-5.0
```bash
./clone-clang.sh depth=1 branch=release_50 single-branch=yes src-dir=llvm-5.0
```
