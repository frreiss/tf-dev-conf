#! /bin/bash

################################################################################
# tf_env.sh
#
# Set up an Anaconda virtualenv for testing your builds of TensorFlow. Creates an
# environment in a subdirectory "testenv" of your current working directory.
#
# Usually you will run this script from the root of your local copy of the
# TensorFlow source.
#
# Requires that conda be installed and set up for calling from bash scripts.
#
# Also requires that you set the environment variable CONDA_HOME to the
# location of the root of your anaconda/miniconda distribution.
################################################################################

PYTHON_VERSION=3.6

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

conda create -y --prefix ./testenv \
    python=${PYTHON_VERSION} \
    numpy pandas jupyterlab 
    #-c conda-forge
conda activate ./testenv

# Additional requirements needed to build API docs for TF 2.x
pip install git+https://github.com/tensorflow/docs tensorboard

conda deactivate

        
