# Build llvm library
#
# If target (aka. MAKECMDGOALS) is empty then llvm-default
# is assumed.
#
# A valid targets are:
#   llvm-default (the default target)
#   llvm-7.0.0
#   llvm-6.0.0
#   llvm-5.0.0
#   llvm-current
#   llvm-get-src
#   help
#   clean
#   distclean
#   test
#   rebuild
#
# Based on [yurydelendik wasmllvm](https://gist.github.com/yurydelendik/4eeff8248aeb14ce763e)
#
# Defaults:
#   verbose              (0 off, 1 on)
#   LLVM_URL             (URL to get source)
#   LLVM_BUILD_ENGINE    (Ninja, "Unix Makefiles")
#   LLVM_BUILD_TYPE      (Release, Debug)
#   LLVM_INSTALL_DIR     (Full path to install llvm)
#   LLVM_LINK_LLVM_DYLIB (ON or OFF)
#   LLVM_LINKER          (gold, bfd)

ROOT_DIR := $(shell pwd)
LLVM_URL := https://github.com/llvm-mirror

ifeq (,$(MAKECMDGOALS))
  MAKECMDGOALS := llvm-default
endif

#$(warning MAKECMDGOALS=$(MAKECMDGOALS))

LLVM_SINGLE_BRANCH := --single-branch

ifeq ($(MAKECMDGOALS),rebuild)
  LLVM_PROJ := llvm-current
  GET_LLVM_SRC_TARGET := get-nothing
  LLVM_SRC_DEPTH :=
  LLVM_BRANCH :=
else ifeq ($(MAKECMDGOALS),clean)
  # Nothing to init
else ifeq ($(MAKECMDGOALS),distclean)
  # Nothing to init
else ifeq ($(MAKECMDGOALS),llvm-master)
  LLVM_PROJ := llvm-master
  GET_LLVM_SRC_TARGET := get-llvm-src-$(LLVM_PROJ)
  LLVM_SRC_DEPTH := --depth 1
  LLVM_BRANCH :=
else ifeq ($(MAKECMDGOALS),llvm-7.0.0)
  LLVM_PROJ := llvm-7.0.0
  GET_LLVM_SRC_TARGET := get-llvm-src-$(LLVM_PROJ)
  LLVM_SRC_DEPTH := --depth 1
  LLVM_BRANCH := -b release_70
else ifeq ($(MAKECMDGOALS),llvm-6.0.0)
  LLVM_PROJ := llvm-6.0.0
  GET_LLVM_SRC_TARGET := get-llvm-src-$(LLVM_PROJ)
  LLVM_SRC_DEPTH := --depth 1
  LLVM_BRANCH := -b release_60
else ifeq ($(MAKECMDGOALS),llvm-5.0.0)
  LLVM_PROJ := llvm-5.0.0
  GET_LLVM_SRC_TARGET := get-llvm-src-$(LLVM_PROJ)
  LLVM_SRC_DEPTH := --depth 1
  LLVM_BRANCH := -b release_39
else ifeq ($(MAKECMDGOALS),llvm-get-src)
  ifeq ($(llvm-branch),)
    $(error "llvm-branch was not specified, expecting master|release_60|...\n" \
"You may also want to supply LLVM_SRC_DEPTH=--depth 1 and\n" \
"LLVM_SINGLE_BRANCH=--no-single-branch as default is --single-branch.")
  endif
  LLVM_PROJ=llvm-$(llvm-branch)
  LLVM_BRANCH=-b $(llvm-branch)
  GET_LLVM_SRC_TARGET := get-llvm-src-$(LLVM_PROJ)
  $(warning "LLVM_PROJ=$(LLVM_PROJ)")
  $(warning "LLVM_BRANCH=$(LLVM_BRANCH)")
  $(warning "LLVM_SRC_DEPTH=$(LLVM_SRC_DEPTH)")
  $(warning "LLVM_SINGLE_BRANCH=$(LLVM_SINGLE_BRANCH)")
else ifeq ($(MAKECMDGOALS),llvm-current)
  LLVM_PROJ := llvm-current
  GET_LLVM_SRC_TARGET := get-nothing
  LLVM_SRC_DEPTH :=
  LLVM_BRANCH :=
