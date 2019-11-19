#!/usr/bin/env bash

################################################################################
# pylint.sh
#
# Quick TensorFlow Pylint run for use on Macs and other machines that don't
# have the oomph to scan 3500 files with pylint. Based on code from
# tensorflow/tools/ci_build/ci_sanity.sh
#
# Note that, before committing a large change, you should run a full ci-sanity
# check -- see the "bbd" alias in aliases.sh.
#
# Run this script from the root of your TensorFlow source code tree, using the
# Anaconda virtualenv that buildenv.sh creates.
#
# Usage:
# conda activate tfbuild && ~/tf-dev-conf/pylint.sh 
################################################################################
# CONSTANTS


# Number of cores on current machine
_N_CORES=`getconf _NPROCESSORS_ONLN`

# Location of this script. May need to be modified if the path has funky stuff
# like symlinks.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PYLINTRC_FILE="${PWD}/tensorflow/tools/ci_build/pylintrc"
PYLINT_BIN="pylint"

################################################################################
# FUNCTIONS

# Magic git command to find the files that your PR will change
get_changed_files() {
    git whatchanged --name-only --pretty="" origin..HEAD

    # Also list files not yet checked in
    git ls-files --modified
}

# Simplified version of the function by the same name in the original script
# Only does incremental listing, and gets everything in the PR
get_py_files_to_check() {
  CHANGED_PY_FILES=$(get_changed_files | grep '.*\.py$')

  # Do not include files removed in the last non-merge commit.
  PY_FILES=""
  for PY_FILE in ${CHANGED_PY_FILES}; do
    if [[ -f "${PY_FILE}" ]]; then
      PY_FILES="${PY_FILES} ${PY_FILE}"
    fi
  done

  echo "${PY_FILES}"
}

die() {
  echo $@
  exit 1
}


# Greatly simplified version of the function in ci_sanity.sh by the same name
# actually runs outside the CI server.
do_pylint() {
  # TODO: Keep this whitelist synchronized with the original script
  ERROR_WHITELIST="^tensorflow/python/framework/function_test\.py.*\[E1123.*noinline "\
"^tensorflow/python/platform/default/_gfile\.py.*\[E0301.*non-iterator "\
"^tensorflow/python/platform/default/_googletest\.py.*\[E0102.*function\salready\sdefined "\
"^tensorflow/python/feature_column/feature_column_test\.py.*\[E0110.*abstract-class-instantiated "\
"^tensorflow/contrib/layers/python/layers/feature_column\.py.*\[E0110.*abstract-class-instantiated "\
"^tensorflow/contrib/eager/python/evaluator\.py.*\[E0202.*method-hidden "\
"^tensorflow/contrib/eager/python/metrics_impl\.py.*\[E0202.*method-hidden "\
"^tensorflow/contrib/rate/rate\.py.*\[E0202.*method-hidden "\
"^tensorflow/python/platform/gfile\.py.*\[E0301.*non-iterator "\
"^tensorflow/python/keras/callbacks\.py.*\[E1133.*not-an-iterable "\
"^tensorflow/python/keras/engine/base_layer.py.*\[E0203.*access-member-before-definition "\
"^tensorflow/python/keras/layers/recurrent\.py.*\[E0203.*access-member-before-definition "\
"^tensorflow/python/kernel_tests/constant_op_eager_test.py.*\[E0303.*invalid-length-returned "\
"^tensorflow/python/keras/utils/data_utils.py.*\[E1102.*not-callable"

  echo "ERROR_WHITELIST=\"${ERROR_WHITELIST}\""

  PYTHON_SRC_FILES=$(get_py_files_to_check)

  if [[ -z ${PYTHON_SRC_FILES} ]]; then
    echo ""
    echo "do_pylint found no Python files to check. Returning."
    return 0
  fi

  if [[ ! -f "${PYLINTRC_FILE}" ]]; then
    die "ERROR: Cannot find pylint rc file at ${PYLINTRC_FILE}"
  fi

  NUM_SRC_FILES=$(echo ${PYTHON_SRC_FILES} | wc -w)
  NUM_CPUS=${_N_CORES}

  echo "Running pylint on ${NUM_SRC_FILES} files with ${NUM_CPUS} "\
"parallel jobs..."
  echo ""

  PYLINT_START_TIME=$(date +'%s')
  OUTPUT_FILE="$(mktemp)_pylint_output.log"
  ERRORS_FILE="$(mktemp)_pylint_errors.log"
  NONWL_ERRORS_FILE="$(mktemp)_pylint_nonwl_errors.log"

  echo "(Output file is ${OUTPUT_FILE})"

  rm -rf ${OUTPUT_FILE}
  rm -rf ${ERRORS_FILE}
  rm -rf ${NONWL_ERRORS_FILE}
  touch ${NONWL_ERRORS_FILE}

  ${PYLINT_BIN} --rcfile="${PYLINTRC_FILE}" --output-format=parseable \
      --jobs=${NUM_CPUS} ${PYTHON_SRC_FILES} > ${OUTPUT_FILE} 2>&1
  PYLINT_END_TIME=$(date +'%s')

  echo ""
  echo "pylint took $((PYLINT_END_TIME - PYLINT_START_TIME)) s"
  echo ""

  grep -E '(\[E|\[W0311|\[W0312)' ${OUTPUT_FILE} > ${ERRORS_FILE}

  N_ERRORS=0
  while read -r LINE; do
    IS_WHITELISTED=0
    for WL_REGEX in ${ERROR_WHITELIST}; do
      if echo ${LINE} | grep -q "${WL_REGEX}"; then
        echo "Found a whitelisted error:"
        echo "  ${LINE}"
        IS_WHITELISTED=1
      fi
    done

    if [[ ${IS_WHITELISTED} == "0" ]]; then
      echo "${LINE}" >> ${NONWL_ERRORS_FILE}
      echo "" >> ${NONWL_ERRORS_FILE}
      ((N_ERRORS++))
    fi
  done <${ERRORS_FILE}

  echo ""
  if [[ ${N_ERRORS} != 0 ]]; then
    echo "FAIL: Found ${N_ERRORS} non-whitelited pylint errors:"
    cat "${NONWL_ERRORS_FILE}"
    return 1
  else
    echo "PASS: No non-whitelisted pylint errors were found."
    return 0
  fi
}


