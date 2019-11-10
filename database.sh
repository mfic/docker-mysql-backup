#!/bin/bash

# Save the current time for the file name
current_time=$(date "+%Y.%m.%d-%H.%M.%S")

function backup(){
	# Backup
	docker exec $container /usr/bin/mysqldump -u $user --password=$passwd $database > $file
}

function restore() {
	# Restore
	cat $file | docker exec -i $container /usr/bin/mysql -u $user --password=$passwd $database
}

function remove_old() {
	# Remove old backups
	switch="print"
	old_files="$(find $backup_dir -mindepth 1 -depth -name "backup-$container-*.sql" -type f -mtime +$time -$switch)"
	if [[ $old_files ]]
	then
		counter=0
		for file in $old_files
		do
			echo "Deleting: $file"
			rm -f $file
			((counter++))
		done
		echo "Deleted $counter backup(s) older than $time days"
	else
		echo "No Backups deleted."
	fi
}

# Call definitions

# First sourcing of env file!
if [[ -f $1 ]]
then
	source $1
else
	echo "File not found. Please define env file."
	exit 1
fi

# Check if $backup_dir folder exists
if [[ ! -d $backup_dir ]]
then
	echo "Backup directory not found. Create..."
	mkdir -p $backup_dir
	echo "Backup directory created: $backup_dir"
else
	echo "Backup directory: $backup_dir"
fi

case "$2" in
	backup)
		file="$backup_dir/backup-$container-$current_time.sql"
		backup
		echo "Backup completed!"
		remove_old
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
