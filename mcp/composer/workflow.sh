#!/bin/bash
# PHP Composer Setup
# Assumes composer is in PATH or downloads it
if ! command -v composer &> /dev/null
then
    echo "Composer could not be found. Downloading..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
else
    echo "Composer detected."
fi
composer install
