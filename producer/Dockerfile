FROM elixir:latest

RUN apt-get update && \
    apt-get install -y build-essential && \
    mix local.hex --force && \
    mix local.rebar --force

# Set the working directory
WORKDIR /app

# Copy the application code
COPY . .

# Install dependencies
RUN mix deps.get

# Compile the application
RUN mix compile

# ENV MIX_ENV=prod

# Start the application
CMD mix run --no-halt