# == Class: dt
#
# Full description of class dt here.
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
#  class { 'dt':
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
class dtserver (

	$has_dtserver	= false,
	$has_dtcache	= false,
	$has_dtseca	= false

	){

#FIXME axsmarine user and group deps


if ($has_dtserver) {

        # DISTANCE TABLE dt Server64 Server64_11_08_2014
        $axs_dt = ["axs-dt-p2p", "axs-dt-s2p"]
        $axs_dt_deps = ["libxmu6","libxp6","libc6-i386","mysql-client","nodejs"]

        package { $axs_dt_deps:
                ensure => present,
        }

        package { $axs_dt:
                ensure => latest,
                require => Package[$axs_dt_deps]
        }

        file { '/data/Server64a':
                ensure => 'link',
                target => '/data/dt-p2p',
                owner => 'axsmarine',
                group => 'axsmarine',
                mode => '777',
        }

        file { '/data/Server64_11_08_2014':
                ensure => 'link',
                target => '/data/dt-s2p',
                owner => 'axsmarine',
                group => 'axsmarine',
                mode => '777',
        }


        exec { "axs-dt-p2p":
                cwd             => "/data/dt-p2p",
                command         => "/data/dt-p2p/server.sh",
                user            => "axsmarine",
                unless          => "/bin/ps aux | /bin/grep axsServer | /bin/grep -v grep",
                require         => Package[$axs_dt]
        }

        exec { "axs-dt-s2p":
                cwd             => "/data/dt-s2p",
                command         => "/data/dt-s2p/AXSROUTER start",
                user            => "axsmarine",
                unless          => "/bin/ps aux | /bin/grep axsserver | /bin/grep -v grep",
                require         => Package[$axs_dt]
        }
} # end if has_dtserver

if ($has_dtcache) {

        package {"axs-dtcache":
                ensure  => present,
                require => Package[$axs_dt_deps]
        }

        file {"/etc/dtcache.conf":
                ensure  => present,
                require => Package["axs-dtcache"],
                notify  => Service["dtcache"],
                content => file("dtserver/dtcache-AWS.conf")
        }

        service {"dtcache":
                ensure  => "running",
                require => Package["axs-dtcache"]
        }
} #end if has_dtcache

if ($has_dtseca) {

	package {'axs-dt-seca-tcp':
		ensure	=> latest
	}

	package {'axs-mcr':
		ensure	=> latest
	}

	file {'/etc/dt-seca-tcp/dt-seca-tcp.conf' :
                ensure  => file,
                content => file("dtserver/dt-seca-tcp.conf"),
        }

} #end if has_dtseca

}
