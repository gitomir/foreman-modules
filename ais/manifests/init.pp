# == Class: ais
#
# Full description of class ais here.
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
#  class { 'ais':
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

# NOTICE ! the required user ais is creaded via module accounts in class accounts::users::ais. check foreman params for host

class ais (

	$has_ais_server		= false,
	$has_ais_infinite	= false,
	$has_vsftpd		= false,
	$has_apache		= false,
	$php_dependencies	= ["php5","php5-gearman","libapache2-mod-php5","git"]
	){


	# PHP + CRONS (future use) CONF

	if ($has_ais_server) {

		package{$php_dependencies:
			ensure	=> latest,
		}
	
        	file {"/etc/php5/cli/php.ini" :
	                content => file("ais/php/php.ini"),
        	        ensure	=> present,
                	require => Package[$php_dependencies],
	        }

	} #end if has_ais_server

	# APACHE CONF

	if ($has_apache) {

	        class {"apache":
                service_ensure  => running,
                user            => "ais",
                group           => "ais",
                manage_group    => false,
                manage_user     => false,
                log_level       => "info",
                default_vhost   => false,
                serveradmin     => "sysadmin@axsmarine.com",
                server_tokens   => "Prod",
                server_signature=> "Off",
                mpm_module      => "prefork",
                keepalive       => "On",
                keepalive_timeout => "15",
                max_keepalive_requests => "100",
                default_mods   =>       [  "access_compat","actions","alias","auth_basic","authn_core","authn_file","authz_user","authz_groupfile","autoindex","cgi","deflate","dir","env","expires","filter","mime","negotiation","reqtimeout","setenvif", "ssl", "status"]
        }

		apache::vhost {'ais-default' :
                	port		=> 80,
			ssl		=> false,
			docroot		=> '/data2/www/WWW',
			docroot_owner	=> "ais",
			docroot_group	=> "ais",
			directories => [
			{
				'path' => '/data2/www/WWW/',
				'options' => 'FollowSymLinks',
				'allowoverride' => 'All',
                               	'directoryindex' => 'index.php',
	                	'auth_require'   => 'all granted'
                        }
                	],
	                aliases => [{
        	                alias => '/WWW/SignalAccuracy',
                	        path  => '/data2/www/WWW/signal-accuracy'
	                }],

        	}

	        include apache::mod::php

		
	        package {'apache2-utils':
        		ensure => installed
	        }


	} # end if has_apache

	# FTP CONF

	if ($has_vsftpd) {

		package{'vsftpd':
			ensure	=> installed
		}

		package{'libpam-pwdfile':
			ensure	=> installed
		}


	        service {'vsftpd':
        	        enable	=> true,
                	ensure	=> running,
	                require	=> Package['vsftpd']
        	}


	        file {"/data/2/axsftp":
        	        ensure  => "directory",
                	owner   => "vsftpd",
	                group   => "ais",
        	        mode    => 2770,
                	require => [Package["vsftpd"], Exec["create_directory_structure"]]
	        }

        	file {"/etc/vsftpd/":
	                ensure  => "directory",
        	        owner   => "root",
                	group   => "root",
	                mode    => 644,
        	        require => Package['vsftpd']
	        }

        	file {"/etc/vsftpd_user_conf/":
                	ensure  => "directory",
	                owner   => "root",
        	        group   => "root",
                	mode    => 644,
	                require => Package['vsftpd']
        	}

        	file {"/etc/vsftpd_user_conf/axsftp":
                	ensure  => "file",
	                owner   => "root",
        	        group   => "root",
                	mode    => 644,
			content	=> file("vsftpd/axsftp"),
	                require => Package['vsftpd']
        	}

        	file {"/etc/vsftpd_user_conf/axsris":
                	ensure  => "file",
	                owner   => "root",
        	        group   => "root",
                	mode    => 644,
			content	=> file("vsftpd/axsris"),
	                require => Package['vsftpd']
		}

	        file {"/etc/vsftpd/ftpd.passwd":
        	        content => template("vsftpd/vsftpd_passwd_ais2.conf.erb"),
                	ensure => present,
	                notify => Service['vsftpd'],
        	        require => Package['vsftpd']
	        }
	
	        file {"/etc/vsftpd.chroot_list":
       		        ensure  => present,
                	notify => Service['vsftpd'],
	                require => Package["vsftpd"],
        	        owner   => "root",
                	group   => "root",
	                mode    => 600,
        	        replace => true,
                	content => "boyan.milanov"
	        }

        	file {"/etc/vsftpd.conf":
                	content => template("vsftpd/vsftpd_aws_ais.conf.erb"),
	                ensure => present,
        	        notify => Service['vsftpd'],
                	require => Package['vsftpd']
	        }


        	file {"/etc/pam.d/vsftpd":
                	content => template("vsftpd/pamd_config_public.conf.erb"),
	                ensure => present,
        	        notify => Service['vsftpd'],
                	require => Package['vsftpd']
	        }

	        file {["/data/data_ris/", "/data/data_ris/data_ris"]:
        	        ensure  => "directory",
                	owner   => "vsftpd",
	                group   => "nogroup",
        	        mode    => 775,
                	require => Package['vsftpd']
        	}
	
	        file {"create_directory_structure.sh":
        	        ensure	=> 'file',
                	content	=> file("ais/create_directory_structure.sh"),
	                path	=> '/tmp/create_directory_structure.sh',
        	        owner	=> 'root',
                	mode	=> '0770',
	                notify	=> Exec['create_directory_structure'],
        	}

	        exec {'create_directory_structure':
        	        command		=> '/tmp/create_directory_structure.sh',
                	refreshonly	=> true
	        }

        	file { '/data2':
                	ensure  => 'link',
	                target  => '/data/2',
        	        owner   => 'ais',
                	group   => 'ais',
			mode    => '0775',
			require => [Exec['create_directory_structure'],User["ais"]]
	        }

        	file { '/data3':
                	ensure  => 'link',
			target  => '/data/3',
			owner   => 'ais',
			group   => 'ais',
			mode    => '0775',
			require => [Exec['create_directory_structure'],User["ais"]]
	        }


	} #end if has_vsftpd

}
