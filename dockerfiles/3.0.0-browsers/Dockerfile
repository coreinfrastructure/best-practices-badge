# "cimg" are newer CircleCI images, built on Ubuntu, supposed to be
# faster and more deterministic.
# See https://hub.docker.com/r/cimg/ruby

FROM cimg/ruby:3.0.0-browsers

# skip installing gem documentation
# We need "cmake" to build the C code required by some gems.
# We need "shared-mime-info" for gem mimemagic.
RUN sudo apt-get update && sudo apt-get install -y cmake shared-mime-info

USER circleci
