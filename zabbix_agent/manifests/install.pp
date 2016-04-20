# == Class: zabbix_agent
#
# Full description of class zabbix_agent here.
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
#  class { 'zabbix_agent':
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
class zabbix_agent::install inherits zabbix_agent {
	
	package { 'zabbix_agent':
		ensure	=> $package_ensure,
		name	=> $package_name,
		require	=> Class['zabbix_agent::repo'],
	}

	package { 'zabbix_sender':
		ensure	=> $package_ensure,
		name	=> 'zabbix-sender',
		require => Class['zabbix_agent::repo'],
	}

	package { 'netcat':
		name	=> "netcat-openbsd"
	}

}
