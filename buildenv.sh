#! /bin/bash

################################################################################
# buildenv.sh
#
# Set up a system-wide Anaconda virtualenv for building TensorFlow. 
#
# Requires that conda be installed and set up for calling from bash scripts.
#
# Also requires that you set the environment variable CONDA_HOME to the
# location of the root of your anaconda/miniconda distribution.
################################################################################

PYTHON_VERSION=3.6

ENV_NAME="tfbuild"

############################
# HACK ALERT *** HACK ALERT 
# The friendly folks at Anaconda thought it would be a good idea to make the
# "conda" command a shell function. 
# See https://github.com/conda/conda/issues/7126
# The following workaround will probably be fragile.
if [ -z "$CONDA_HOME" ]
then 
    echo "Error: CONDA_HOME not set"
    exit
fi
. ${CONDA_HOME}/etc/profile.d/conda.sh
# END HACK
############################


# Remove the detrius of any previous runs of this script
conda env remove -n ${ENV_NAME}


# Create initial env with official prereqs for running tests
conda create -y --name ${ENV_NAME} \
    python=${PYTHON_VERSION} \
    numpy wheel \
    -c conda-forge

conda activate ${ENV_NAME}

# Install unofficial requirements, i.e. not mentioned in the docs, but tests
# will fail without them.
# TODO: Revisit these periodically
conda install -y portpicker grpcio scipy \
    keras-applications keras-preprocessing 
    #-c conda-forge

# Some prereqs are only available from conda-forge
conda install -y autograd \
    -c conda-forge

# Additional requirements for running the tests under contrib
conda install -y scikit-learn

# Requirements that must be installed from pip because the conda version is
# not kept sufficiently up to date. TODO: Revisit this list and move things to
# conda install.
pip install tensorflow-estimator


# Install TensorFlow and keras-applications, both of which are also unofficial
# requirements. We install them from pip because the version in conda-forge is
# sometimes too old to work with the master build of TF.
#pip install tensorflow tensorflow-estimator keras-applications

conda deactivate
    
        
echo << EOM
Anaconda virtualenv installed under name '${ENV_NAME}'
Run \"conda activate ${ENV_NAME}\" before running ./configure
EOM

