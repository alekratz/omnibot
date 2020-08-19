FROM elixir:1.10

# XXX #
# Rust is required because of the "meeseeks" dependency because it uses a Rust
# library for some reason. I'll start looking for alternatives so we don't have
# to worry about installing it in the future because that is not a small
# dependency.

# It's impossible to pass a command line parameter (-y) to a shell script being
# read through stdin, so this line downloads, runs, and removes that script.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustup.sh && \
    chmod +x /tmp/rustup.sh && \
    /tmp/rustup.sh -y && \
    rm /tmp/rustup.sh

# Also set the PATH to include /root/.cargo/bin, where Rust was installed to
ENV PATH="/root/.cargo/bin:$PATH"

# END XXX #

RUN mkdir /app
WORKDIR /app

RUN mix local.hex --force
RUN mix local.rebar --force

CMD mix deps.get && mix run --no-halt
