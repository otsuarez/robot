This is a web crawler written in Perl. A plugin architecture was choosen in order to achieve flexibility. Sites to be parsed are declared in ini files. Since the same web framework can be used for more than one site, the parser code is encapsuled in perl modules.

A new site can be added just by adding the relevant ini and pm files to the corresponding directories.

The engine logs to the syslog facility.

This was written for an social network site and it original purpose was to gather (cultural, sports, etc) events from several other web sites.

Documentation (spanish) is available on the https://github.com/otsuarez/robot/wiki.
