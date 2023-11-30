# Start with a suitable base, Debian for the Linux environment
FROM debian:bullseye-slim

# Set non-interactive for apt-get installs
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary tools
RUN apt-get update && apt-get install -y \
    bash \
    openssh-client \
    coreutils \
    iproute2 \
    openconnect \
    sed \
    tmux \
    sshpass \
    python3 \
    python3-pip \
    gcc \
    lsof \
    && rm -rf /var/lib/apt/lists/*


# Install python packages
RUN pip3 install --no-cache-dir --upgrade determined==0.26.1

RUN pip3 install --no-cache-dir --upgrade mitmproxy


# Add CA certificate (assuming it's in the same directory as the Dockerfile)
COPY rootcert.crt /rootcert.crt

# Copy .bashrc and set up the environment (assuming .bashrc is in the same directory as the Dockerfile)
COPY bashrc /root/.bashrc
RUN echo "source /root/.bashrc" > /root/.profile

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Entrypoint and environment variables
ENV SHELL /bin/bash
ENV BASH_ENV /root/.bashrc
# ENV HOME /root  # this is the default

RUN mkdir /wd
WORKDIR /wd

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "bash" ] 
