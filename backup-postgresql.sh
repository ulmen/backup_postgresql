#! /bin/bash

# backup-postgresql.sh
# by Craig Sanders
# this script is public domain.  feel free to use or modify as you like.

DUMPALL="/usr/bin/pg_dumpall"
PGDUMP="/usr/bin/pg_dump"
PSQL="/usr/bin/psql"

# directory to save backups in, must be rwx by postgres user
BASE_DIR="/var/backups/postgres"
YMD=$(date "+%Y-%m-%d")
DIR="$BASE_DIR/$YMD"
mkdir -p $DIR
cd $DIR

# get list of databases in system , exclude the tempate dbs
DBS=$($PSQL -l -t | egrep -v 'template[01]' | awk '{print $1}')

# first dump entire postgres database, including pg_shadow etc.
$DUMPALL -D | gzip -9 > "$DIR/db.out.gz"

# next dump globals (roles and tablespaces) only
$DUMPALL -g | gzip -9 > "$DIR/globals.gz"

# now loop through each individual database and backup the schema and data separately
for database in $DBS; do
    SCHEMA=$DIR/$database.schema.gz
    DATA=$DIR/$database.data.gz

    # export data from postgres databases to plain text
    $PGDUMP -C -c -s $database | gzip -9 > $SCHEMA

    # dump data
    $PGDUMP -a $database | gzip -9 > $DATA
done

# delete backup files older than 30 days
OLD=$(find $BASE_DIR -type d -mtime +30)
if [ -n "$OLD" ] ; then
        echo deleting old backup files: $OLD
        echo $OLD | xargs rm -rfv
fi