else ifeq ($(MAKECMDGOALS),llvm-default)
  ## Use get-default-llvm-src which gets the "current" submodule
  #LLVM_PROJ := llvm-default
  #GET_LLVM_SRC_TARGET := get-default-llvm-src
  #LLVM_SRC_DEPTH := --depth 1
  #LLVM_URL :=
  #LLVM_BRANCH :=

  # Default to llvm-5.0.0
  LLVM_PROJ := llvm-5.0.0
  GET_LLVM_SRC_TARGET := get-llvm-src-$(LLVM_PROJ)
  LLVM_SRC_DEPTH := --depth 1
  LLVM_BRANCH := -b release_50
else ifeq ($(MAKECMDGOALS),test)
  # Nothing to do 
else ifeq ($(MAKECMDGOALS),help)
  # Nohting to do
else
  $(error Uknown target '$(MAKECMDGOALS)', someone did not pass a goal)
endif

LLVM_SRC_DIR := $(ROOT_DIR)/src
LLVM_BUILD_DIR := $(ROOT_DIR)/build

LLVM_BUILD_ENGINE := Ninja
#LLVM_BUILD_ENGINE := "Unix Makefiles"
LLVM_BUILD_TYPE := Release
LLVM_INSTALL_DIR := $(ROOT_DIR)/dist
LLVM_LINK_LLVM_DYLIB := ON

LLVM_LINKER := gold
#LLVM_LINKER := bfd
ifeq (llvm-5.0.0,$(LLVM_PROJ))
  # 3.9.1 doesn't support -DLLVM_USE_LINKER so make it empty to supress a warning
  #LLVM_USE_LINKER :=

  # Fix a compile error that xlocale.h is not found, this is because
  # Arch Linux is using glibc >= version 2.26 where it was renamed to Xlocale.h
  #$(shell sudo ln -sfn /usr/include/locale.h /usr/include/xlocale.h)
else
  LLVM_USE_LINKER=-DLLVM_USE_LINKER=$(LLVM_LINKER)
endif

verbose=0
ifeq (1,$(verbose))
  VERBOSE_CMAKE := -DCMAKE_VERBOSE_MAKEFILE=ON
endif

ifeq ($(LLVM_BUILD_ENGINE),Ninja)
MAKE := ninja
MAKEFILE := build.ninja
  ifeq ($(VERBOSE_CMAKE),-DCMAKE_VERBOSE_MAKEFILE=ON)
    MAKE_FLAGS := -v
  else
    MAKE_FLAGS :=
  endif
else
MAKE := make
MAKEFILE := Makefile
MAKE_FLAGS :=
endif

$(LLVM_PROJ): built-llvm-$(LLVM_PROJ)

.PHONY: rebuild
rebuild: clean-built-installed
	@echo building $(LLVM_PROJ) `git -C $(LLVM_SRC_DIR) log -1 --pretty="format:hash=%h ref=%d subject=%s"`
	$(MAKE) $(MAKE_FLAGS) -C $(LLVM_BUILD_DIR)
	touch built-llvm-$(LLVM_PROJ)
	@echo installing $(LLVM_PROJ)
	$(MAKE) -C $(LLVM_BUILD_DIR) install
	touch installed-llvm-$(LLVM_PROJ)

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
	rm -f built-* installed-* main-*

built-llvm-$(LLVM_PROJ): $(LLVM_BUILD_DIR)/generated-llvm-makefile-$(LLVM_PROJ)
	make rebuild

$(LLVM_BUILD_DIR)/generated-llvm-makefile-$(LLVM_PROJ): $(GET_LLVM_SRC_TARGET)
	@echo generate $(LLVM_PROJ) `git -C src log -1 --pretty="format:hash=%h ref=%d subject=%s"`
	mkdir -p $(LLVM_BUILD_DIR)
	cd $(LLVM_BUILD_DIR); cmake -G $(LLVM_BUILD_ENGINE) $(VERBOSE_CMAKE) $(LLVM_USE_LINKER) -DCMAKE_INSTALL_PREFIX=$(LLVM_INSTALL_DIR) -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly -DCMAKE_BUILD_TYPE=$(LLVM_BUILD_TYPE) -DLLVM_LINK_LLVM_DYLIB=$(LLVM_LINK_LLVM_DYLIB) $(LLVM_SRC_DIR)
	touch $(LLVM_BUILD_DIR)/generated-llvm-makefile-$(LLVM_PROJ)

