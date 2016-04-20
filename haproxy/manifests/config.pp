# == Class: haproxy
#
# Full description of class haproxy here.
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
#  class { 'haproxy':
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
class haproxy::config inherits haproxy {

	file { $config:
		ensure	=> file,
		content	=> template($config_template),
		notify	=> Service[$service_name],
	}

 if $config_backend_map {
	file { $config_backend_map:
		ensure	=> file,
		content	=> template($config_backend_template),
		notify	=> Service[$service_name],
	}
 }

 if $config_cert {
	file { $config_cert:
		ensure	=> file,
		content	=> file($config_cert_file),
		notify	=> Service[$service_name],
	}
 }
}
