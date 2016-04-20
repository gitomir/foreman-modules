# == Class: elasticgraylog
#
# Full description of class elasticgraylog here.
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
#  class { 'elasticgraylog':
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
class elasticgraylog (

	$manage_elastic = false,
	$manage_graylog	= false,
	$manage_grayweb	= false,
	$elastic_version= undef

	){

	if ($manage_elastic) {

		if ($elastic_version) { $elastic_package = "elasticsearch=$elastic_version" } else { $elastic_package = "elasticsearch" }

		$elastic_config = '/etc/elasticsearch/elasticsearch.yml'

		package {'elasticsearch':
			name	=> $elastic_package,
			ensure	=> present,
		}

		service {'elasticsearch':
			enable	 => true,
			ensure	 => 'running',
			hasstatus=> true,
    			subscribe=> File[$elastic_config],
			require	 => Package['elasticsearch'],
		}

		file { $elastic_config:
			ensure	=> present,
			owner	=> "root",
			group	=> "root",
			content	=> template("elasticgraylog/elasticsearch.yml.erb"),
			notify	=> Service['elasticsearch']
		}


		class { 'limits':
			purge_limits_d_dir => false,
		}

		limits::limits { 'elasticsearch_nofile':
			ensure     => present,
			user       => 'elasticsearch',
			limit_type => 'nofile',
			hard       => 64000,
		}

	} #end if manage_elastic

	if ($manage_graylog) {

		$graylog_config = '/etc/graylog/server/server.conf'
#		$global_attributes = '/opt/graylog/embedded/cookbooks/graylog/attributes/default.rb'

		package {'graylog-server':
			ensure	=> present,

		}

		service {'graylog-server':
			ensure	=> running,
			require	=> [Package['graylog-server'],File[$graylog_config]]
		}

#		file { $global_attributes:
#			ensure	=> present,
#			owner	=> "root",
#			group	=> "root",
#			content	=> template("elasticgraylog/attributes-default.rb.erb"),
#			notify	=> Exec['/usr/bin/graylog-ctl reconfigure'],
#		}
	
		file { $graylog_config:
			ensure	=> present,
			owner	=> "graylog",
			group	=> "graylog",
			content	=> template("elasticgraylog/graylog.server.conf.erb"),
			notify	=> Service['graylog-server'],
			require	=> Package['graylog-server']
		}
	
	} #end if manage_graylog

	if ($manage_grayweb) {

		$grayweb_config	= '/etc/graylog/web/web.conf'

		package {'graylog-web':
			ensure	=> present
		}

		service {'graylog-web':
			ensure	=> running,
			require	=> [Package['graylog-web'],File[$grayweb_config]]
		}

                file { $grayweb_config:
       	                ensure  => present,
               	        owner   => "graylog",
                      	group   => "graylog",
                        content => template("elasticgraylog/graylog.web.conf.erb"),
       	                notify  => Service['graylog-web'],
               	        require => Package['graylog-web']
                }

	} #end if manage_greyweb

}
