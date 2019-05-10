# tf-dev-conf

This project contains the configuration files that I use to set up my development 
environment for modifying the TensorFlow code.

### Installation Instructions:

1. Check out this repository into your home directory.
2. Install Anaconda
3. Run the script `buildenv.sh` to set up an Anaconda environment `tfbuild` for building TensorFlow.
2. Add the following to your `.bashrc`:

   ```
   export MY_TF_REPO_URL=<Github URL of your fork of TensorFlow; 
                           for example, https://github.com/frreiss/tensorflow-fred.git>
    
   if [ -f ~/tf-dev-conf/aliases.sh ]; then
       source ~/tf-dev-conf/aliases.sh
   fi
   ```

### Contents of this directory:

* **aliases.sh**: Bash aliases for common TensorFlow develoment tasks
* **branch.py**: Script to create a local development branch for a TensorFlow pull request
* **buildenv.sh**: Script to configure an Anaconda environment on the local machine for building TensorFlow.
* **testenv.sh**: Script to create an Anaconda environment under the current directory for testing your modified version of TensorFlow.

### My Development Workflow

**Phase 1:** Implement code changes on laptop:

1. `tfb my-pr-name`:
   Replace `my-pr-name` with a name for your branch and local working directory. 
   The local working directory will be `tf-my-pr-name` and the branch you push to will
   be `issue-my-pr-name`. Choose a name that will be memorable; larger pull requests can
   stay in the review queue for weeks or months.
2. `cd tf-my-branch-name`
3. `tfcc` (configures for compilation)
4. `bbt`: Kick off a build/test cycle in the background while you make your code changes.
    This step will save you time later on.
5. Make changes
7. `git push` (create and push to your branch)

**Phase 2a:** Manual testing on laptop:

1. `cd tf-my-branch-name`
2. `bbp`/`bbp2` (prepare to build a Pip package)
3. `bbpp` (actually build the pip package)
4. `~/tf-dev-conf/testenv.sh`
5. `conda activate ./testenv`
6. `pip install ./pip_package/*.whl`
7. `jupyter lab` (to try out your changes)

**Phase 2b:** Build/test on the cloud. These steps can run at the same time as 2a.

1. Create a large virtual machine or container. I use a 56-core VM with 128GB of memory and local flash storage.
2. Import this repository's scripts and configuration to your VM/container
3. `tfc my-pr-name`: Check out a copy of your branch to the cloud machine.
4. `bbd`: Run pre-commit sanity checks like `pylint`. Fix any problems that arise while the next step runs.
5. `bbtd`: Full regression test suite from a Docker environment.

**Phase 3:** Prepare PR:

1. Return to laptop and `cd tf-my-branch-name`.
2. `git rebase --interactive HEAD~<number of commits made>`: Squash all your commits to date.
3. `git push --force`. Note that you will need to check out a fresh copy of your branch on your large cloud VM/container after this step by running `tfc my-branch-name` a second time.
4. Go to github.com and create a pull request off the branch `issue-my-branch-name`.

Phase 4: Maintain branch during review. On your laptop:

1. `conda activate tfbuild`
2. `cd tf-my-branch-name`
3. Make any changes requested
4. `bbt` to rerun regression tests affected by your changes
5. If you made significant changes, fire up a VM and repeat Phase 2b.
6. `git push`. Do **not** rebase a second time; doing so will corrupt your pull request.