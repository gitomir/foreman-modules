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
class zabbix_agent (

        $autoupdate             = $zabbix_agent::params::autoupdate,
        $config                 = $zabbix_agent::params::config,
        $config_template        = $zabbix_agent::params::config_template,
        $package_ensure         = $zabbix_agent::params::package_ensure,
        $package_name           = $zabbix_agent::params::package_name,
        $service_enable         = $zabbix_agent::params::service_enable,
        $service_ensure         = $zabbix_agent::params::service_ensure,
        $service_manage         = $zabbix_agent::params::service_manage,
        $service_name           = $zabbix_agent::params::service_name,
	$zabbix_server		= $zabbix_agent::params::zabbix_server,
	$zabbix_server_act	= $zabbix_agent::params::zabbix_server_act,
	$zabbix_sourceip	= $zabbix_agent::params::zabbix_sourceip,
	$zabbix_listenip	= $zabbix_agent::params::zabbix_listenip,
	$zabbix_listenport	= $zabbix_agent::params::zabbix_listenport,
	$zabbix_logfile_name	= $zabbix_agent::params::zabbix_logfile_name,
	$zabbix_logfile_size	= $zabbix_agent::params::zabbix_logfile_size,
	$zabbix_debug_level	= $zabbix_agent::params::zabbix_debug_level,
	$zabbix_hostname	= $zabbix_agent::params::zabbix_hostname,
	$zabbix_startagents	= $zabbix_agent::params::zabbix_startagents,
	$zabbix_pidfile		= $zabbix_agent::params::zabbix_pidfile,
	$zabbix_includedir	= $zabbix_agent::params::zabbix_includedir,
	$zabbix_moduledir	= $zabbix_agent::params::zabbix_moduledir,
	$manage_repo		= $zabbix_agent::params::manage_repo,
	$repo_location		= $zabbix_agent::params::repo_location,
	$zabbix_version		= $zabbix_agent::params::zabbix_version,
        $script_haproxy         = $zabbix_agent::params::script_haproxy,
        $script_mysql           = $zabbix_agent::params::script_mysql,
        $script_mysql_cc        = $zabbix_agent::params::script_mysql_cc,
        $script_apache          = $zabbix_agent::params::script_apache,
        $script_memcache        = $zabbix_agent::params::script_memcache,
        $script_elastic         = $zabbix_agent::params::script_elastic,
        $script_vfsdev          = $zabbix_agent::params::script_vfsdev,
        $script_nfsclient       = $zabbix_agent::params::script_nfsclient,
        $script_drbd            = $zabbix_agent::params::script_drbd,
	$script_execdir		= $zabbix_agent::params::script_execdir,

        ) inherits zabbix_agent::params {

}
