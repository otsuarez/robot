This is a web scrapping tool written in Perl. 

This program is splitted in three main components:

* The sites directory. For each site to be crawled, an ini file is created and placed on this directory. Properties like the site's url and frequency of indexing are declared on this files.
* The plugins directory. The parsing regex code is stored in Perl modules, so same syntax can be shared by more than two sites.
* engine.pl. An script to be executed from cron. Checks the sites directory for ini files and perform the corresponding scrapping and stores the obtained data in a database.

A new site can be added just by adding the relevant ini and pm (if required) files to the corresponding directories.

The engine logs to the syslog facility.

This tool was written for an social network site and its original purpose was to collect (cultural, sports, etc) events from several other social web sites.

Documentation (spanish) is available on the https://github.com/otsuarez/robot/wiki.
