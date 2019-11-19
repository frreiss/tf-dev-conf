################################################################################
# Fred's bash/zsh aliases for TensorFlow development
#
# To activate the aliases in this file file, run 
#   . ~/tf-def-conf/aliases.sh
# from the command-line prompt or from your .bashrc.
#

TF_DEV_CONF="${HOME}/tf-dev-conf"

OS=`uname`
CPU=`uname -p`

# Create a local branch for working on a TF issue
alias tfb="${TF_DEV_CONF}/branch.py -c"

# Check out a branch created with tfb
alias tfc="${TF_DEV_CONF}/branch.py"

# Create an Anaconda virtualenv for testing your builds of TensorFlow.
# Virtualenv is created as $PWD/testenv
alias tft="${TF_DEV_CONF}/testenv.sh"

# Configure a local copy of TF prior to build, using defaults for all prompted
# config parameters.
alias tfcc="conda activate tfbuild && bazel clean && yes '' | ./configure"

# How many subprocesses to run for TF builds
#NPROC=`getconf _NPROCESSORS_ONLN`

# Extra Bazel options required to get the build to work on my machines.
# These change regularly.
HACK_OPTS=""

# TEMPORARY: Optimized builds segfault on my mac as of 9/24/2019
# TODO: Re-enable the "opt" flag
#HACK_OPTS="${HACK_OPTS} --config=opt"



# On VMs, the number of detected CPUs is the number of cores. On bare metal,
# the number of detected CPUs is the number of threads. Divide by 2 to avoid
# thrashing when on bare metal. 
if [[ "${OS}" == "Darwin" ]]
then
    # Mac laptop
    JOBS_OPTS="--jobs=HOST_CPUS*0.5"
elif [[ "${CPU}" == "s390x" ]]
then
    # Mainframe. Assume Java is messed up
    JOBS_OPTS="--host_javabase=@local_jdk//:jdk"
else
    # Anything else is assumed to be a VM
    JOBS_OPTS=""
fi

# Aggregate options together so alias strings are shorter.
BB_OPTS="${JOBS_OPTS} ${HACK_OPTS}"

# Build target for pip package prereqs. You still need to run the
# build_pip_package script after running this target; see bbpp below.
TF_PIP_TARGET=//tensorflow/tools/pip_package:build_pip_package

# Create the materials to create a Pip package
alias bbp="bazel build ${BB_OPTS} ${TF_PIP_TARGET}"

# Version of bbp that builds a TensorFlow 2.x pip package
alias bbp2="bazel build ${BB_OPTS} --config=v2 ${TF_PIP_TARGET}"

# Build the pip package from within a Docker container. Useless for creating an
# installable pip package, but useful for when the build is broken on
# everything except for Google's Docker image. Very slow on Mac.
alias bbpd="tensorflow/tools/ci_build/ci_build.sh CPU bazel build ${BB_OPTS} ${TF_PIP_TARGET}"


# Actually build the pip package (need to run bbp first)
PKG_DIR="./pip_package"
alias bbpp="rm -rf ${PKG_DIR} && ./bazel-bin/tensorflow/tools/pip_package/build_pip_package ${PKG_DIR}"

# Local regression tests

# Exclusions now commented out because the configure script now sets them
# up properly.
# Config mostly cribbed from Google's Ubuntu CI config
#TEST_FILTERS="-no_oss,-oss_serial,-gpu,-benchmark-test"
#if ([ `uname` == "Darwin" ])
#then
#    # Additional filters for Mac:
#    TEST_FILTERS="${TEST_FILTERS},-nomac"
#    TEST_FILTERS="${TEST_FILTERS},-mkldnn_contraction_kernel"
#fi
#EXCLUDE_TESTS="--test_tag_filters=${TEST_FILTERS}"
#EXCLUDE_TESTS="${EXCLUDE_TESTS} --test_size_filters=small,medium"

TEST_TARGET="//tensorflow/..."
TEST_TARGET="${TEST_TARGET} -//tensorflow/compiler/..."
TEST_TARGET="${TEST_TARGET} -//tensorflow/lite/..."
#TEST_TARGET="${TEST_TARGET} -//tensorflow/contrib/..."

