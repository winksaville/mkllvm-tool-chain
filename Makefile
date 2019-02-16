# Build llvm library
#
# Originally based on [yurydelendik wasmllvm](https://gist.github.com/yurydelendik/4eeff8248aeb14ce763e)
#
# Help is available with:
# $ make help

ROOT_DIR := $(shell pwd)
LLVM_URL := https://github.com/llvm

#$(warning MAKECMDGOALS=$(MAKECMDGOALS))

LLVM_SINGLE_BRANCH := --single-branch
default-branch := release/7.x

ifeq ($(MAKECMDGOALS),rebuild)
  LLVM_PROJ := current
  GET_LLVM_SRC_TARGET := get-nothing
  LLVM_SRC_DEPTH :=
  LLVM_BRANCH :=
else ifeq ($(MAKECMDGOALS),dobuild)
  LLVM_PROJ := current
  GET_LLVM_SRC_TARGET := get-nothing
  LLVM_SRC_DEPTH :=
  LLVM_BRANCH :=
else ifeq ($(MAKECMDGOALS),buildit)
  LLVM_PROJ := current
  GET_LLVM_SRC_TARGET := get-nothing
  LLVM_SRC_DEPTH :=
  LLVM_BRANCH :=
else ifeq ($(MAKECMDGOALS),install)
  LLVM_PROJ := current
  GET_LLVM_SRC_TARGET := get-nothing
  LLVM_SRC_DEPTH :=
  LLVM_BRANCH :=
else ifeq ($(MAKECMDGOALS),clean)
  # Nothing to init
else ifeq ($(MAKECMDGOALS),distclean)
  # Nothing to init
else ifeq ($(MAKECMDGOALS),test)
  # Nothing to do 
else ifeq ($(MAKECMDGOALS),help)
  # Nohting to do
else ifeq ($(MAKECMDGOALS),build)
  ifeq ($(branch),)
    $(error "'branch' was not specified, expecting master|release/X.x|...\n")
  endif
  LLVM_PROJ := llvm-$(subst /,-,$(branch))
  GET_LLVM_SRC_TARGET := get-llvm-src-$(LLVM_PROJ)
  LLVM_SRC_DEPTH := --depth 1
  LLVM_BRANCH := -b $(branch)
else ifeq ($(MAKECMDGOALS),get-src)
  ifeq ($(branch),)
    $(error "'branch' was not specified, expecting master|release/X.x|...\n")
  endif
  LLVM_PROJ=llvm-$(subst /,-,$(branch))
  LLVM_BRANCH=-b $(branch)
  GET_LLVM_SRC_TARGET := get-llvm-src-$(LLVM_PROJ)
  $(warning "LLVM_PROJ=$(LLVM_PROJ)")
  $(warning "LLVM_BRANCH=$(LLVM_BRANCH)")
  $(warning "LLVM_SRC_DEPTH=$(LLVM_SRC_DEPTH)")
  $(warning "LLVM_SINGLE_BRANCH=$(LLVM_SINGLE_BRANCH)")
else ifeq ($(MAKECMDGOALS),default)
  LLVM_PROJ := llvm-$(subst /,-,$(default-branch))
  GET_LLVM_SRC_TARGET := get-llvm-src-$(LLVM_PROJ)
  LLVM_SRC_DEPTH := --depth 1
  LLVM_BRANCH := -b $(default-branch)
else
  $(error "No target specified, execute 'make help'")
endif

LLVM_SRC_DIR := $(ROOT_DIR)/src
LLVM_BUILD_DIR := $(LLVM_SRC_DIR)/build

LLVM_BUILD_ENGINE := Ninja
#LLVM_BUILD_ENGINE := "Unix Makefiles"
LLVM_BUILD_TYPE := Release
LLVM_INSTALL_DIR := $(ROOT_DIR)/dist
LLVM_LINK_LLVM_DYLIB := ON

# Befault build only llvm, no other projects. Otherwise provide list on command line
sub-projects :=

# Default all if desired
#sub-projects="clang;clang-tools-extra;libcxx;libcxxabi;libunwind;lldb;compiler-rt;lld;polly;debuginfo-tests"

# Default linker
LLVM_LINKER := gold
#LLVM_LINKER := bfd

ifeq ($(LLVM_PROJ),llvm-release-3.9.x)
  # if default is 3.9.x -DLLVM_USE_LINKER isn't supported
  LLVM_USE_LINKER :=
else
  LLVM_USE_LINKER=-DLLVM_USE_LINKER=$(LLVM_LINKER)
endif

# Fix a compile error that xlocale.h is not found, this is because
# Arch Linux is using glibc >= version 2.26 where it was renamed to Xlocale.h
#$(shell sudo ln -sfn /usr/include/locale.h /usr/include/xlocale.h)

verbose=0
ifeq (1,$(verbose))
  VERBOSE_CMAKE := -DCMAKE_VERBOSE_MAKEFILE=ON
endif

ifeq ($(LLVM_BUILD_ENGINE),Ninja)
MAKE := ninja
MAKEFILE := build.ninja
  ifeq ($(VERBOSE_CM KE),-DCMAKE_VERBOSE_MAKEFILE=ON)
    MAKE_FLAGS := -v
  else
    MAKE_FLAGS :=
  endif
else
MAKE := make
MAKEFILE := Makefile
MAKE_FLAGS :=
endif

build default $(LLVM_PROJ): rebuild

.PHONY: rebuild
rebuild: generated-llvm-makefile-$(LLVM_PROJ)
	make buildit
	make install

.PHONY: buildit
buildit: 
	@echo building $(LLVM_PROJ) `git -C $(LLVM_SRC_DIR) log -1 --pretty="format:hash=%h ref=%d"`
	mkdir -p $(LLVM_BUILD_DIR)
	$(MAKE) $(MAKE_FLAGS) -C $(LLVM_BUILD_DIR)
	touch built-$(LLVM_PROJ)