# Keep the skeleton of the top-level driver program around for its
# pretty-printing of results.
SANITY_STEPS=("do_pylint")
SANITY_STEPS_DESC=("Run pylint on all changed *.py files")



FAIL_COUNTER=0
PASS_COUNTER=0
STEP_EXIT_CODES=()

# Execute all the sanity build steps
COUNTER=0
while [[ ${COUNTER} -lt "${#SANITY_STEPS[@]}" ]]; do
  INDEX=COUNTER
  ((INDEX++))

  echo ""
  echo "=== Sanity check step ${INDEX} of ${#SANITY_STEPS[@]}: "\
"${SANITY_STEPS[COUNTER]} (${SANITY_STEPS_DESC[COUNTER]}) ==="
  echo ""

  ${SANITY_STEPS[COUNTER]}
  RESULT=$?

  if [[ ${RESULT} != "0" ]]; then
    ((FAIL_COUNTER++))
  else
    ((PASS_COUNTER++))
  fi

  STEP_EXIT_CODES+=(${RESULT})

  echo ""
  ((COUNTER++))
done

# Print summary of build results
COUNTER=0
echo "==== Summary of sanity check results ===="
while [[ ${COUNTER} -lt "${#SANITY_STEPS[@]}" ]]; do
  INDEX=COUNTER
  ((INDEX++))

  echo "${INDEX}. ${SANITY_STEPS[COUNTER]}: ${SANITY_STEPS_DESC[COUNTER]}"
  if [[ ${STEP_EXIT_CODES[COUNTER]} == "0" ]]; then
    printf "  ${COLOR_GREEN}PASS${COLOR_NC}\n"
  else
    printf "  ${COLOR_RED}FAIL${COLOR_NC}\n"
  fi

  ((COUNTER++))
done

echo
echo "${FAIL_COUNTER} failed; ${PASS_COUNTER} passed."

echo
if [[ ${FAIL_COUNTER} == "0" ]]; then
  printf "Sanity checks ${COLOR_GREEN}PASSED${COLOR_NC}\n"
else
  printf "Sanity checks ${COLOR_RED}FAILED${COLOR_NC}\n"
  exit 1
fi
