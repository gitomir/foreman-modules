# == Class: mass_rsync
#
# Full description of class mass_rsync here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'mass_rsync':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class mass_rsync 
	($install_cron	= false)
{

        file {"/usr/local/tools":
                ensure  => "directory",
                owner   => "root",
                group   => "root",
        }

        file { "/usr/local/tools/mass_rsync.sh":
                mode    => 755,
                owner   => root,
                group   => root,
                content => file("mass_rsync/mass_rsync.sh"),
                ensure  => present,
                require => File["/usr/local/tools/"]
        }

        file { "/usr/local/tools/exclude.rsync":
                mode    => 644,
                owner   => root,
                group   => root,
                content => file("mass_rsync/exclude.rsync"),
                ensure  => present,
                require => File["/usr/local/tools/"]
        }
	
	if ($install_cron) {
	        cron { "mass_rsync":
        	        command         => "/usr/local/tools/mass_rsync.sh > /tmp/mass_rsync.log 2>&1",
                	user            => "root",
	                hour            => "*",
        	        minute          => "*/5",
                	require         => [File["/usr/local/tools/mass_rsync.sh"], File["/usr/local/tools/exclude.rsync"]]
		}
	}
}
