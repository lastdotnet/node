FROM ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# create custom user, install dependencies, create data directory
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y \
    && apt-get install -y curl gosu net-tools \
    && mkdir -p /home/$USERNAME/hl/data \
    && mkdir -p /home/$USERNAME/hl/tmp/shell_rs_out \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl \
    && chown -R $USERNAME:$USERNAME /usr/local/bin

WORKDIR /home/$USERNAME

# configure chain to testnet
RUN echo '{"chain": "Testnet"}' > /home/$USERNAME/visor.json \
    && chown $USERNAME:$USERNAME /home/$USERNAME/visor.json \
    && ln -s /home/$USERNAME/visor.json /usr/local/bin/visor.json

# save the public list of peers to connect to
ADD --chown=$USER_UID:$USER_GID https://binaries.hyperliquid.xyz/Testnet/initial_peers.json /home/$USERNAME/initial_peers.json

# temporary configuration file (will not be required in future update)
ADD --chown=$USER_UID:$USER_GID https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json /home/$USERNAME/non_validator_config.json

# add the binary
ADD --chown=$USER_UID:$USER_GID --chmod=700 https://binaries.hyperliquid.xyz/Testnet/hl-visor /usr/local/bin/hl-visor

# gossip ports
EXPOSE 4001
EXPOSE 4002

# use gosu to run directly as hluser
ENTRYPOINT chown -R hluser:hluser /home/hluser/hl && exec gosu hluser hl-visor run-non-validator --serve-eth-rpc