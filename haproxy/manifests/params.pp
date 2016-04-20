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
#   e.g. "Specify one or more upstream haproxy servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_haproxy_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'haproxy':
#    servers => [ 'pool.haproxy.org', 'haproxy.local.company.com' ],
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
class haproxy::params {

	$autoupdate		= false
	$config			= '/etc/haproxy/haproxy.cfg'
	$config_template	= 'haproxy/haproxy.cfg.erb'
	$config_backend_map	= '/etc/haproxy/backend.map'
	$config_backend_template= 'haproxy/backend.map.erb'
	$config_cert		= '/etc/haproxy/EV_axsmarine.com.pem'
	$config_cert_file	= 'haproxy/EV_axsmarine.com.pem'
	$package_ensure		= 'latest'
	$package_name 		= 'haproxy'
	$package_socat_ensure	= 'present'
	$package_hatop_ensure	= 'present'
	$service_enable		= true
	$service_ensure		= 'running'
	$service_manage		= true
	$service_name		= 'haproxy'

}
