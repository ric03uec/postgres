#!/bin/bash -e

export IS_INITIALIZED=false
export PG_USER=postgres
export SHIPPABLE_POSTGRES_PORT=5432
export PG_MAJOR="$PG_MAJOR"
export POSTGRES_BINARY="/usr/lib/postgresql/$PG_MAJOR/bin/postgres"
export POSTGRES_CMD="su -u postgres $SHIPPABLE_POSTGRES_BINARY \
	-c config_file=/etc/postgresql/$PG_MAJOR/main/postgresql.conf"
export LOGFILE=/var/log/postgresql/pg.log

# import ubuntu image
# install postgres 9.5 from repo
# create directory and config files
# set entrypoint script. DO NOT change the interface so that same docker run command works
#		- check if db present or not
#		- create db if not use pg_ctl
#		- check if user prsent or not
#		- create user if not, use pg_ctl
#		- create mounts if not exists
#   - throw error if no config file
_print_runtime() {
	echo "PG runtime envs"
	echo "PG_MAJOR: $PG_MAJOR"
	echo "PATH: $PATH"
	echo "PGDATA: $PGDATA"
	echo "POSTGRES_BINARY: $POSTGRES_BINARY"
	echo "POSTGRES_CMD: $POSTGRES_CMD"

	if [ -z "$DBUSER" ] || [ "$DBUSER" == "" ]; then
		echo "DBUSER env variable doesnt exist, exiting"
		exit 1
	else
		echo "DBUSER: $DBUSER"
	fi

	if [ -z "$DBPASSWORD" ] || [ "$DBPASSWORD" == "" ]; then
		echo "DBPASSWORD env variable doesnt exist, exiting"
		exit 1
	else
		echo "DBPASSWORD: $DBPASSWORD"
	fi

	if [ -z "$DBNAME" ] || [ "$DBNAME" == "" ]; then
		echo "DBNAME env variable doesnt exist, exiting"
		exit 1
	else
		echo "DBNAME: $DBNAME"
	fi
}

_check_db_state() {
	echo "checking database initialize status"
	local pg_version="$PGDATA/PG_VERSION"
	if [ ! -f "$pg_version" ]; then
		echo "DB not initialized"
		export IS_INITIALIZED=false
	else
		echo "DB already initialized"
		export IS_INITIALIZED=true
	fi
}

_create_data_dir() {
	echo "Creating data directory"
	mkdir -p $PGDATA
	chown -cR $PG_USER:$PG_USER $PGDATA
}

_initialize_db() {
	echo "Checking database initialize status"
	if [ $IS_INITIALIZED == false ];then
		echo "Creating db files"
		su - $PG_USER -c "/usr/lib/postgresql/$PG_MAJOR/bin/initdb -D $PGDATA"
	else
		echo "DB already initialized, skipping db files creation"
	fi
}

_create_config() {
	echo "Creating postgresql.conf file"
	local config_dir="/etc/postgresql/$PG_MAJOR"
	mkdir -p "$config_dir"

	local config="$config_dir/postgresql.conf"
	if [ ! -f "$config" ]; then

		echo "Config file not present, creating from sample"
		cp -vr /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample $config

		echo "Updating listen_addresses value to * "
		sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" $config

	else
		echo "Config file already present, skipping"
	fi
}

_update_perms() {
	echo "Updating login permissions"
	{
		echo
		echo "host all all all md5"
	} >> "$PGDATA/pg_hba.conf"
}

_boot() {
	echo "Booting database server"
	su - postgres -c "/usr/lib/postgresql/$PG_MAJOR/bin/pg_ctl \
		-D $PGDATA \
		-l $LOGFILE \
		-w start"
}

_create_user() {
	echo "Checking user $DBUSER"
	# error if password not provided
	local user_exists=$(psql -U postgres -tAc \
		"SELECT 1 FROM pg_roles WHERE rolname='$DBUSER'" \
		| grep 1 \
		| awk '{print $1}')
	if [ "$user_exists" == "" ]; then
		echo "Creating $DBUSER"
		psql -U postgres -c \
			"CREATE USER $DBUSER PASSWORD '$DBPASSWORD' LOGIN INHERIT";
	else
		echo "$DBUSER already exists"
	fi
}

_create_db() {
	echo "creating database $DBNAME"
	local db_exists=$(psql -U postgres -l | grep $DBNAME | wc -l)
	if [[ $db_exists -gt 0 ]]; then
		echo "Database $DBNAME exists, skipping"
	else
		echo "Database $DBNAME does not exist"
		psql -U postgres -c \
			"CREATE DATABASE $DBNAME OWNER $DBUSER";
	fi
}

_tail() {
	echo "Tailing db logs"
	tail -100f $LOGFILE
}

main() {
	echo "Starting postgres server"
	_print_runtime
	_check_db_state
	_create_data_dir
	_initialize_db
	_create_config
	_update_perms
	_boot
	_create_user
	_create_db
	_tail
}

main
