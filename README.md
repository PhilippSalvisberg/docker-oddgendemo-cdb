# DEPRECATION NOTICE
This project has been deprecated in favor of the [docker-oddgendemo](https://github.com/PhilippSalvisberg/docker-oddgendemo). This repository will not be updated anymore.

# oddgen Demo using an Oracle Database 12.2.0.1 Enterprise Edition with CDB Architecture

## Content

Dockerfile including scripts to build an image containing the following:

* Oracle Linux 7.3-1.0.4.el7.x86_64
* Oracle Database 12.2.0.1 Enterprise Edition with CDB architecture
	* Container database (CDB$ROOT)
	* Pluggable database (OPDB1)
		* Sample schemas SCOTT, HR, OE, PM, IX, SH, BI (master branch as of build time)
		* APEX 5.1.1 including APEX\_LISTENER and APEX\_REST\_PUBLIC\_USER
		* FTLDB 1.5.0
		* tePLSQL (master branch as of build time)
		* oddgen example/tutorial schemas ODDGEN, OGDEMO (main branch as of build time)

Please see [Readme Information for Oracle Database 12c Release 2 (12.2)](https://docs.oracle.com/database/122/READM/features-not-available-12-2-beta.htm#READM-GUID-80BA0601-969E-45F3-9AAF-E570B03E7D7D) regarding restrictions of CDB architecture.

See [docker-oddgendemo](https://github.com/PhilippSalvisberg/docker-oddgendemo) for a non-CDB variant of this image.

Due to [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) I cannot make this image available on a public Docker registry.

## Installation

### Using Default Settings (recommended)

Complete the following steps to create a new container:

1. Create the container

		docker run -d -p 1522:1522 -p 8083-8084:8083-8084 -h ocdb --name ocdb phsalvisberg/oddgendemo-cdb

2. wait around **25 minutes** until the Oracle database instance is created and APEX is installed in the pluggable database. Check logs with ```docker logs -f -t ocdb```. The container is ready to use when the last line in the log is ```Database ready to use. Enjoy! ;-)```. The container stops if an error occurs. Check the logs to determine how to proceed.

Feel free to stop the docker container after a successful installation with ```docker stop -t 60 ocdb```. The container should shutdown the database gracefully within the given 60 seconds and persist the data fully (ready for backup). Next time you start the container using ```docker start ocdb``` the database will start up.

### Options

#### Environment Variables

You may set the environment variables in the docker run statement to configure the docker container setup process. The following table lists all environment variables with its default values:

Environment variable | Default value | Comments
-------------------- | ------------- | --------
WEB_CONSOLE | ```true``` | Set to ```false``` if you do not need APEX and Enterprise Manger Database Express 12c (container is created faster, since APEX will not be removed from CDB and installed in PDB)
DBCA_TOTAL_MEMORY | ```2048```| Keep in mind that DBCA fails if you set this value too low
GDBNAME | ```ocdb.docker``` | The global database name, used also as service name for the container database
ORACLE_SID | ```ocdb```| The Oracle SID of the container database
PDB_NAME | ```opdb1```| The name of the pluggable database
SERVICE_NAME | ```opdb1.docker``` | The Oracle Service Name for the pluggable database
APEX_PASS | ```Oracle12c!```| Initial APEX ADMIN password
PASS | ```oracle```| Password for SYS and SYSTEM

Here's an example run call amending the SYS/SYSTEM password and skip APEX installation in PDB:

```
docker run -e PASS=manager -e WEB_CONSOLE=false -d -p 1522:1522 -p 8083-8084:8083-8084 -h ocdb --name ocdb phsalvisberg/oddgendemo-cdb
```

#### Volumes

The image defines a volume for ```/u01/app/oracle```. You may map this volume to a storage solution of your choice. Here's an example using a named volume ```ocdb```:

```
docker run -v ocdb:/u01/app/oracle -d -p 1522:1522 -p 8083-8084:8083-8084 -h ocdb --name ocdb phsalvisberg/oddgendemo-cdb
```

Here's an example mapping the local directory ```$HOME/docker/ocdb/u01/app/oracle``` to ```/u01/app/oracle```.

```
docker run -v $HOME/docker/ocdb/u01/app/oracle:/u01/app/oracle -d -p 1522:1522 -p 8083-8084:8083-8084 -h ocdb --name ocdb phsalvisberg/oddgendemo-cdb
```

**Please note**: Volumes mapped to local directories are not stable, at least not in Docker for Mac 1.12.0. E.g. creating a database may never finish. So I recommend not to use local mapped directories for the time being. Alternatively you may use a volume plugin. A comprehensive list of volume plugins is listed [here](https://docs.docker.com/engine/extend/plugins/#volume-plugins).

#### Change Timezone

The default timezone of the container is UTC. To query the available timezones run:

```
docker exec ocdb ls -RC /usr/share/zoneinfo
```

To change the timezone to "Central European Time (CET)" run the following two commands:

```
docker exec ocdb unlink /etc/localtime
docker exec ocdb ln -s /usr/share/zoneinfo/Europe/Zurich /etc/localtime
```

Restart your container to ensure the new setting take effect.

```
docker restart -t 60 ocdb
```

## Access To Database Services

### Enterprise Manager Database Express 12c

[http://localhost:8083/em/](http://localhost:8083/em/)

User | Password
-------- | -----
system | oracle
sys | oracle

### APEX

[http://localhost:8084/apex/](http://localhost:8084/apex/)

Property | Value
-------- | -----
Workspace | INTERNAL
User | ADMIN
Password | Oracle12c!

### Database Connections

To access the database e.g. from SQL Developer you configure the following properties:

Property | Value
-------- | -----
Hostname | localhost
Port | 1522
SID | ocdb
Service for container database | ocdb.docker
Service for pluggable database | opdb1.docker

The configured user with their credentials are:

User | Password
-------- | -----
pdbadmin | oracle
system | oracle
sys | oracle
apex_listener | oracle
apex\_rest\_public\_user | oracle
apex\_public\_user | oracle
scott | tiger
hr | hr
oe | oe
pm | pm
ix | ix
sh | sh
bi | bi
ftldb | ftldb
teplsql | teplsql
oddgen | oddgen
ogdemo | ogdemo

Use the following connect string to connect as scott via SQL*Plus or SQLcl: ```scott/tiger@localhost:1522/opdb1.docker```

## Backup

Complete the following steps to backup the data volume:

1. Stop the container with

		docker stop -t 30 ocdb

2. Backup the data volume to a compressed file ```ocdb.tar.gz``` in the current directory with a little help from the ubuntu image

		docker run --rm --volumes-from ocdb -v $(pwd):/backup ubuntu tar czvf /backup/ocdb.tar.gz /u01/app/oracle

3. Restart the container

		docker start ocdb

## Restore

Complete the following steps to restore an image from scratch. There are other ways, but this procedure is also applicable to restore a database on another machine:

1. Stop the container with

		docker stop -t 30 ocdb

2. Remove the container with its associated volume

		docker rm -v ocdb

3. Remove unreferenced volumes, e.g. explicitly created volumes by previous restores

		docker volume ls -qf dangling=true | xargs docker volume rm

4. Create an empty data volume named ```ocdb```

		docker volume create --name ocdb

5. Populate data volume ```ocdb``` with backup from file ```ocdb.tar.gz``` with a little help from the ubuntu image

		docker run --rm -v ocdb:/u01/app/oracle -v $(pwd):/backup ubuntu tar xvpfz /backup/ocdb.tar.gz -C /

6. Create the container using the ```ocdb```volume

		docker run -v ocdb:/u01/app/oracle -d -p 1522:1522 -p 8083-8084:8083-8084 -h ocdb --name ocdb phsalvisberg/oddgendemo-cdb

7. Check log of ```ocdb``` container

		docker logs ocdb

	The end of the log should look as follows:

		Reuse existing database.

		(...)

		Database ready to use. Enjoy! ;-)

## Issues

Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/PhilippSalvisberg/docker-oddgendemo-cdb/issues)
* [submit new issue](https://github.com/PhilippSalvisberg/docker-oddgendemo-cdb/issues/new)

## Credits
This Dockerfile is based on the following work:

- Maksym Bilenko's GitHub project [sath89/docker-oracle-12c](https://github.com/MaksymBilenko/docker-oracle-12c)
- Frits Hoogland's blog post [Installing the Oracle database in docker](https://fritshoogland.wordpress.com/2015/08/11/installing-the-oracle-database-in-docker/)
- Tim Hall's article on [Multitenant : Uninstall APEX from the CDB in Oracle Database 12c Release 1 (12.1)](https://oracle-base.com/articles/12c/multitenant-uninstall-apex-from-the-cdb-12cr1)

## License

docker-oddgendemo is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>.

See [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) and [Oracle Database Licensing Information User Manual](https://docs.oracle.com/database/122/DBLIC/Licensing-Information.htm#DBLIC-GUID-B6113390-9586-46D7-9008-DCC9EDA45AB4) regarding Oracle Database licenses.
