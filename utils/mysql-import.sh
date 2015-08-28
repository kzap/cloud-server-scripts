# Used to import many gzipped SQL files, usually when restoring from backups.
# The filenames would be in the format of DBNAME.sql.gz
# Be sure to replace {PASSWORD} with your password for importing
#
for SQL in *.sql.gz; do DB=${SQL/\.sql.gz/}; echo importing $DB; zcat $SQL | mysql -u root --password='{PASSWORD}' $DB; done