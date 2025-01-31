#!/bin/bash


# ----------------------------------------------------------------
#
#  Install postgreSQL  + vectorDB on Rocky Linux 9
#  
#  31 janv 2025
#
#-----------------------------------------------------------------
#  
#  UTILISATION: ./script.sh PASSWORD 16 0.8.0
#  
#-----------------------------------------------------------------


cd /tmp


# Get inputs 
pass=$1                # password du compte 'postgres' créé par defaut lors de l'install de poostgreSQL
pgVersion=$2           # version de postgreSQL
pgVectorVersion=$3     # version de pgvector
echo "pgVersion = $pgVersion"
echo "pgVectorVersion = $pgVectorVersion"


# dnf module list postgresql   : voir la lisye des versions dispo et celle par defaut


# install and update the repo
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf update -y

# disable the default PostgreSQL repo 
dnf -qy module disable postgresql

# Install and enable
dnf install -y git postgresql$pgVersion-server 
systemctl enable postgresql-$pgVersion




# Initialize the PostgreSQL database server to enable the default 'postgres' user.
postgresql-$pgVersion-setup initdb


# Enable client authentication on DB
# ----------------------------------
#         TYPE        DATABASE           USER                   ADDRESS                 METHOD
echo    "host           all              all                 172.17.0.0/16               trust"  >> /var/lib/pgsql/$pgVersion/data/pg_hba.conf 


# Allow TCP/IP socket
# -------------------
echo "listen_addresses='*'" >> /var/lib/pgsql/$pgVersion/data/postgresql.conf 


# Start service
systemctl start postgresql-$pgVersion


# Set password for user 'postgres
echo "$pass" | passwd "postgres" --stdin


# test:
# su - postgres     # on passe sur le compte créé lors de l'install de postgresql
# psql -l           # liste toutes les tables
# createdb myDB     # creation de la DB myDB
# psql -d myDB      # on se met sur la DB par defaut 'postgres'
# \conninfo         # Outputs information about the current database connection
# \dt               # Table
# \du               # user et roles
# \q                # sortir de la DB


# Install pgvector (extension pour DB vectorielle)
# ----------------
cd /tmp
# wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pgvector_16-0.8.0-1PGDG.rhel9.x86_64.rpm 
wget https://download.postgresql.org/pub/repos/yum/$pgVersion/redhat/rhel-9-x86_64/pgvector_$pgVersion-$pgVectorVersion-1PGDG.rhel9.x86_64.rpm 
rpm -ivh pgvector_$pgVersion-$pgVectorVersion-1PGDG.rhel9.x86_64.rpm
#Connect to DB & Create extension
#psql> CREATE EXTENSION vector;
# \dx               # liste des extensions installées




: '
# Utilisation du vector DB:
# ------------------------

Creation du vector column à 3 dimensions:
    CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));

Insert vectors: 
    INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');

Affiche le contenu de la table:
SELECT * FROM items;

Get the nearest neighbors by L2 distance: 
    SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;

 # more docs : https://medium.com/@besttechreads/step-by-step-guide-to-installing-pgvector-and-loading-data-in-postgresql-f2cffb5dec43

'