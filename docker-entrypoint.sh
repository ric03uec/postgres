#!/bin/bash -e

export IS_INITIALIZED=false
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

}

_check_db_state() {
	## if PG_VERSION is available in data directory, then db is already initialized,
	## skip any other steps
	echo "checking database initialize status"

}

_create_data_dir() {
	echo "Creating data directory"
	# skip if db is initialized
}

_create_db() {
	echo "Creating database"
	# skip if db present
}

_create_user() {
	echo "Creating user $DBUSER"
	# error if password not provided

}

_create_config() {
	echo "Creating postgresql.conf file"
	# if not present, copy from sample and update values
	# if present, skip
}

_boot() {
	echo "Booting database server"

}


main() {
	echo "Starting postgres server"
	_print_runtime
	_check_db_state
	_create_data_dir
	_create_db
	_create_user
	_create_config
	_boot
}

main
