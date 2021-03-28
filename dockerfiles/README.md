# CII Best Practices CircleCI Dockerfiles

This directory contains directories and Dockerfiles for the custom
images used in the app's CI pipeline on CircleCI.  When upgrading ruby,
it is best to copy the folder and name it according to the CircleCI base
image you are using.

To upgrade the docker image you must have an account on DockerHub and docker
installed on your computer (Install instructions are
[here](https://docs.docker.com/install/). You can then run the following steps.

1. Copy the existing file and directory as described above.
2. Modify the Dockerfile to point to the correct base image.
3. Log in to DockerHub
    ~~~~sh
    docker login -u <username>
    ~~~~
4. Build the docker image (replace `<tag>` below with for example
   `2.5.1-stretch`.
    ~~~~sh
    docker build -t <username>/cii-bestpractices:<tag> .
    ~~~~
5. Push your image.
    ~~~~sh
    docker push <username>/cii-bestpractices:<tag>
    ~~~~

Once completed you can then update `.circleci/config.yml` to use the new image.
You should also add your new Dockerfile to version control.
