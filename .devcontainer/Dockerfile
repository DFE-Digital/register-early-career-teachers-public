FROM ruby:4.0.4-slim

RUN echo 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";' > /etc/apt/apt.conf.d/99no-recommends

RUN apt update -qq && apt install -y \
    build-essential \
    libpq-dev \
    libyaml-dev \
    git \
    curl \
    postgresql-client \
    nodejs \
    npm

WORKDIR /workspaces/register-early-career-teachers-public

RUN gem update --system