get-nothing: clean

get-default-llvm-src:
	@echo get-default-llvm-src
	make clean
	rm -rf $(LLVM_SRC_DIR)
	mkdir $(LLVM_SRC_DIR)
	git submodule init
	git submodule update $(LLVM_SRC_DEPTH)
	touch get-default-llvm-src

llvm-get-src: $(GET_LLVM_SRC_TARGET)

get-llvm-src-$(LLVM_PROJ):
	@echo get-llvm-src-$(LLVM_PROJ)
	make clean
	rm -rf $(LLVM_SRC_DIR)
	git clone $(LLVM_SRC_DEPTH) $(LLVM_BRANCH) $(LLVM_URL)/llvm.git $(LLVM_SINGLE_BRANCH) $(LLVM_SRC_DIR)
	git -C $(LLVM_SRC_DIR)/tools clone ${LLVM_SRC_DEPTH} $(LLVM_BRANCH) $(LLVM_SINGLE_BRANCH) ${LLVM_URL}/clang.git clang
	git -C $(LLVM_SRC_DIR)/tools/clang/tools clone ${LLVM_SRC_DEPTH} $(LLVM_BRANCH) $(LLVM_SINGLE_BRANCH) ${LLVM_URL}/clang-tools-extra.git extra
	git -C $(LLVM_SRC_DIR)/tools clone ${LLVM_SRC_DEPTH} $(LLVM_BRANCH) $(LLVM_SINGLE_BRANCH) ${LLVM_URL}/lld.git lld
	git -C $(LLVM_SRC_DIR)/tools clone ${LLVM_SRC_DEPTH} $(LLVM_BRANCH) $(LLVM_SINGLE_BRANCH) ${LLVM_URL}/polly.git polly
	git -C $(LLVM_SRC_DIR)/projects clone ${LLVM_SRC_DEPTH} $(LLVM_BRANCH) $(LLVM_SINGLE_BRANCH) ${LLVM_URL}/compiler-rt.git compiler-rt
	git -C $(LLVM_SRC_DIR)/projects clone ${LLVM_SRC_DEPTH} $(LLVM_BRANCH) $(LLVM_SINGLE_BRANCH) ${LLVM_URL}/openmp.git openmp
	git -C $(LLVM_SRC_DIR)/projects clone ${LLVM_SRC_DEPTH} $(LLVM_BRANCH) $(LLVM_SINGLE_BRANCH) ${LLVM_URL}/libcxx.git libcxx
	git -C $(LLVM_SRC_DIR)/projects clone ${LLVM_SRC_DEPTH} $(LLVM_BRANCH) $(LLVM_SINGLE_BRANCH) ${LLVM_URL}/libcxxabi.git libcxxabi
	git -C $(LLVM_SRC_DIR)/projects clone ${LLVM_SRC_DEPTH} $(LLVM_BRANCH) $(LLVM_SINGLE_BRANCH) ${LLVM_URL}/test-suite.git test-suite
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
  help          this help text
  clean         Remove build/ and dist/
  distclean     remove build/, dist/ and src/
  llvm-master   Get, Build, Install master
  llvm-7.0.0    Get, Build, Install release_70
  llvm-6.0.0    Get, Build, Install release_60
  llvm-5.0.0    Get, Build, Install release_50
  llvm-default  Get, Build, Install the default which is llvm-5.0.0
  llvm-current  Build, Install what ever is in src/
  llvm-get-src  Only gets the sources of the specified branch
                llvm-branch=xxx where xxx is {master|release_60|...}.
                You may also want to supply LLVM_DEPTH=--depth 1 and
                LLVM_SINGLE_BRANCH=--no-single-branch as default is --single-branch
  test          quick test compiling main.cpp and running it statically and shared.
                Currently static linking with lld is broken,
		see https://bugs.llvm.org/show_bug.cgi?id=38074
                so gold is used.
  rebuild       Rebuild the sources unconditionally

Valid options are:
  verbose=$(verbose) (0 off, 1 on)
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
