#
# Database structure for database 'robot'
#

DROP DATABASE IF EXISTS "robot";
CREATE DATABASE "robot" /*!40100 DEFAULT CHARACTER SET latin1 */;

USE "robot";


#
# Table structure for table 'eventos'
#

CREATE TABLE "eventos" (
  "id" int(11) NOT NULL auto_increment,
  "title" tinytext,
  "subtitle" tinytext,
  "description" text,
  "puntosventa" tinytext,
  "ventalink" tinytext,
  "bandadetailurl" tinytext,
  "detailsurl" tinytext,
  "image" tinytext,
  "clasification" tinytext,
  "price" tinytext,
  "location" int(11) default NULL,
  "startDate" datetime NOT NULL default '0000-00-00 00:00:00',
  "endDate" datetime NOT NULL default '0000-00-00 00:00:00',
  "created" timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  ("id")
) AUTO_INCREMENT=25;



#
# Table structure for table 'location'
#

CREATE TABLE "location" (
  "id" int(11) NOT NULL auto_increment,
  "title" tinytext,
  PRIMARY KEY  ("id")
) AUTO_INCREMENT=9;



