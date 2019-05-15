#!/bin/bash
# Builds llvm;clang;lld;compiler-rt in build-${id} with
# logs in log-${id].txt and install in ~/local-${id}

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

enabled_projects="clang;lld;compiler-rt"

# Use set -x so we see the commands.
# Substitue check-all for others like check-tsan:
cmd="set -x ; \
  cmake ../llvm -G Ninja -DLLVM_ENABLE_PROJECTS=\"${enabled_projects}\" -DCMAKE_INSTALL_PREFIX=${install_dir} -DCMAKE_BUILD_TYPE=Release -DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON && \
  ninja -j${jobcnt} -v && \
  ninja -j${jobcnt} -v check-all"

# Set the pipefail flag so the exit status is from ${cmd} and not time or tee
set -o pipefail

# In a subshell time the evaluated command and log the output
# of the subshell with 2>&1 | tee $(log). The log includes the time
# the command took as well as all output from the commands.
( time eval ${cmd} ) 2>&1 | tee ${log}
