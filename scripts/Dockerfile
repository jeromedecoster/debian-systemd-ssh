# based from https://github.com/priximmo/devopsland/blob/master/ansible/12-docker-platform-dev/Dockerfile
# and https://developers.redhat.com/blog/2014/05/05/running-systemd-within-docker-container
FROM debian:11

# https://forums.balena.io/t/why-do-i-need-env-container-docker/22595/2
# https://forums.balena.io/t/why-do-i-need-env-container-docker/22595/5
ENV container docker

# https://unix.stackexchange.com/a/87763
ARG LANG=en_US.UTF-8
ENV LANG $LANG
ENV LC_ALL $LANG
ENV LANGUAGE $LANG

# https://bobcares.com/blog/debian_frontendnoninteractive-docker/
# inline `DEBIAN_FRONTEND=noninteractive` before `apt install ...` 
# to resolve error `debconf: unable to initialize frontend: Dialog`
# debconf: unable to initialize frontend: Dialog
#
# https://stackoverflow.com/a/61990740
# single RUN command with cache clean
RUN apt update -qq \
    && DEBIAN_FRONTEND=noninteractive apt install -qq --yes --no-install-recommends \
        ca-certificates \
        curl \
        git \
        locales \
        nano \
        openssh-server \
        python3 \
        sudo \
        systemd \
        tree \
        vim \
    && rm --recursive --force /var/lib/apt/lists/*

# resolve `locale: Cannot set LC_ALL | LC_CTYPE | LC_MESSAGES to default locale: No such file or directory`
RUN sed -i "s/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g" /etc/locale.gen \ 
    && sed -i "s/^# $LANG UTF-8$/$LANG UTF-8/g" /etc/locale.gen \ 
    && locale-gen \
    && update-locale LANG=$LANG LC_ALL=$LANG

# change the line `#PermitRootLogin prohibit-password` to `PermitRootLogin yes`
RUN sed --in-place "s|#PermitRootLogin prohibit-password|PermitRootLogin yes|" /etc/ssh/sshd_config

# remove the following services :
# /lib/systemd/system/multi-user.target.wants/getty.target
# /lib/systemd/system/multi-user.target.wants/systemd-ask-password-wall.path
# /lib/systemd/system/multi-user.target.wants/systemd-logind.service
# /lib/systemd/system/multi-user.target.wants/systemd-update-utmp-runlevel.service
# /lib/systemd/system/multi-user.target.wants/systemd-user-sessions.service
# /etc/systemd/system/default.target.wants/e2scrub_reap.service
# /etc/systemd/system/getty.target.wants/getty@tty1.service
# /etc/systemd/system/multi-user.target.wants/remote-fs.target
# /etc/systemd/system/multi-user.target.wants/ssh.service
# /etc/systemd/system/sysinit.target.wants/systemd-pstore.service
# /etc/systemd/system/timers.target.wants/apt-daily-upgrade.timer
# /etc/systemd/system/timers.target.wants/apt-daily.timer
# /etc/systemd/system/timers.target.wants/e2scrub_all.timer
# /etc/systemd/system/timers.target.wants/fstrim.timer
# /lib/systemd/system/sockets.target.wants/systemd-initctl.socket
# /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup-dev.service
# /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup.service
# /lib/systemd/system/systemd-update-utmp-runlevel.service
# /lib/systemd/system/systemd-update-utmp.service
RUN rm --force /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

# on your linux `ls -l /sbin/init` return `lrwxrwxrwx 1 root root /sbin/init -> /lib/systemd/systemd`
RUN ln --symbolic /lib/systemd/system /sbin/init

# `sudo systemctl get-default` return `graphical.target`
RUN systemctl set-default multi-user.target

# `openssl passwd -crypt -salt sa password` return `sa3tHJ3/KuYvI`
RUN sed --in-place "s#root:\*#root:sa3tHJ3/KuYvI#" /etc/shadow

# https://wiki.ubuntu.com/systemd#Boot_loader_configuration
# after installation, the machine will still boot under upstart by default. 
# to boot under systemd, the following argument must be specified on the kernel command line : 
ENV init /lib/systemd/systemd

# VOLUME [ "/sys/fs/cgroup" ]

ARG USER=user
# `openssl passwd -crypt -salt sa password` return `sa3tHJ3/KuYvI`

# `sudo systemctl status ssh` return : loaded, inactive, enabled
# add user to sudoers
# https://askubuntu.com/a/1199
# run scripts on start up to start ssh
RUN useradd --create-home --password sa3tHJ3/KuYvI --shell /bin/bash ${USER} \
    && mkdir /home/${USER}/.ssh \
    && chmod 700 /home/${USER}/.ssh \
    && chown ${USER}:${USER} /home/${USER}/.ssh \
    && echo "$USER   ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && echo '#!/bin/bash' > /etc/rc.local \
    && echo 'systemctl start ssh' >> /etc/rc.local \
    && chmod +x /etc/rc.local \
    && echo "alias ll='ls -lA'" >> /home/${USER}/.bashrc

# https://stackoverflow.com/a/59678710/1503073
# you can only use files in your Dockerfile that are within the build context
# usually, this is the Dockerfile's directory `.`
COPY id_debian_systemd_ssh.pub /home/${USER}/.ssh/authorized_keys

RUN chmod 600 /home/${USER}/.ssh/authorized_keys \
    && chown ${USER}:${USER} /home/${USER}/.ssh/authorized_keys

ENTRYPOINT [ "/lib/systemd/systemd" ]