# Tests that are consistently flaky on my machines
TEST_TARGET="${TEST_TARGET} -//tensorflow/python/tpu:tpu_test"
TEST_TARGET="${TEST_TARGET} -//tensorflow/python/tpu:datasets_test"
TEST_TARGET="${TEST_TARGET} -//tensorflow/python/eager:remote_test"
TEST_TARGET="${TEST_TARGET} -//tensorflow/python/debug:dist_session_debug_grpc_test"
TEST_TARGET="${TEST_TARGET} -//tensorflow/python/distribute:values_test"
TEST_TARGET="${TEST_TARGET} -//tensorflow/python/autograph/pyct:inspect_utils_test_par"
TEST_TARGET="${TEST_TARGET} -//tensorflow/examples/speech_commands:freeze_test"
#TEST_TARGET="${TEST_TARGET} -//tensorflow/core/kernels:eigen_mkldnn_contraction_kernel_test"
TEST_TARGET="${TEST_TARGET} -//tensorflow/python/keras:data_utils_test"
#TEST_TARGET="${TEST_TARGET} -//tensorflow/core:platform_setround_test"
#TEST_TARGET="${TEST_TARGET} -//tensorflow/core:platform_setround_test"
#TEST_TARGET="${TEST_TARGET} -//tensorflow/python/autograph/pyct/..."


# Note that output is teed to a file in case we exceed the screen buffer.
# Or not -- Bazel doesn't like running with non-TTY output.
#BBT_COMMAND="bazel test ${BB_OPTS} --notest_verbose_timeout_warnings --keep_going ${EXCLUDE_TESTS} -- ${TEST_TARGET} | tee test.out"
BBT_COMMAND="bazel test ${BB_OPTS} --notest_verbose_timeout_warnings --keep_going ${EXCLUDE_TESTS} -- ${TEST_TARGET}"
alias bbt="time ${BBT_COMMAND}"

# Run a single test case (test case name is first argument).
alias bbt1="bazel test ${BB_OPTS}"

# Version of bbt alias that uses the Google Docker image.
# Useful when the build is broken for every platfrom except the Google Docker
# image.
alias bbtd="time tensorflow/tools/ci_build/ci_build.sh CPU ${BBT_COMMAND}"


# OUTDATED:
# Additional regression tests that Google runs on PRs
# NOTE: You will need to do the following prereqs:
# -- Download the Android SDK tools
# -- Use <android>/tools/bin/sdkmanager to install the "platforms" and
#    "build-tools" components of the android sdk
# -- Download the Android NDK (currently version 16)
# -- Install a nightly build of TF 
#ADDL_HACK_OPTS=""
#ADDL_HACK_OPTS="${ADDL_HACK_OPTS} --keep_going"
#ADDL_HACK_OPTS="${ADDL_HACK_OPTS} --build_tests_only"
#ADDL_HACK_OPTS="${ADDL_HACK_OPTS} --test_tag_filters=-no_oss,-oss_serial,-gpu,-benchmark-test"
#alias bbtt="time bazel test ${BB_OPTS} ${ADDL_HACK_OPTS} //tensorflow/contrib/..."


# Reformat a C++ file.
alias tff="clang-format -style=Google"

# Quick and dirty Python linter.
alias bbl="${TF_DEV_CONF}/pylint.sh"

# Linter under Docker. This takes a while.
BBD_COMMAND="time tensorflow/tools/ci_build/ci_build.sh CPU "
BBD_COMMAND+="tensorflow/tools/ci_build/ci_sanity.sh "
BBD_COMMAND+="2>&1 | tee lint.out"
alias bbd=$BBD_COMMAND

# Full CI suite from within Google Docker image.
# Doesn't currently work on laptop.
#alias bbdd="time tensorflow/tools/ci_build/ci_build.sh CPU bazel test //tensorflow/python/... 2>&1 | tee test.out"
alias bbdd="time tensorflow/tools/ci_build/ci_build.sh CPU bazel test //tensorflow/python/..."

# Build API documentation, OLD VERSION
# Must be run from (tensorflow root)/tensorflow
# Puts docs into <tf root>/env/tfdocs
# Note single quotes; we don't want to replace $(pwd) with my home dir!
#alias bbg='time bazel run tools/docs:generate  --define=grpc_no_ares=true -- --src_dir=$(pwd)/docs_src/ --output_dir=$(pwd)/../env/tfdocs/' 

# Build API documentation, NEW VERSION. Run from root of source tree
alias bbg='time bazel run ${BB_OPTS} tensorflow/tools/docs:generate -- --output_dir=$(pwd)/env/tfdocs'

# Build V2 API docs. Still a work in progress
# Prerequisite steps:
# tfcc
# bbp2
# bbpp
# <Open up a second shell window>
# conda activate ./testenv
# pip install --upgrade ./pip-package/*
alias bbg2="python ./tensorflow/tools/docs/generate2.py"
#alias bbg2="time bazel run ${BB_OPTS} tensorflow/tools/docs:generate2 -- --output_dir=$(pwd)/env/tfdocs2"


