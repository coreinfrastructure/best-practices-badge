# "cimg" are newer CircleCI images, built on Ubuntu, supposed to be
# faster and more deterministic. For more on these images see:
# See https://hub.docker.com/r/cimg/ruby
# https://circleci.com/developer/images/image/cimg/ruby

# OpenSSF Scorecard wants us to pin our image to a deterministic
# docker image. A discussion about docker pinning is here:
# https://medium.com/@tariq.m.islam/container-deployments-a-lesson-in-deterministic-ops-a4a467b14a03
# You can get the hash value for a specific image by using "docker images"
# and querying about REPOSITORY:TAG, for example:
# docker pull cimg/ruby:3.0.5-browsers
# will return:
#3.0.5-browsers: Pulling from cimg/ruby
#Digest: sha256:bb2edbe41336dd713fd6aae84b3af0b6633d16f752dbe235b8abbaea436482dc
# For more about Docker pinning, see:
# https://docs.docker.com/engine/reference/commandline/pull/#pull-an-image-by-digest-immutable-identifier
# So instead of something like "FROM cimg/ruby:3.0.5-browsers", we do this:

# pin :3.0.5-browsers
FROM cimg/ruby@sha256:bb2edbe41336dd713fd6aae84b3af0b6633d16f752dbe235b8abbaea436482dc
# skip installing gem documentation
# We need "cmake" to build the C code required by some gems.
# We need "shared-mime-info" for gem mimemagic.
RUN sudo apt-get update && sudo apt-get install -y cmake shared-mime-info

USER circleci
