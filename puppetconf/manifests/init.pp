# == Class: puppet
#
# Full description of class puppet here.
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
#  class { 'puppet':
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
class puppetconf (
	$enable	= true ){

	if ($enable) {

	service{'puppet':
		name	=> "puppet",
		ensure	=> "running",
	}

	file{'/etc/puppet/puppet.conf':
		ensure	=> file,
		content	=> template("puppetconf/puppet.agent.conf.erb"),
		notify	=> Service['puppet'],
	}
		
	file{'/etc/puppet/auth.conf':
		ensure	=> file,
		content	=> template("puppetconf/auth.agent.conf.erb"),
		notify	=> Service['puppet'],
	}

	file{'/etc/default/puppet':
		ensure	=> file,
		content	=> template("puppetconf/etc-default-puppet.erb"),
		notify	=> Service["puppet"],
	}

	} #end if enable
}
