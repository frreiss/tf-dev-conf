#! /bin/bash

################################################################################
# lintenv.sh
#
# Set up a system-wide Anaconda virtualenv for running TensorFlow's
# tensorflow/tools/ci_build/ci_sanity.sh script outside of a Docker container. 
# Replicates the Python environment in the TensorFlow Dockerfiles under
# tensorflow/tools/ci_build.
#
# Requires that conda be installed and set up for calling from bash scripts.
#
# Also requires that you set the environment variable CONDA_HOME to the
# location of the root of your anaconda/miniconda distribution.
################################################################################

# Dockerfiles are all on Python 3.6, not 3.7
PYTHON_VERSION=3.6

ENV_NAME="tflint"

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


# Create initial env, leaving it as empty as possible to prevent version
# conflicts with the specific libraries that the TF test env needs.
conda create -y --name ${ENV_NAME} \
    python=${PYTHON_VERSION} 

conda activate ${ENV_NAME}

# For now we pip install everything so as to tightly control version numbers
# See tensorflow/tools/ci_build/install/install_pip_packages.sh for more
# information.
# The original code set up both Python 2 and 3, but given the looming EOL date
# for Python 2, we only do Python 3 here.

# Start out by downgrading pip to the same version used in the TF script.
easy_install -U pip==18.1

pip install --upgrade \
    wheel==0.31.1 \
    setuptools==39.1.0 \
    virtualenv \
    six==1.12.0 \
    future>=0.17.1 \
    absl-py \
    werkzeug==0.11.10 \
    bleach==2.0.0 \
    markdown==2.6.8 \
    protobuf==3.6.1 \
    numpy==1.14.5 \
    scipy==1.1.0 \
    scikit-learn==0.18.1 \
    pandas==0.19.2 \
    psutil \
    py-cpuinfo \
    pylint==1.6.4 \
    pycodestyle \
    portpicker \
    grpcio \
    astor \
    gast \
    termcolor \
    h5py==2.8.0 \
    argparse 

# These dependencies are installed separately because they will change
# frequently and need to be installed without dependent packages
# frequently and require --no-deps argument.
pip install keras_applications==1.0.6 --no-deps
pip install keras_preprocessing==1.0.5 --no-deps
pip install tf-estimator-nightly --no-deps

conda deactivate
    
        
echo << EOM
Anaconda virtualenv installed under name '${ENV_NAME}'
Run \"conda activate ${ENV_NAME}\" before running ./configure
EOM

