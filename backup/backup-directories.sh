# Used for backing up all the directories in a certain directory
# Stores them in {BACKUP_DIR}
# Compressed with bzip, use tar -czf for a faster gzip compression

find ./* -maxdepth 0 -type d -exec echo "Archiving {}" \; -exec tar -cjf "{BACKUP_DIR}/{}-{DATE}.tar.bz2" \;
