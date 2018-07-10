#!/usr/bin/env bash
# Clone llvm tool-chain.
#
# This is similar to the get-llvm-src-$(LLVM_PROJ) target,
# but might be useful if just cloning is desired.

LLVM_URL=https://github.com/llvm-mirror
LLVM_SRC_DIR=src
LLVM_BRANCH="-b master"
LLVM_SINGLE_BRANCH=--no-single-branch

# Process arguments
while [ $# -gt 0 ]; do
  case "$1" in
    depth=*)
      LLVM_SRC_DEPTH="--depth ${1#*=}"
      ;;
    branch=*)
      LLVM_BRANCH="-b ${1#*=}"
      ;;
    single-branch=yes)
      LLVM_SINGLE_BRANCH="--single-branch"
      ;;
    single-branch=no)
      LLVM_SINGLE_BRANCH="--no-single-branch"
      ;;
    src-dir=*)
      LLVM_SRC_DIR="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument, '$1' expecting:\n"
      printf "  depth=N    where N is the depth of the clone\n"
      printf "             default is full depth\n"
      printf "  branch=XX  where XX is the branch to clone\n"
      printf "             default is release_60\n"
      printf "  single_branch={yes|no}\n"
      printf "             yes means only the single branch is cloned\n"
      printf "             no means all branches are cloned\n"
      printf "             default is no\n"
      exit 1
  esac
  shift
done

echo LLVM_URL=${LLVM_URL}
echo LLVM_SRC_DIR=${LLVM_SRC_DIR}
echo LLVM_SRC_DEPTH=${LLVM_SRC_DEPTH}
echo LLVM_BRANCH=${LLVM_BRANCH}
echo LLVM_SINGLE_BRANCH=${LLVM_SINGLE_BRANCH}

git clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_URL}/llvm.git ${LLVM_SINGLE_BRANCH} ${LLVM_SRC_DIR} \
&& (git -C ${LLVM_SRC_DIR}/tools clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_SINGLE_BRANCH} ${LLVM_URL}/clang.git clang) \
&& (git -C ${LLVM_SRC_DIR}/tools/clang/tools clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_SINGLE_BRANCH} ${LLVM_URL}/clang-tools-extra.git extra) \
&& (git -C ${LLVM_SRC_DIR}/tools clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_SINGLE_BRANCH} ${LLVM_URL}/lld.git lld) \
&& (git -C ${LLVM_SRC_DIR}/tools clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_SINGLE_BRANCH} ${LLVM_URL}/polly.git polly) \
&& (git -C ${LLVM_SRC_DIR}/projects clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_SINGLE_BRANCH} ${LLVM_URL}/compiler-rt compiler-rt) \
&& (git -C ${LLVM_SRC_DIR}/projects clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_SINGLE_BRANCH} ${LLVM_URL}/openmp.git openmp) \
&& (git -C ${LLVM_SRC_DIR}/projects clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_SINGLE_BRANCH} ${LLVM_URL}/libcxx libcxx) \
&& (git -C ${LLVM_SRC_DIR}/projects clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_SINGLE_BRANCH} ${LLVM_URL}/libcxxabi libcxxabi) \
&& (git -C ${LLVM_SRC_DIR}/projects clone ${LLVM_SRC_DEPTH} ${LLVM_BRANCH} ${LLVM_SINGLE_BRANCH} https://github.com/llvm-mirror/test-suite test-suite) \
&& cd ${LLVM_SRC_DIR}
