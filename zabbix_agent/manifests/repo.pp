class zabbix_agent::repo (
	$manage_repo    = $zabbix_agent::params::manage_repo,
	$repo_location  = $zabbix_agent::params::repo_location,
	$zabbix_version = $zabbix_agent::params::zabbix_version,) 
	inherits zabbix_agent::params {

		if ($manage_repo) {
			$majorrelease = '6'
			$reponame     = $majorrelease
			$operatingsystem = downcase($::operatingsystem)

		apt::source { 'zabbix':
			location => "http://repo.zabbix.com/zabbix/${zabbix_version}/${operatingsystem}/",
			repos    => 'main',
			release  => $releasename,
			key      => {
				'id'     => 'FBABD5FB20255ECAB22EE194D13D58E479EA5ED4',
				'source' => 'http://repo.zabbix.com/zabbix-official-repo.key',
			}
		}
  		} # end if ($manage_repo)
}
