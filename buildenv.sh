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

PYTHON_VERSION=3.7

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
if [ -e "${CONDA_HOME}/etc/profile.d/conda.sh" ]
then
    . ${CONDA_HOME}/etc/profile.d/conda.sh
else
    echo "${CONDA_HOME} does not appear to be set up properly"
    exit
fi
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


# Install unofficial test requirements, i.e. not mentioned in the docs, but 
# tests will fail without them.
# TODO: Revisit these periodically
conda install -y portpicker grpcio scipy h5py six

    #keras-applications keras-preprocessing 
    #-c conda-forge

# Other stuff needed for building from an IDE
conda install -y pylint flake8 rope

# Some prereqs are only available from conda-forge
conda install -y autograd \
    -c conda-forge

# Additional requirements for running the tests under contrib
conda install -y scikit-learn

# Requirements that are installed from pip so we can avoid pulling in
# dependencies. Use the specific versions that the TF Docker images use
pip install keras_applications==1.0.8 --no-deps
pip install keras_preprocessing==1.1.0 --no-deps
pip install tf-estimator-nightly --no-deps 


conda deactivate
    
        
echo << EOM
Anaconda virtualenv installed under name '${ENV_NAME}'
Run \"conda activate ${ENV_NAME}\" before running ./configure
EOM

