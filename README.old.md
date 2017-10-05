# Wordpress Environment

## Run command

This environment is provided with a helper command called `run`.
To make it usage easy, add the following line to your `~/.bashrc` file:

```
alias run='./run.sh'
```

This will make the command available when you are inside the environment folder.

## Run up

To bring your environment up, use `run up`. To destroy it (keeping volumes) use `run down`.
The port 8888 will be exposed to host machine.

## Configure your hosts

Add the following lines to your hosts file

```
127.0.0.1 docker.wordpress
127.0.0.1 docker.wordpress.phpmyadmin
```

## Installing theme

The `run` script provides a easy way to install a theme package from git.

```
$ run theme:install replace-by-git-url 
``` 

## Running on Windows

There are a few pre-requisites to run this over Windows:

- The Bash for Windows (aka WSL) should be installed
- The docker should be installed on host machine (Windows) and TCP/IP should be enabled on docker (Settings -> General -> Expose daemon on tcp://localhost:2375 without TLS)
- The docker-ce client should be installed on WSL
- The `/mnt/c` should be mounted on `/c` using `sudo mount --bind /mnt/c /c` (need to find a way to add on fstab to be permanent), or create a symlink using `sudo ln -s /mnt/c /c` (permanent)
- This repository should be on the following path `C:\wordpress-environment` in order to volumes work fine.