.PHONY: install
install:
	@echo installing $(LLVM_PROJ)
	$(MAKE) -C $(LLVM_BUILD_DIR) install
	touch installed-llvm-$(LLVM_PROJ)

generated-llvm-makefile-$(LLVM_PROJ): llvm-get-src
	@echo generate $(LLVM_PROJ) `git -C src log -1 --pretty="format:hash=%h ref=%d subject=%s"`
	mkdir -p $(LLVM_BUILD_DIR)
	cd $(LLVM_BUILD_DIR); cmake -G $(LLVM_BUILD_ENGINE) $(VERBOSE_CMAKE) $(LLVM_USE_LINKER) -DLLVM_ENABLE_PROJECTS="$(sub-projects)" -DCMAKE_INSTALL_PREFIX=$(LLVM_INSTALL_DIR) -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly -DCMAKE_BUILD_TYPE=$(LLVM_BUILD_TYPE) -DLLVM_LINK_LLVM_DYLIB=$(LLVM_LINK_LLVM_DYLIB) $(LLVM_SRC_DIR)/llvm
	touch generated-llvm-makefile-$(LLVM_PROJ)

.PHONY: clean
clean: clean-except-get

.PHONY: distclean
distclean: clean-except-get
	rm -rf $(LLVM_SRC_DIR)
	rm -f get-*

.PHONY: clean-except-get
clean-except-get: clean-built-installed
	rm -rf $(LLVM_BUILD_DIR) $(LLVM_INSTALL_DIR)

.PHONY: clean-built-installed
clean-built-installed:
	rm -f generated-llvm-makefile-* built-* installed-* main-*

llvm-get-src: $(GET_LLVM_SRC_TARGET)

get-nothing: clean

get-llvm-src-$(LLVM_PROJ): clean
	@echo get-llvm-src-$(LLVM_PROJ)
	rm -rf $(LLVM_SRC_DIR)
	git clone $(LLVM_SRC_DEPTH) $(LLVM_BRANCH) $(LLVM_URL)/llvm-project.git $(LLVM_SINGLE_BRANCH) $(LLVM_SRC_DIR)
	touch get-llvm-src-$(LLVM_PROJ)

# Quick test that we can compile and run. Add "-v" for verbose output of compilation
.PHONY: test
test:
	$(LLVM_INSTALL_DIR)/bin/clang++ -fuse-ld=gold  -g -o main-gold-static -static -pthread $$($(LLVM_INSTALL_DIR)/bin/llvm-config --ldflags) main.cpp
	./main-gold-static 1 2 3
	$(LLVM_INSTALL_DIR)/bin/clang++ -fuse-ld=lld  -g -o main-lld-shared  -pthread $$($(LLVM_INSTALL_DIR)/bin/llvm-config --ldflags) main.cpp
	./main-lld-shared 4 5 6

define helpdata
make {target} {options}

Valid targets are:
  help               this help text
  default            Get, Build, Install the default branch=$(default-branch)
  build branch=xxx   Get, Build, Install the specified branch
  get-src branch=xxx Get the specified branch
  rebuild            Buildit and Install
  buildit            build the current sources
  install            install then latest built executables and libs
  clean              Remove build/ and dist/
  distclean          remove build/, dist/ and src/
  test               Quickly test compiling main.cpp and running it statically and shared.
                     Currently static linking with lld is broken,
		     see https://bugs.llvm.org/show_bug.cgi?id=38074
                     so gold is used.

Valid options are:
  verbose=$(verbose) (0 off, 1 on)
  branch=$(branch) (master|release/8.x|...)
  sub-projects="$(sub-projects)"
    Empty is the default or can be any of:
      clang, clang-tools-extra, libcxx,
      libcxxabi, libunwind, lldb, compiler-rt,
      lld, polly, debuginfo-tests
    in a semi colon list, such as:
      sub-projects="clang;lld"
    or the complete list:
      sub-projects="clang;clang-tools-extra;libcxx;libcxxabi;libunwind;lldb;compiler-rt;lld;polly;debuginfo-tests"

  LLVM_URL=$(LLVM_URL) (URL to get source)
  LLVM_BUILD_ENGINE=$(LLVM_BUILD_ENGINE) (Ninja, "Unix Makefiles")
  LLVM_BUILD_TYPE=$(LLVM_BUILD_TYPE) (Release, Debug)
  LLVM_INSTALL_DIR=$(LLVM_INSTALL_DIR) (<Full path> to install llvm)
  LLVM_LINK_LLVM_DYLIB=$(LLVM_LINK_LLVM_DYLIB) (ON or OFF)
  LLVM_LINKER=$(LLVM_LINKER) (gold, bfd)

  Default options that can be overridden on command line using XXXX=YYYY
  for example to change build type add LLVM_BUILD_TYPE=Debug to command line.

Notes:
  In the above Get, Build and Install are conditional
  based on a file created if the operation was previously
  successful. Specifically modifying the contents of src/
  does not cause a rebuild, you'll need to specify the
  rebuild target.

  LLVM_LINK_LLVM_DYLIB=ON causes clang to default the compiled programs
  to dynamic link to the libLLVM-X.so. On linux you may need to set the
  LD_LIBRARY_PATH enviornment variable to your LLVM_INSTALL_PATH so the
  libLLVM-X.so is found when running the app. This may not be required if
  the -L<LLVM_INSTALL_PATH> is passed to clang.

  Use llvm-config to get configuration information such as
  option flags, directories for libraries and include files ...

endef

export helpdata

.PHONY: help
help:
	echo "$$helpdata"
