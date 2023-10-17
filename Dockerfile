FROM debian:latest
ENV POWERSHELL_VERSION=v7.3.8
RUN apt-get update && apt-get install -y locales curl wget nmap nano vim msmtp msmtp-sendmail python3 python3-pip zsh \
&& source /etc/os-release \
&& wget -q https://packages.microsoft.com/config/debian/$POWERSHELL_VERSION/packages-microsoft-prod.deb \
&& dpkg -i packages-microsoft-prod.deb \
&& rm packages-microsoft-prod.deb \
&& apt-get update && apt-get install -y powershell
RUN rm -rf /var/lib/apt/lists/*  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
RUN useradd -ms /bin/bash blueteam
USER blueteam
WORKDIR /home/blueteam
# FROM HERE WE START WHAT THE USER SPACE LOOKS LIKE
ENV LANG en_US.utf8

