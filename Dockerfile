FROM ruby:2.4.1-alpine
# CMD ["./install-badge-dev-env"]

RUN  apk add --update \
  # for bcrypt and other compilation
  build-base \
  # for nokogiri
  cmake \
  # for mail
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

# Copy the Gemfile as well as the Gemfile.lock and install 
# the RubyGems. This is a separate step so the dependencies 
# will be cached unless changes to one of those two files 
# are made.
RUN gem install bundler --no-document 
COPY Gemfile Gemfile.lock .ruby-version /tmp/
WORKDIR /tmp
RUN bundle install --jobs 20 --retry 5

# Copy the main application.
COPY . ./

# The main command to run when the container starts. Also 
# tell the Rails dev server to bind to all interfaces by 
# default.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]