FROM debian:latest
SHELL ["/bin/bash", "-c"]
RUN source /etc/os-release && apt-get update && apt-get install -y curl wget && 
&& wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.3.8/powershell_7.3.8-1.deb_amd64.deb \
&& dpkg -i powershell_7.3.8-1.deb_amd64.deb \
&& apt-get install -y locales curl wget nmap nano vim msmtp msmtp-mta python3-full \
python3-pip zsh emacs python3-full python3-pip git elinks2 emacs rclone rsync mc zip unzip unar p7zip-full iperf3 mtr \
&& wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.3.8/powershell_7.3.8-1.deb_amd64.deb \
&& dpkg -i powershell_7.3.8-1.deb_amd64.deb \
&& pip3 install pipx --break-system-packages
RUN rm -rf /var/lib/apt/lists/*  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
RUN useradd -ms /usr/bin/zsh blueteam
USER blueteam
WORKDIR /home/blueteam
# FROM HERE WE START WHAT THE USER SPACE LOOKS LIKE
ENV LANG en_US.utf8
RUN touch ~/.zshrc \
&& pipx install --include-deps ansible \
&& pipx inject --include-apps ansible argcomplete \
&& pipx ensurepath \ 
&& sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
&& /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
&& echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.zshrc
