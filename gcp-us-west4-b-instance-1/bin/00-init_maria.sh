#!/bin/bash

PTERODACTYL_USER=pterodactyl
PTERODACTYL_PASS=$(python3 -c 'import random; print("".join(random.choices("abcdefghijklmnopqrstuvwxyz1234567890", k=16)));')
mysql -u root << EOSQL
CREATE USER '$PTERODACTYL_USER'@'127.0.0.1' IDENTIFIED BY '$PTERODACTYL_PASS';
CREATE DATABASE panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
EOSQL
