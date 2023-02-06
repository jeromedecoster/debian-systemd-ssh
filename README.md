# debian-systemd-ssh

debian and systemd in a docker image that can be connected to via ssh

## Usage

```bash
Usage dss <command> [option]
```

## Commands

```bash
<nbr>          Create nbr containers
d, destroy     Destroy all containers
e, edit        Edit Dockerfile
i, info        Show running containers information
s, ssh [idx]   SSH to debian-[idx]. Missing containers will be created
```
  
### Examples
    
```bash
# connect to debian-1 via ssh (create it first if missing)
dss s

# create 3 containers then connect to debian-2 via ssh
dss 3 && dss s 2
```

---

### install with curl

```bash
curl github.com/jeromedecoster/debian-systemd-ssh/raw/master/install.sh \
    --location \
    --silent \
    | bash
```

### install with wget

```bash
wget github.com/jeromedecoster/debian-systemd-ssh/raw/master/install.sh \
    --output-document=- \
    --quiet \
    | bash
```

### uninstall

```bash
sudo rm --force --recursive /usr/local/lib/debian-systemd-ssh \
    && sudo rm --force --recursive /usr/local/bin/dss
```

### inspiration

- [Deploy container as virtual machine](https://github.com/priximmo/devopsland/tree/master/ansible/12-docker-platform-dev)
- [Running systemd within a Docker Container](https://developers.redhat.com/blog/2014/05/05/running-systemd-within-docker-container)