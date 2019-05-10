# tf-dev-conf

This project contains the configuration files that I use to set up my development 
environment for modifying the TensorFlow code.

Directions for use:

1. Check out this repository into your home directory.
2. Install Anaconda
3. Run the script `buildenv.sh` to set up an Anaconda environment `tfbuild` for building TensorFlow.
2. Add the following to your `.bashrc`:

   ```
   export MY_TF_REPO_URL=<Github URL of your fork of TensorFlow; 
                           for example, https://github.com/frreiss/tensorflow-fred.git>
    
   if [ -f ~/tf-dev-conf/tf-aliases.sh ]; then
       source ~/tf-dev-conf/tf-aliases.sh
   fi
   ```

Contents of this directory:

* **buildenv.sh**: Script to configure an Anaconda environment on the local machine for building TensorFlow.
* **testenv.sh**: Script to create an Anaconda environment under the current directory for testing your modified version of TensorFlow.
* **tf-aliases.sh**: Bash aliases for common TensorFlow develoment tasks
* **tf-branch.py**: Script to create a local development branch for a TensorFlow pull request
