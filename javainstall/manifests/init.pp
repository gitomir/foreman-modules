# == Class: java
#
# Full description of class java here.
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
#  class { 'java':
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
class javainstall {

	include ::apt

	apt::ppa { 'ppa:webupd8team/java': }

	exec { 'java-prerequisites':
		path	=> '/bin/:/usr/bin/',
		command	=> 'echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections; echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections',
		creates	=> '/usr/bin/java',
		before	=> Package['oracle-java7-installer'],
	}

	package { 'oracle-java7-installer':
		ensure	=> present,
		require	=> [Apt::Ppa['ppa:webupd8team/java'],Exec['java-prerequisites']],
	}

}
