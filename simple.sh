#!/bin/bash
# Builds llvm;clang;lld;compiler-rt in build-${id} with
# logs in log-${id].txt and install in ~/local-${id}
#
# AFAIK, llvm is always built
#Examples:
# Default it builds clang
# $ ./simple.sh clang
#
# To build only llvm either set enabled_projects=llvm or none
# these are exactly the same
# $ enabled_projects=none ./simple.sh llvm
# $ enabled_projects=llvm ./simple.sh llvm
#
# Make clang lld and compiler-rt
# $ enabled_projects= ./simple.sh clang-lld-compiler-rt

id=$1
log=../log-${id}.txt
build_dir=build-${id}
install_dir=~/local-${id}

if [ "${id}" == "" ]; then printf "Usage: $0 id\n Missing id\n"; exit 1; fi

mkdir -p ${build_dir}
cd ${build_dir}

if [ "${jobcnt}" == "" ]; then
  jobcnt=${jobcnt:-$(( $(nproc) - 1 ))};
fi
if [[ ${jobcnt} < 1 ]]; then jobcnt=1; fi

rm -f ${log}
touch ${log}

if [ "${enabled_projects}" == "none" ]; then
  # Make it empty
  enabled_projects=
elif [ "${enabled_projects}" != "" ]; then
  # Use what was passed, do no-op comamnd ":"
  :
else
  # Take a default

  others="libclc;parallel-libs;pstl;openmp;llgo"
  ok="clang;clang-tools-extra;libcxx;libcxxabi;libunwind;compiler-rt;lld;lldb;polly;debuginfo-tests"

  # All projects
  #enabled_projects="all"

  # Most projects, this does compile
  #enabled_projects="clang;clang-tools-extra;libcxx;libcxxabi;libunwind;compiler-rt;lld;lldb;polly;debuginfo-tests"

  # Typical list I test
  #enabled_projects="clang;lld;compiler-rt"

  #enabled_projects="clang;llgo"
  enabled_projects="clang"

fi

# Use set -x so we see the commands.
# Substitue check-all for others like check-tsan:
cmd="set -x ; \
  cmake ../llvm -G Ninja -DLLVM_ENABLE_PROJECTS=\"${enabled_projects}\" -DCMAKE_INSTALL_PREFIX=${install_dir} -DCMAKE_BUILD_TYPE=Release && \
  ninja -j${jobcnt} -v"

#  ninja -j${jobcnt} -v && \
#  ninja -j${jobcnt} -v check-tsan"

# Set the pipefail flag so the exit status is from ${cmd} and not time or tee
set -o pipefail

# In a subshell time the evaluated command and log the output
# of the subshell with 2>&1 | tee $(log). The log includes the time
# the command took as well as all output from the commands.
( time eval ${cmd} ) 2>&1 | tee ${log}
