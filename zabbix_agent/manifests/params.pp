# == Class: zabbix_agent
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
#
# === Authors
#
# Miroslav Nikolov <miroslav.nikolov@axsmarine.com>
#
#
class zabbix_agent::params {

	$autoupdate		= false
	$config			= '/etc/zabbix/zabbix_agentd.conf'
	$config_template	= 'zabbix_agent/zabbix_agentd.conf.erb'
	$package_ensure		= 'latest'
	$package_name 		= 'zabbix-agent'
	$service_enable		= true
	$service_ensure		= 'running'
	$service_manage		= true
	$service_name		= 'zabbix-agent'
	$zabbix_server		= 'zabbix'
	$zabbix_server_act	= undef
	$zabbix_sourceip	= $::ipaddress
	$zabbix_listenip	= $::ipaddress
	$zabbix_listenport	= '10050'
	$zabbix_logfile_name	= '/var/log/zabbix/zabbix_agentd.log'
	$zabbix_logfile_size	= '1'
	$zabbix_debug_level	= '3'
	$zabbix_hostname	= $::hostname
	$zabbix_startagents	= '5'
	$zabbix_pidfile		= '/var/run/zabbix/zabbix_agentd.pid'
	$zabbix_includedir	= '/etc/zabbix/zabbix_agentd.d/'
	$zabbix_moduledir	= undef
        $manage_repo		= true
        $repo_location		= ''
        $zabbix_version		= '3.0'
        $script_haproxy         = false
        $script_mysql           = false
        $script_mysql_cc        = false
        $script_apache          = false
        $script_memcache        = false
        $script_elastic         = false
        $script_vfsdev          = true
        $script_nfsclient       = false
        $script_drbd            = false
        $script_execdir         = '/usr/local/bin/'

}
