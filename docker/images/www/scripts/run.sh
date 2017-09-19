#!/bin/bash

chmod -R 0777 /var/www
exec supervisord -n