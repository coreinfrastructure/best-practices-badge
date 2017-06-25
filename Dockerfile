FROM ruby:2.4.1-alpine
MAINTAINER Dan Kohn <dan@dankohn.com>
RUN  apk --update --virtual build-dependencies add \
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
  # for JS support
  nodejs \
  # for pg
  postgresql-dev \
  # tzinfo data is required
  tzdata

ENV APP_HOME /app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

# Expose port 3000 to the Docker host, so we can access it 
# from the outside.
EXPOSE 3000

# This will enable caching gems
ENV BUNDLE_PATH /ruby_gems

# Copy the Gemfile, Gemfile.lock and .ruby-version and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those three files
# are made.
RUN gem install bundler --no-document 
COPY Gemfile Gemfile.lock .ruby-version /tmp/
WORKDIR /tmp
RUN bundle install --jobs 20 --retry 5
RUN apk del build-dependencies

# Copy the main application.
COPY . $APP_HOME

RUN rails db:version || bundle exec rake db:setup
