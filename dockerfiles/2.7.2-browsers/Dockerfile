# "cimg" are newer CircleCI images, built on Ubuntu, supposed to be
# faster and more deterministic.
# See https://hub.docker.com/r/cimg/ruby

FROM cimg/ruby:2.7.2-browsers

# skip installing gem documentation
RUN sudo apt-get update && sudo apt-get install -y cmake

USER circleci
