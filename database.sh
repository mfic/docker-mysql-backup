#!/bin/bash

current_time=$(date "+%Y.%m.%d-%H.%M.%S")

function backup(){
	# Backup
	docker exec $container /usr/bin/mysqldump -u $user --password=$passwd $database > $file.sql
}

function restore() {
	# Restore
	cat $file | docker exec -i $container /usr/bin/mysql -u $user --password=$passwd $database
}

function remove_old() {
	# Remove old backups
	find $backup_dir -name "backup-$container-*.sql" -type f -mtime +$time -exec rm -f {}
}

# Check if $backup_dir folder exists
if [[ ! -d $backup_dir ]]
then
	mkdir $backup_dir
fi
# Call definitions

if [[ -f $1 ]]
then
	source $1
else
	echo "File not found. Please define env file."
	exit 1
fi

case "$2" in
	backup)
		file="$backup_dir/backup-$container-$current_time.sql"
		backup
		echo "Backup completed!"
		remove_old
		echo "Deleted backups older than $time"
		;;

	restore)
		file=$3
		if [[ -f "$file" ]]
		then
			restore
			echo "Restore completed"
		else 
			echo "File not found. Please specify correct path to the MySQL backup you wish to restore."
		fi
		;;

	*)
		echo "Use either backup or restore"
		exit 1
esac
