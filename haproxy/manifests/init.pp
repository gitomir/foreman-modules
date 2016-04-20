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
class haproxy (

	$autoupdate		= $haproxy::params::autoupdate,
	$config			= $haproxy::params::config,
	$config_template	= $haproxy::params::config_template,
	$config_backend_map	= $haproxy::params::config_backend_map,
	$config_backend_template= $haproxy::params::config_backend_template,
	$config_cert		= $haproxy::params::config_cert,
	$config_cert_file	= $haproxy::params::config_cert_file,
	$package_ensure		= $haproxy::params::package_ensure,
	$package_name 		= $haproxy::params::package_name,
	$package_socat_ensure	= $haproxy::params::package_socat_ensure,
	$package_hatop_ensure	= $haproxy::params::package_hatop_ensure,
	$service_enable		= $haproxy::params::service_enable,
	$service_ensure		= $haproxy::params::service_ensure,
	$service_manage		= $haproxy::params::service_manage,
	$service_name		= $haproxy::params::service_name,
	) inherits haproxy::params {

}
