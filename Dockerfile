ARG DEBIAN_VERSION=13

FROM debian:${DEBIAN_VERSION} AS base
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Install locales and basic utilities needed for parallel stages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      curl git locales nix-bin pipx wget zsh && \
    rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG=en_US.utf8

# Create blueteam user and miscellaneous directories
RUN useradd -ms /usr/bin/zsh blueteam && \
    mkdir -p /nix/var/nix /home/linuxbrew && \
    chown -R blueteam:blueteam /nix /home/linuxbrew

# Grab miscellaneous non-apt utilities
FROM base AS misc
WORKDIR /out

# kubectl, kubectx, kubens, kubectl-cnpg, devbox, direnv
RUN curl -fsSLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubectx_v0.9.5_linux_x86_64.tar.gz" | \
        tar -xz kubectx && \
    curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubens_v0.9.5_linux_x86_64.tar.gz" | \
        tar -xz kubens && \
    curl -fsSL "https://github.com/cloudnative-pg/cloudnative-pg/raw/main/hack/install-cnpg-plugin.sh" | \
        sh -s -- -b . && \
    curl -fsSL "https://github.com/jetify-com/devbox/releases/download/0.16.0/devbox_0.16.0_linux_amd64.tar.gz" | \
        tar -xz devbox && \
    curl -fsSL "https://direnv.net/install.sh" | \
        bin_path=. bash

# Install Linuxbrew and build homedir
FROM base AS home
USER blueteam
WORKDIR /home/blueteam

# Install nix channels and update
RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && nix-channel --update

# Install Linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install pipx packages and configure shells
RUN touch ~/.zshrc && mkdir -p .local/bin && \
    pipx install --include-deps ansible && \
    pipx inject --include-apps ansible argcomplete && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> .profile && \
		echo 'eval "$(direnv hook bash)"' >> .bashrc && \
		echo 'eval "$(direnv hook zsh)"' >> .zshrc

# Final result
FROM base AS final

RUN source /etc/os-release && cd /run && \
    curl -O https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash-completion busybox dnsutils dos2unix elinks emacs file ftp iperf3 \
      iputils-ping ipython3 irssi less man-db manpages mc mosh msmtp msmtp-mta \
      mtr mutt nano ncal ncat ncftp nmap openssh-client openssl p7zip-full \
      patch powershell psmisc python3-cryptography python3-full python3-pip rclone \
      rsync screen sqlite3 tcpdump testdisk tftp-hpa traceroute tshark unar unzip \
      vim xxd yafc zip && \
    rm -rf /var/lib/apt/lists/*

# Add busybox symlinks for any otherwise missing tools
RUN busybox --install

COPY --from=containerssh/agent /usr/bin/containerssh-agent /usr/bin/containerssh-agent
COPY --from=misc /out /usr/local/bin
COPY --from=home /home /home
COPY --from=home /nix /nix

USER blueteam
WORKDIR /home/blueteam
