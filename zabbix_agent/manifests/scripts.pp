class zabbix_agent::scripts (
	$service_name		= $zabbix_agent::params::service_name,
        $zabbix_includedir      = $zabbix_agent::params::zabbix_includedir,
	$script_execdir		= $zabbix_agent::params::script_execdir,
	$script_haproxy		= $zabbix_agent::params::script_haproxy,
	$script_mysql		= $zabbix_agent::params::script_mysql,
	$script_mysql_cc	= $zabbix_agent::params::script_mysql_cc,
	$script_apache		= $zabbix_agent::params::script_apache,
	$script_memcache	= $zabbix_agent::params::script_memcache,
	$script_elastic		= $zabbix_agent::params::script_elastic,
	$script_vfsdev		= $zabbix_agent::params::script_vfsdev,
	$script_nfsclient	= $zabbix_agent::params::script_nfsclient,
	$script_drbd		= $zabbix_agent::params::script_drbd,)
	inherits zabbix_agent::params {


	#default in zabbix-agent 3.0 has userparameter_mysql so remove it
	file {'/etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf':
		ensure	=> absent
	}

	if ($script_haproxy) {

		$script_haproxy_userparam_file	= "${zabbix_includedir}userparam_haproxy.conf"
		$script_haproxy_executable	= "${script_execdir}zhaproxy_discovery.sh"

		file {$script_haproxy_userparam_file:
			ensure	=> file,
			owner	=> "zabbix",
			group	=> "zabbix",
			mode	=> 440,
			content	=> file("zabbix_agent/userparam_haproxy.conf"),
			require	=> Package['zabbix_agent'],
			notify	=> Service[$service_name],
		}

		file {$script_haproxy_executable:
			ensure	=> file,
			owner	=> "zabbix",
			group	=> "root",
			mode	=> 550,
			content	=> file("zabbix_agent/zhaproxy_discovery.sh"),
			require	=> Package['zabbix_agent'],
		}

	} # end if ($script_haproxy)

	if ($script_mysql) {

		$zabbix_homedir			= "/var/lib/zabbix/"
                $script_mysql_userparam_file	= "${zabbix_includedir}userparam_mysql.conf"
                $script_mysql_executable	= "${script_execdir}zmysql_stats_wrapper.sh"
		$script_mysql_ss_php_exec	= "${script_execdir}ss_get_mysql_stats.php"
		$script_mysql_ss_php_conf	= "${script_execdir}ss_get_mysql_stats.php.cnf"
		$script_mysql_my_cnf		= "${zabbix_homedir}.my.cnf"
	        $template_mysql_deps		= ["php5-cli","php5-mysql","libmysqlclient18","mysql-common"]

	        package {$template_mysql_deps:
        	        ensure  => present
	        }

                file {$script_mysql_userparam_file:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "zabbix",
                        mode    => 440,
                        content => file("zabbix_agent/userparam_mysql.conf"),
                        require => Package['zabbix_agent'],
                        notify  => Service[$service_name],
                }

                file {$script_mysql_executable:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "root",
                        mode    => 550,
                        content => file("zabbix_agent/zmysql_stats_wrapper.sh"),
                        require => Package['zabbix_agent'],
                }

                file {$script_mysql_ss_php_exec:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "root",
                        mode    => 440,
                        content => file("zabbix_agent/ss_get_mysql_stats.php"),
                        require => Package['zabbix_agent'],
                }

                file {$script_mysql_ss_php_conf:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "root",
                        mode    => 400,
                        content => file("zabbix_agent/ss_get_mysql_stats.php.cnf"),
                        require => Package['zabbix_agent'],
                }

		file {$zabbix_homedir:
			ensure	=> directory,
			owner	=> "zabbix",
			group	=> "zabbix",
			mode	=> 750,
		}


                file {$script_mysql_my_cnf:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "zabbix",
                        mode    => 400,
                        content => file("zabbix_agent/my.cnf"),
                        require => [Package['zabbix_agent'],File[$zabbix_homedir]]
                }

		#FIXME mysqli.default.socket in php.ini

	} # end if ($script_mysql)

	if ($script_mysql_cc) {

                $script_mysql_cc_userparam_file  = "${zabbix_includedir}userparam_mysql_cc.conf"
                $script_mysql_cc_executable      = "${script_execdir}zmysql_cc.sh"

                file {$script_mysql_cc_userparam_file:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "zabbix",
                        mode    => 440,
                        content => file("zabbix_agent/userparam_mysql_cc.conf"),
                        require => Package['zabbix_agent'],
                        notify  => Service[$service_name],
                }

                file {$script_mysql_cc_executable:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "root",
                        mode    => 550,
                        content => file("zabbix_agent/zmysql_cc.sh"),
                        require => Package['zabbix_agent'],
                }

	} # end if ($script_mysql_cc)

	if ($script_apache) {

		$script_apache_userparam_file   = "${zabbix_includedir}userparam_apache.conf"
                $script_apache_executable       = "${script_execdir}zapache.sh"

                file {$script_apache_userparam_file:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "zabbix",
                        mode    => 440,
                        content => file("zabbix_agent/userparam_apache.conf"),
                        require => Package['zabbix_agent'],
                        notify  => Service[$service_name],
                }

                file {$script_apache_executable:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "root",
                        mode    => 550,
                        content => file("zabbix_agent/zapache.sh"),
                        require => Package['zabbix_agent'],
                }

	} # end if ($script_apache)

	if ($script_memcache) {

                $script_memcache_userparam_file  = "${zabbix_includedir}userparam_memcache.conf"
                $script_memcache_executable      = "${script_execdir}zmemcache.sh"

                file {$script_memcache_userparam_file:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "zabbix",
                        mode    => 440,
                        content => file("zabbix_agent/userparam_memcache.conf"),
                        require => Package['zabbix_agent'],
                        notify  => Service[$service_name],
                }

                file {$script_memcache_executable:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "root",
                        mode    => 550,
                        content => file("zabbix_agent/zmemcache.sh"),
                        require => [Package['zabbix_agent'],Package["netcat"]],
                }

	} # end if ($script_memcache)

	if ($script_elastic) {
	} # end if ($script_elastic)

	if ($script_vfsdev) {

		$script_vfsdev_userparam_file	= "${zabbix_includedir}userparam_vfsdev.conf"
		$script_vfsdev_executable	= "${script_execdir}zvfsdev_discovery.sh"

		file {$script_vfsdev_userparam_file:
			ensure	=> file,
			owner	=> "zabbix",
			group	=> "zabbix",
			mode	=> 440,
			content	=> file("zabbix_agent/userparam_vfsdev.conf"),
			require	=> Package['zabbix_agent'],
			notify	=> Service[$service_name],
		}

		file {$script_vfsdev_executable:
			ensure	=> file,
			owner	=> "zabbix",
			group	=> "root",
			mode	=> 550,
			content	=> file("zabbix_agent/zvfsdev_discovery.sh"),
			require	=> Package['zabbix_agent'],
		}

	} # end if ($script_vfsdev)

	if ($script_nfsclient) {

                $script_nfsclient_userparam_file   = "${zabbix_includedir}userparam_nfsclient.conf"
                $script_nfsclient_discovery        = "${script_execdir}znfs_discovery.sh"
                $script_nfsclient_executable       = "${script_execdir}znfs_check.sh"

                file {$script_nfsclient_userparam_file:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "zabbix",
                        mode    => 440,
                        content => file("zabbix_agent/userparam_nfsclient.conf"),
                        require => Package['zabbix_agent'],
                        notify  => Service[$service_name],
                }

                file {$script_nfsclient_executable:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "root",
                        mode    => 550,
                        content => file("zabbix_agent/znfs_check.sh"),
                        require => Package['zabbix_agent'],
                }

                file {$script_nfsclient_discovery:
                        ensure  => file,
                        owner   => "zabbix",
                        group   => "root",
                        mode    => 550,
                        content => file("zabbix_agent/znfs_discovery.sh"),
                        require => Package['zabbix_agent'],
                }


	} # end if ($script_nfsclient)

	if ($script_drbd) {

                $script_drbd_userparam_file   = "${zabbix_includedir}userparam_drbd.conf"

		file {$script_drbd_userparam_file:
			ensure	=> file,
			owner	=> "zabbix",
			group	=> "zabbix",
			mode	=> 440,
			content	=> file("zabbix_agent/userparam_drbd.conf"),
			require	=> Package['zabbix_agent'],
			notify	=> Service[$service_name],
		}

	} # end if ($script_drbd)
}
