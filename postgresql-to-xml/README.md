ap20-utils/postgresql-to-xml
----------------------------

Utility script used to generate a set of xml files from any postgresql relational database

Contents:
* run.sh: an executable bash script which takes a postgresql database name
* list_tables.sql: a postgresql command file to generate a list of table names
* example.log: a log file of a successful run (databasename=diggers) showing what the script does

Usage: (You need to chmod 775 run.sh so it is executable): ./run.sh postgresqldatabasename

Requirements: 
* a recent postgresql installation which supports the "query_to_xml" command
* the psql postgresql command line utility
* perl 
* Saxon HE or PE XML processor (assembles an all in one xml file)

The script will query the postgresqldatabasename supplied and generate a list of table names. It creates a directory named the same as the database for all output. It uses postgresql's "query_to_xml" command to generate an xml file for each table in the database. Optionally you can modify the script to determine customised sort sequences for each table (the default is no order by clause). Perl is used to convert from generic 'row" elements to generate an element named the same as the table.

If your database is very large the final step which makes an all in one xml file, and generates an md5 checksum, may be commented out.

Depending on your requirements you can create a BaseX XML database from the single table xml files or from the all in one xml file. Refer to your BaseX or other XML database documentation for how to create an xml database from these file(s).


Initial version: ss 19 March 2014

