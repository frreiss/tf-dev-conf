################################################################################
# Fred's bash aliases for TensorFlow development
#
# To activate the aliases in this file file, run 
#   . ~/tf-def-conf/aliases.sh
# from the command-line prompt or from your .bashrc.
#

# Create a local branch for working on a TF issue
alias tfb="${HOME}/tf-dev-conf/branch.py -c"

# Check out a branch created with tfb
alias tfc="${HOME}/tf-dev-conf/branch.py"

# Create an Anaconda virtualenv for testing your builds of TensorFlow.
# Virtualenv is created as $PWD/testenv
alias tft="${HOME}/tf-dev-conf/testenv.sh"

# Configure a local copy of TF prior to build, using defaults for all prompted
# config parameters.
alias tfcc="conda activate tfbuild && bazel clean && yes '' | ./configure"

# How many subprocesses to run for TF builds
NPROC=`getconf _NPROCESSORS_ONLN`

# Extra Bazel options required to get the build to work on my machines.
# These change regularly.
HACK_OPTS=""
HACK_OPTS="${HACK_OPTS} --config=opt"
#HACK_OPTS="${HACK_OPTS} --config=xla"
#HACK_OPTS="${HACK_OPTS} --define=grpc_no_ares=true"
#HACK_OPTS="${HACK_OPTS} --incompatible_remove_native_http_archive=false"

# Aggregate options together so alias strings are shorter.
BB_OPTS="--jobs=${NPROC} ${HACK_OPTS}"

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
TEST_TARGET="${TEST_TARGET} -//tensorflow/contrib/..."
TEST_TARGET="${TEST_TARGET} -//tensorflow/core:platform_setround_test"

# Note that output is teed to a file in case we exceed the screen buffer.
BBT_COMMAND="bazel test ${BB_OPTS} --notest_verbose_timeout_warnings --keep_going ${EXCLUDE_TESTS} -- ${TEST_TARGET} | tee test.out"
alias bbt="time ${BBT_COMMAND}"

# Version of bbt alias that uses the Google Docker image.
# Useful when the build is broken for every platfrom except the Google Docker
# image.
alias bbtd="time tensorflow/tools/ci_build/ci_build.sh CPU ${BBT_COMMAND}"


# Additional regression tests that Google runs on PRs
# NOTE: You will need to do the following prereqs:
# -- Download the Android SDK tools
# -- Use <android>/tools/bin/sdkmanager to install the "platforms" and
#    "build-tools" components of the android sdk
# -- Download the Android NDK (currently version 16)
# -- Install a nightly build of TF 
ADDL_HACK_OPTS=""
ADDL_HACK_OPTS="${ADDL_HACK_OPTS} --keep_going"
ADDL_HACK_OPTS="${ADDL_HACK_OPTS} --build_tests_only"
ADDL_HACK_OPTS="${ADDL_HACK_OPTS} --test_tag_filters=-no_oss,-oss_serial,-gpu,-benchmark-test"
alias bbtt="time bazel test ${BB_OPTS} ${ADDL_HACK_OPTS} //tensorflow/contrib/..."


# Linter. Run prior to making a PR. Logs to build.out because output length
# often exceeds screen scrollback buffer size
alias bbd="time tensorflow/tools/ci_build/ci_build.sh CPU tensorflow/tools/ci_build/ci_sanity.sh 2>&1| tee lint.out"

# Full CI suite from within Google Docker image.
# Doesn't currently work on laptop.
alias bbdd="time tensorflow/tools/ci_build/ci_build.sh CPU bazel test //tensorflow/python/... 2>&1 | tee test.out"

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


