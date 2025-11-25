#!/bin/bash


docker stop $(docker ps -qa)

docker rm $(docker ps -qa)

docker volume rm data_lldap_data

docker rmi lldap/lldap:stable


# cd /data
# docker compose up --detach






