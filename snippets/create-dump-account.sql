-- No privileges
GRANT USAGE ON *.* TO 'dump'@localhost IDENTIFIED BY '...';

-- whatever DBs you need
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON `databasename`.* TO 'dump'@localhost;
