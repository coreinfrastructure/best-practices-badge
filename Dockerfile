FROM ruby:2.4.1-alpine as builder
MAINTAINER Dan Kohn <dan@dankohn.com>

# Build dependencies will not be included in the final container
RUN apk --no-cache add \
  # for bcrypt and other compilation
  build-base \
  # for nokogiri
  cmake \
  # for gems fetched via git
  git \
  # for ruby-graphviz
  graphviz \
  # for nokogiri
  libxml2-dev \
  # for pg
  postgresql-dev

ENV APP_HOME /app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

# This enables caching gems in a separate container
ENV BUNDLE_PATH /gems_cache

# Copy the Gemfile, Gemfile.lock and .ruby-version and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those three files
# are made.
RUN gem install bundler --no-document 
COPY Gemfile* .ruby-version /tmp/
WORKDIR /tmp
RUN bundle install --jobs 20 --retry 5
# RUN apk del build-dependencies

# FROM ruby:2.4.1-alpine
# MAINTAINER Dan Kohn <dan@dankohn.com>

# These are needed for the runtime (not in build)
RUN apk --no-cache add libpq tzdata

# Needed for eslintrb in development
RUN apk --no-cache add nodejs

ENV APP_HOME /app
RUN mkdir -p $APP_HOME
# ENV BUNDLE_PATH /ruby_gems
# COPY --from=builder /gems_cache $BUNDLE_PATH

# Copy the main application.
ENV SECRET_KEY_BASE 8645c4e1c9ec1c433666e93482888c6ac317de3f11e1cf52f49bbbd99eb87e71126831c5005e3385e9128a9fe2cc98c8f07f7db8e8d687a7e31b00f3a98355c1
ENV FASTLY_API_KEY 62e6b55493b47840bbcc6d345a74fb1a
COPY . $APP_HOME
# Copy Gemfile in case it was generated in the container
RUN cp /tmp/Gemfile.lock $APP_HOME
WORKDIR $APP_HOME
# RUN bundle exec rails assets:precompile
