# Wordpress base environment

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

