# Wordpress Environment

This docker-compose project creates an easy to use development environment for WordPress.

It's composed by three containers:

- `mysql:5.7`
- `iget/default-www:latest` containing:
  - `PHP 7.1`
  - Latest `nginx`
  - Latest `NodeJS`
- `phpmyadmin/phpmyadmin:latest`

It also contains a script named `run.sh`, that contains some commands to control
the environment and other helpful commands.

## How to use?

This project shares the `www` directory with our `default-www` container, that will be served on `http://localhost:8888`.

Although this was designed for WordPress usage, you can use any web application compatible with our PHP and MySQL
versions. Some php extensions may not be installed, requiring that you extend our `default-www` image.

On first usage, all you need to do is:

```
./run.sh up
```

This will bring up all containers, and you will be able to access it under `http://localhost:8888/`, that will serve
your `www` directory content.

### The `run` script

The `run.sh` script contains some helpful commands, you can see by typing `./run.sh help`.

On following examples we used an alias `run`, that you can setup by adding the following line to your `~/.bashrc` file:

```
alias run='./run.sh'
```

#### `run bind [-d=domain]`

The `bind` command will add a entry on `/etc/hosts` for Linux and Mac host machines pointing to localhost.

Usage:

```
run bind my-wordpress-env
# Will print `127.0.0.1 my-wordpress-env` on your hosts file
# and flush and restart dns if you are on a Mac host
```

#### `run install`

The `install` command will clone the latest WordPress version and put the `wp-config-sample.php`.

#### `run install:theme[repository url]`

The `install:theme` command will clone your Wordpress theme from `[repository url]` named as `theme`, and install `npm` dependencies.

#### `run theme:npm [command]`

The `theme:npm` command is an alias to `npm [command]` inside the www container.

This allow you run npm commands without need to install node stuff on host machine.

#### `run theme:run [command]`

The `theme:run` command is an alias to `theme:npm run [command]`.

## Running on Windows

There are a few pre-requisites to run this over Windows:

- The Bash for Windows (aka WSL) should be installed
- The docker should be installed on host machine (Windows) and TCP/IP should be enabled on docker (Settings -> General -> Expose daemon on tcp://localhost:2375 without TLS)
- The docker-ce client should be installed on WSL
- The `/mnt/c` should be mounted on `/c` using `sudo mount --bind /mnt/c /c` (need to find a way to add on fstab to be permanent), or create a symlink using `sudo ln -s /mnt/c /c` (permanent)
- This repository should be on the following path `C:\wordpress-environment` in order to volumes work fine.
