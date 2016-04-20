# == Class: php
#
# Full description of class php here.
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
#  class { 'php':
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
class php (

	$has_apache	= true,
	$has_php52	= true,
	$has_php53	= true,
	$php53_ini_file	= "php/php-53.ini.erb",
        $axs_php52	= ["axs-php-52", "axs-php-52-imagick", "axs-php-52-memcache"],
        $axs_php53	= ["axs-php-53", "axs-php-53-imagick", "axs-php-53-memcache"],
        $axs_php_mod_deps = ["make","autoconf","libzmq3","libzmq3-dev","libevent-dev","pdftk", "axs-libmysqlclient16", "axs-libgd2"],
	) {

	package { $axs_php_mod_deps:
               	ensure => present
        }


	if ($has_apache) {

		if ($has_php52) {
	        file {"/usr/local/php52/etc/php52/apache2":
        	        ensure => "directory",
                	require => Package[$axs_php52]
	        }

	        file {"/usr/local/php52/etc/php52/apache2/php.ini":
        	        content => template("php/php-52.ini.erb"),
                	ensure => present,
		#FIME
        	#        notify => Service["apache2"],
	                require => [Package["axs-php-52"], File["/usr/local/php52/etc/php52/cli"]]
        	}

		file {"/etc/apache2/php52.conf":
        	        mode => 644,
                	owner => root,
	                group => root,
        	        source => "puppet:///modules/php/php52.conf",
                	ensure => present,
			#FIXME
        	        #require => [Package["apache2"], Package["axs-php-52"]]
                	require => Package["axs-php-52"]
	        }

        	} #end if has_php52

		if ($has_php53) {
		file {"/usr/local/php53/etc/php53/apache2":
                	ensure => "directory",
	                require => Package[$axs_php53]
        	}

	        file {"/usr/local/php53/etc/php53/apache2/php.ini":
        	        content => template($php53_ini_file),
                	ensure => present,
		#FIXME
        	#        notify => Service["apache2"],
	                require => Package["axs-php-53"]
        	}
	        

        	file {"/etc/apache2/php53.conf":
                	mode => 644,
	                owner => root,
        	        group => root,
                	source => "puppet:///modules/php/php53.conf",
	                ensure => present,
			#FIXME
                	#require => [Package["apache2"], Package["axs-php-53"]]
	                require => Package["axs-php-53"]
		}
		} #end if has_php53

	} #end if has_apache
	if ($has_php52) {

	        package { $axs_php52:
        	        ensure => present,
			#FIXME require external class apt::source
        	        #require => [Apt::Source['apt.vcloud.axsmarine.com'], Package[$axs_php_mod_deps]]
                	#require => Package[$axs_php_mod_deps]
	        }

	        file {"/etc/php/php52":
        	        ensure => "link",
                	target => "/usr/local/php52/etc/php52/",
        	}

	        file {"/usr/local/php52/etc/php52/cli/php.ini":
        	        content => template("php/php-52.ini.erb"),
                	ensure => present,
	                require => Package["axs-php-52"]
        	}

	        file {"/usr/lib/cgi-bin/php52-cgi":
        	        mode => 755,
                	owner => root,
	                group => root,
        	        source => "puppet:///modules/php/php52-cgi",
                	ensure => present,
	                require => Package["axs-php-52"]
        	}
	
	        file {"/usr/local/php52/etc/php52/cli":
        	        ensure => "directory",
                	require => Package[$axs_php52]
	        }

	        file {"/var/log/php-52-error.log":
        	        mode    => 664,
                	owner   => root,
			#FIXME
        	        #group   => axsmarine,
                	ensure  => present,
	                require => Package["axs-php-52"]
        	        #FIXME user
			#require => [User["axsmarine"], Package["axs-php-52"]]
		}

		#Following two packages (libt1-5 & libjpeg62) are linked to php52-gd module and they are mandatory!!!
        	package { "libjpeg62":
                	ensure => present
	        }

        	package { "libt1-5":
                	ensure => present
	        }

	} #end if has_php52

	if ($has_php53) {

	        package { $axs_php53:
        	        ensure => present,
			#FIXME require external class apt::source
	                #require => [Apt::Source['apt.vcloud.axsmarine.com'], Package[$axs_php_mod_deps]]
        	        #require => Package[$axs_php_mod_deps]
	        }


	        file {"/etc/php/php53":
        	        ensure => "link",
                	target => "/usr/local/php53/etc/php53/",
        	}

	        file {"/usr/local/php53/etc/php53/cli":
        	        ensure => "directory",
                	require => Package[$axs_php53]
	        }
	
	        file {"/usr/local/php53/etc/php53/cli/php.ini":
        	        content => template($php53_ini_file),
                	ensure => present,
	                require => [Package["axs-php-53"], File["/usr/local/php53/etc/php53/cli"]],
        	}

	        file {"/usr/lib/cgi-bin/php53-cgi":
        	        mode => 755,
                	owner => root,
	                group => root,
        	        source => "puppet:///modules/php/php53-cgi",
                	ensure => present,
	                require => Package["axs-php-53"]
        	}

	        file {"/var/log/php-53-error.log":
        	        mode    => 664,
                	owner   => root,
	                #FIXME group 
			#group   => axsmarine,
                	ensure  => present,
	                require => Package["axs-php-53"]
        	        #FIXME user
			#require => [User["axsmarine"], Package["axs-php-53"]]
	        }

	} #end if has_php53

if ($has_php53) {

        exec {"pecl-libzmq":
                user            => "root",
                command         => "/usr/bin/printf \"\\n\" | /usr/local/php53/bin/pecl install zmq channel://pecl.php.net/zmq-1.1.2",
                creates         => "/usr/local/php53/lib/php/extensions/no-debug-non-zts-20090626/zmq.so",
                require         => Package[$axs_php53]
        }

        exec {"pecl-libevent":
                user            => "root",
                command         => "/usr/bin/printf \"\\n\" | /usr/local/php53/bin/pecl install libevent channel://pecl.php.net/libevent-0.1.0",
                creates         => "/usr/local/php53/lib/php/extensions/no-debug-non-zts-20090626/libevent.so",
                require         => Package[$axs_php53]
        }

        #PEAR
        exec {"pear-ole":
                user            => "root",
                command         => "/usr/local/php53/bin/pear install -f OLE channel://pear.php.net/OLE-1.0.0RC1",
                creates         => "/usr/local/php53/pear/OLE",
		refreshonly	=> true,
                require         => Package[$axs_php53]
        }

        exec {"pear-spreadsheet-writer":
                user            => "root",
                command         => "/usr/local/php53/bin/pear install -f Spreadsheet_Excel_Writer channel://pear.php.net/Spreadsheet_Excel_Writer-0.9.3",
                creates         => "/usr/local/php53/pear/Spreadsheet/Excel/Writer",
                require         => [Package[$axs_php53],  Exec["pear-ole"]]
        }

} #end if has_php53

if ($has_php52) {

        exec {"pear-ole52":
                user            => "root",
                command         => "/usr/local/php52/bin/pear install --ignore-errors OLE channel://pear.php.net/OLE-1.0.0RC1",
                creates         => "/usr/local/php52/pear/OLE",
		refreshonly	=> true,
                require         => Package[$axs_php52]
        }

        exec {"pear-spreadsheet-writer52":
                user            => "root",
                command         => "/usr/local/php52/bin/pear install --ignore-errors Spreadsheet_Excel_Writer channel://pear.php.net/Spreadsheet_Excel_Writer-0.9.3",
                creates         => "/usr/local/php52/pear/Spreadsheet/Excel/Writer",
                require         => [Package[$axs_php52],  Exec["pear-ole52"]]
        }

} #end if has_php52

}
