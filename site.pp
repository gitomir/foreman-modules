node default {

}

node "aws-frontend-0.aws.axsmarine.com", "aws-frontend-1.aws.axsmarine.com", "aws-frontend-2.aws.axsmarine.com", "aws-frontend-3.aws.axsmarine.com" {
        #APACHE2

        class {"apache": 
                service_ensure  => running,
                user            => "axsmarine",
                group           => "axsmarine",
                manage_group    => false,
                manage_user     => false,
                log_level       => "info",
                docroot         => "/data/www",
                default_vhost   => false,
                serveradmin     => "sysadmin@axsmarine.com",
                server_tokens   => "Prod",
                server_signature=> "Off",
                mpm_module      => false,
                keepalive       => "On",
                keepalive_timeout => "15",
                max_keepalive_requests => "100",
                default_mods    => ["access_compat","actions","alias","auth_basic","authn_core","authn_file","authz_user","authz_groupfile","autoindex","cgi","deflate","dir","env","expires","filter","mime","negotiation","reqtimeout","setenvif", "ssl", "status"],
        }

        apache::listen { '443': }

        class {"apache::mod::prefork": 
                        startservers    => 40, 
                        minspareservers => 30,
                        maxspareservers => 60,
                        serverlimit     => 2048,
                        maxclients      => 1024
        }

        class { 'apache::mod::status':
                        allow_from      => ['127.0.0.1','::1'],
                        extended_status => 'On',
                        status_path     => '/server-status',
        }

        #SSL CRT
        file {"/etc/apache2/ssl":
                ensure  => "directory",
                owner   => "root",
                group   => "root",
        }


        file {"/etc/apache2/ssl/STAR_axsmarine_com.crt":
                mode => 644,
                owner => root,
                group => root,
                source => "puppet:///modules/apache/STAR_axsmarine_com.crt",
                ensure => present,
        }


        file {"/etc/apache2/ssl/STAR_axsmarine_com.key":
                mode    => 644,
                owner   => root,
                group   => root,
                source  => "puppet:///modules/apache/STAR_axsmarine_com.key",
                ensure  => present,
                require => File["/etc/apache2/ssl"]
        }

        file {"/etc/apache2/ssl/axsmarine.ca-bundle":
                mode    => 644,
                owner   => root,
                group   => root,
                source  => "puppet:///modules/apache/axsmarine.ca-bundle",
                ensure  => present,
                require => File["/etc/apache2/ssl"]
        }


        # VHOSTS
        # DEFAULT FRONT-END DECLARATION
        apache::vhost { "aws-frontend-3.aws.axsmarine.com":
                priority                => "00",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
		manage_docroot		=> false,
                vhost_name              => "aws-frontend-3.aws.axsmarine.com",
                aliases                 => [{
                        alias           => "/tanker",
                        #path           => "/data/www2"
                        path            => "/data/axstanker"},{
                        alias           => "/v2",
                        path            => "/data/www2/v2"},{
                        alias           => "/gas",
                        path            => "/data/www2/gas"},{
                        alias           => "/axsdry3",
                        path            => "/data/axsdry3"},{
                        alias           => "/offshore",
                        path            => "/data/www/SNP"},{
                        alias           => "/ypi",
                        path            => "/data/ypi"},{
                        alias           => "/calculator",
                        path            => "/data/www2/calculator"}],
                rewrites                => [{
                        comment         => "Protect RR (To avoid fake domains linked to this server)",
                        rewrite_cond    => ["%{REQUEST_URI} !^/WWW/webservices/soap/reuters/production/server_staging.php.*$",
                                        "%{REQUEST_URI} !^/DistanceWebService/DistanceCalculator.php.*$",
                                        "%{REQUEST_URI} !^/colt/tests_base_colt.php$",
                                        "%{REQUEST_URI} !^/colt/lb_status.html$",
                                        "%{REMOTE_ADDR} !^localhost$",
                                        "%{REMOTE_ADDR} !^127.0.0.1$",
                                        "%{SERVER_NAME} !^62.23.130.7$"],
                        rewrite_rule    => "^(.*)$ http://www.axsmarine.com/$1 [L,R=301]"}],
                additional_includes     => ["php52.conf"],
                custom_fragment         => '<Location /server-status>
                                                SetHandler server-status
                                                Require ip 127.0.0.1 ::1
                                            </Location>'
        }

        # SYSADMIN INTERNALS prio 01

        apache::vhost { "phpMemcachedAdmin.axs-offices.com":
                priority                => "01",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/phpMemcachedAdmin.axs-offices.com",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "phpMemcachedAdmin.axs-offices.com",
                directories             => [{
                        path            => "/data/phpMemcachedAdmin.axs-offices.com",
                        allow_override  => "all",
                        auth_name       => "Password Protected Area",
                        auth_type       => "Basic",
                        auth_user_file  => "/data/phpMemcachedAdmin.axs-offices.com/.htpasswd",
                        auth_require    => "host 213.169.56.130"}],
                additional_includes     => ["php52.conf"]
        }

        # AXSMARINE CORP SITE & INTERNAL SITES prio 10

        apache::vhost { "axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "axsmarine.com",
                serveraliases           => ["www.axsmarine.com", "www1.axsmarine.com", "www2.axsmarine.com", "www3.axsmarine.com", "old.axsmarine.com"],
########################
# !!! WARNING !!!
#
# THIS SSLProxyEngine is needed like this because hte https proxy pass, BUT if the mod ssl is not loaded this results in a syntax error.
# but because of the HA ssl stripping we can not hit an https vhost so it is in custom_fragment not with  ssl_proxyengine  => true like in puppet forge
#
########################
                custom_fragment         => "SSLProxyEngine On",
#               proxy_pass              => [
#                       { "path" => "/public4", "url" => "https://public.axsmarine.com/public4", "reverse_urls" => "https://public.axsmarine.com/public4" }],
                rewrites                => [{
                        comment         => "Liner2 RR",
                        rewrite_rule    => "^/liner2/(.*)$ http://www.alphaliner.com/liner2/$1 [R=301,L]"},{
                        comment         => "TODO Unknown ask devs",
                        rewrite_cond    => ["%{REQUEST_FILENAME} !-f","%{REQUEST_FILENAME} !-d","%{REQUEST_FILENAME} !-l"],
                        rewrite_rules   => "^(.*)$ index.php?url=$1 [L,QSA]"}],
                directories             => [{
                        path            => "/",
                        allow_override  => "none"},{
                        path            => "/data/www/public4",
                        allow_override  => "none",
                        custom_fragment => "RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-l
    RewriteRule ^(.*)$ index.php?url=\$1 [L,QSA]"},{
#                        custom_fragment => "Php_value auto_prepend_file /data/www/axsmarine.com_prepend.php"},{
                        path            => "/AxsInteractions/axsdry3/",
                        auth_name       => "Password Protected Area",
                        auth_type       => "Basic",
                        auth_user_file  => "/data/include/axsdry3_htpwd/.htpwd",
                        custom_fragment => "
                                        <LIMIT GET POST>
                                                Require valid-user
                                        </LIMIT>"},{
                        path            => "/AxsInteractions/server/",
                        auth_require    => "all denied",
                        options         => ["-Indexes"]},{
                        path            => "/WWW/adminmenu/",
                        auth_name       => "Password Protected Area",
                        auth_type       => "Basic",
                        auth_user_file  => "/data/www/WWW/adminmenu/.htpasswd",
                        custom_fragment => "
                                        <LIMIT GET POST>
                                                Require valid-user
                                        </LIMIT>"},{
                        path            => "/WWW/administration/",
                        auth_name       => "Password Protected Area",
                        auth_type       => "Basic",
                        auth_user_file  => "/data/www/WWW/administration/.htpasswd",
                        custom_fragment => "
                                        <LIMIT GET POST>
                                                Require valid-user
                                        </LIMIT>"},{
                        path            => "/WWW/administration/adminvessel.old/",
                        auth_name       => "Password Protected Area",
                        auth_type       => "Basic",
                        auth_user_file  => "/data/www/WWW/administration/adminvessel/.htpasswd",
                        custom_fragment => "
                                        <LIMIT GET POST>
                                                Require valid-user
                                        </LIMIT>"},{
                        path            => "/WWW/administration/adminuser/",
                        auth_name       => "Password Protected Area",
                        auth_type       => "Basic",
                        auth_user_file  => "/data/www/WWW/administration/adminuser/.htpasswd",
                        custom_fragment => "
                                        <LIMIT GET POST>
                                                Require valid-user
                                        </LIMIT>"},{
                        path            => "/WWW/prototype/ext/Axsgrid/",
                        auth_name       => "Password Protected Area",
                        auth_type       => "Basic",
                        auth_user_file  => "/data/www/WWW/prototype/ext/Axsgrid/.htpasswd",
                        custom_fragment => "
                                        <LIMIT GET POST>
                                                Require valid-user
                                        </LIMIT>"},{
                        path            => "/SNP/migration2/",
                        auth_name       => "Password Protected Area",
                        auth_type       => "Basic",
                        auth_user_file  => "/data/www/SNP/migration2/.htpasswd",
                        custom_fragment => "
                                        <LIMIT GET POST>
                                                Require valid-user
                                        </LIMIT>"},{
                        path            => "/data/www/public4",
                        allow_override  => "none"},{
                        path            => ".(flv|ico|pdf|avi|mov|ppt|doc|mp3|wmv|wav)$",
                        provider        => "filesmatch",
                        custom_fragment => "ExpiresDefault A29030400"},{
                        path            => ".(jpg|jpeg|png|gif|swf)$",
                        provider        => "filesmatch",
                        custom_fragment => "ExpiresDefault A29030400"},{
                        path            => ".(txt|xml|js|css)$",
                        provider        => "filesmatch",
                        custom_fragment => "ExpiresDefault A10800"},{
                        path            => "/AxsInteractions/server/modules/",
                        auth_require    => "all denied"},{
                        path            => "/AxsInteractions/server/modules/user/",
                        auth_require    => "all denied"},{
                        path            => "/AxsInteractions/server/modules/droplist/",
                        auth_require    => "all denied"},{
                        path            => "/AxsInteractions/server/modules/prof/",
                        auth_require    => "all denied"},{
                        path            => "/AxsInteractions/server/modules/interactions/",
                        auth_require    => "all denied"},{
                        path            => "/AxsInteractions/server/framework/",
                        auth_require    => "all denied"},{
                        path            => "/AxsInteractions/server/include/",
                        auth_require    => "all denied"},{
                        path            => "/AxsInteractions/server/include/config/",
                        auth_require    => "all denied"},{
                        path            => "/WWW/help/addressbook/inc/",
                        auth_require    => "all denied"},{
                        path            => "/WWW/help/addressbook/inc/lang/",
                        auth_require    => "all denied"},{
                        path            => "/WWW/help/addressbook/bin/",
                        auth_require    => "all denied"},{
                        path            => "/WWW/help/addressbook/lib/_fla/",
                        auth_require    => "all denied"},{
                        path            => "/WWW/help/addressbook/conf/",
                        auth_require    => "all denied"},{
                        path            => "/WWW/help/addressbook/data/",
                        auth_require    => "all denied"},{
                        path            => "/WWW/dokuwiki/inc/",
                        auth_require    => "all denied"},{
                        path            => "/WWW/dokuwiki/inc/lang",
                        auth_require    => "all denied"},{
                        path            => "/WWW/dokuwiki/bin",
                        auth_require    => "all denied"},{
                        path            => "/WWW/dokuwiki/conf/",
                        auth_require    => "all denied"},{
                        path            => "/WWW/dokuwiki/data/",
                        auth_require    => "all denied"}
                ],
                additional_includes     => ["php52.conf","dry3-shutdown-ruleset-apache24.conf"]
        }

        file {"/etc/apache2/dry3-shutdown-ruleset-apache24.conf":
                mode    => 644,
                owner   => root,
                group   => root,
                source  => "puppet:///modules/apache/dry3-shutdown-ruleset-apache24.conf",
                ensure  => present,
        }

        apache::vhost { "beta.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/beta",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "beta.axsmarine.com",
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "mito.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/mito",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "mito.axsmarine.com",
                additional_includes     => ["php53.conf"]
        }


        apache::vhost { "webservices.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/WWW/webservices/soap",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "webservices.axsmarine.com",
# DEPRECED
#               proxy_pass              => [
#                       { "path" => "/reuters/phase2/ais", "url" => "http://axs-ais-vip.heb.fr.colt.net/WWW/webservices/soap/reuters/phase2/ais", "reverse_urls" => "http://axs-ais-vip.heb.fr.colt.net/WWW/webservices/soap/reuters/phase2/ais", "timeout" => "3600" }],
                directories             => [{
                        path            => "/data/www/WWW/webservices/soap/",
                        options         => ["-Indexes +FollowSymLinks +MultiViews"]},
                ],
                headers                 => ["unset Transfer-Encoding"],
                setenv                  => ["no-gzip 1","force-response-1.0 1","downgrade-1.0 1"],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "webservicesv4.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/WWW/webservicesv4/soap",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "webservices.axsmarine.com",
# DEPRECED
#               proxy_pass              => [
#                       { "path" => "/reuters/phase2/ais", "url" => "http://axs-ais-vip.heb.fr.colt.net/WWW/webservices/soap/reuters/phase2/ais", "reverse_urls" => "http://axs-ais-vip.heb.fr.colt.net/WWW/webservices/soap/reuters/phase2/ais", "timeout" => "3600" }],
                headers                 => ["unset Transfer-Encoding"],
                setenv                  => ["no-gzip 1","force-response-1.0 1","downgrade-1.0 1"],
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "help.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/WWW/help",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "help.axsmarine.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "static.axsmarine.com_non-ssl":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/static",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "static.axsmarine.com",
                servername              => "static.axsmarine.com",
                directories             => [{
#                       "path"          => "\.(ttf|otf|eot|woff)$",
                        "path"          => "\.*",
                        "provider"      => "filesmatch",
                        "headers"       => "set Access-Control-Allow-Origin \"*\"" }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "static.axsmarine.com_ssl":
                priority                => "10",
                port                    => "443",
                ssl                     => true,
                ssl_cert                => "/etc/apache2/ssl/STAR_axsmarine_com.crt",
                ssl_key                 => "/etc/apache2/ssl/STAR_axsmarine_com.key",
                ssl_chain               => "/etc/apache2/ssl/axsmarine.ca-bundle",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/static",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "static.axsmarine.com",
                servername              => "static.axsmarine.com",
                directories             => [{
#                       "path"          => "\.(ttf|otf|eot|woff)$",
                        "path"          => "\.*",
                        "provider"      => "filesmatch",
                        "headers"       => "set Access-Control-Allow-Origin \"*\"" }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "staticv5.axsmarine.com_non-ssl":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/staticv5",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "staticv5.axsmarine.com",
                servername              => "staticv5.axsmarine.com",
                directories             => [{
#                       "path"          => "\.(ttf|otf|eot|woff)$",
                        "path"          => "\.*",
                        "provider"      => "filesmatch",
                        "headers"       => "set Access-Control-Allow-Origin \"*\"" }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "staticv5.axsmarine.com_ssl":
                priority                => "10",
                port                    => "443",
                ssl                     => true,
                ssl_cert                => "/etc/apache2/ssl/STAR_axsmarine_com.crt",
                ssl_key                 => "/etc/apache2/ssl/STAR_axsmarine_com.key",
                ssl_chain               => "/etc/apache2/ssl/axsmarine.ca-bundle",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/staticv5",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "staticv5.axsmarine.com",
                servername              => "staticv5.axsmarine.com",
                directories             => [{
#                       "path"          => "\.(ttf|otf|eot|woff)$",
                        "path"          => "\.*",
                        "provider"      => "filesmatch",
                        "headers"       => "set Access-Control-Allow-Origin \"*\"" }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "mops.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/WWW/SOF",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "mops.axsmarine.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "mobile.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/mobile",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "mobile.axsmarine.com",
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "crm.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/crm.axsmarine.com",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "axsdry.axsmarine.com",
                #headers                        => ["append Vary User-Agent env=!dont-vary"],
                #setenvif               => ["Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary"],
                directories             => [{
                        path            => "\.(html|htm|php)$",
                        provider        => "filesmatch",
                        headers         => ["set X-UA-Compatible \"IE=8\"","set X-UA-Compatible \"IE=EmulateIE8\""]},{
                        path            => "/",
                        provider        => "location",
                        custom_fragment => "SetOutputFilter DEFLATE
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    Header append Vary User-Agent env=!dont-vary"}],
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "admin1.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/admin.axsmarine.com",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "admin1.axsmarine.com",
                directories             => [{
                        path            => "/data/admin.axsmarine.com",
                        allow_override  => "all"},{
                        path            => "\.(html|htm|php)$",
                        provider        => "filesmatch",
                        headers         => ["set X-UA-Compatible \"IE=8\"","set X-UA-Compatible \"IE=EmulateIE8\""]},{
                        path            => "/",
                        provider        => "location",
                        custom_fragment => "SetOutputFilter DEFLATE
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    Header append Vary User-Agent env=!dont-vary"}],
                additional_includes     => ["php53.conf"]
        }

        # KIBANA & ES prio 15

        apache::vhost { "kibana.axsmarine.com":
                priority                => "15",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/kibana.axsmarine.com",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "kibana.axsmarine.com",
                proxy_pass              => [
                        { "path" => "/es", "url" => "http://axsbs-ws013:9200", "reverse_urls" => "http://axsbs-ws013:9200", "retry" => "0", "timeout" => "60" }],
                directories             => [{
                        path            => "/data/www/kibana.axsmarine.com",
                        allow_override  => "all",
                        auth_name       => "Password Protected Area",
                        auth_type       => "Basic",
                        auth_user_file  => "/data/www/kibana.axsmarine.com/.htpasswd"}],

                additional_includes     => ["php53.conf"]

        }

        # TANKER prio 20

        apache::vhost { "axstanker.axsmarine.com":
                priority                => "20",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
#TODO duplicated vhost declaration, merging
#               docroot                 => "/data/www2",
                docroot                 => "/data/axstanker",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "axstanker.axsmarine.com",
                serveraliases           => ["www1.axstanker.com","www2.axstanker.com","www3.axstanker.com","www.axstanker.com"],
                directories             => [{
                        path            => "\.(html|htm|php)$",
                        provider        => "filesmatch",
                        headers         => ["set X-UA-Compatible \"IE=8\"","set X-UA-Compatible \"IE=EmulateIE8\""]},{
                        path            => "\.(ini)$",
                        provider        => "filesmatch",
                        auth_require    => "all denied"}],
                additional_includes     => ["php52.conf"],
                custom_fragment         => '
#Overwrite the default encoding
AddDefaultCharset UTF-8'
        }

        apache::vhost { "axstankerv3.axsmarine.com":
                priority                => "20",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/axstankerv3",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "axstankerv3.axsmarine.com",
#TODO see no_mod_php5.txt
#               directories             => [{ 
#                       path            => "/data/axstankerv3",
#                       php_admin_values        => [ "include_path ..:/usr/local/lib/php." ]
#               }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "axstankerv4.axsmarine.com":
                priority                => "20",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/axstankerv4.axsmarine.com",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "axstankerv4.axsmarine.com",
                additional_includes     => ["php53.conf"],

        }

        apache::vhost { "soap.axstanker.com":
                priority                => "20",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/soap",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "soap.axstanker.com",
                additional_includes     => ["php52.conf"]
        }

        # LINER prio 30

        apache::vhost { "www.axsliner.com":
                priority                => "30",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www3",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "www.axsliner.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "www.alphaliner.com":
                priority                => "30",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/axs-alphaliner",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "www.alphaliner.com",
                serveraliases           => ["www.axs-alphaliner.com","alphaliner.com"],
                rewrites                => [{
                        comment         => "Global RR",
                        rewrite_cond    => "%{HTTP_HOST} !^www.alphaliner.com$",
                        rewrite_rule    => "^(.*)$ http://www.alphaliner.com$1 [R=301,L]"}],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "import.alphaliner.com":
                priority                => "30",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/liner2/import",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "import.alphaliner.com",
                serveraliases           => ["import.axs-alphaliner.com"],
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "alphalinerv4.axsmarine.com":
                priority                => "40",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/alphalinerv4.axsmarine.com",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "alphalinerv4.axsmarine.com",
                #headers                        => ["append Vary User-Agent env=!dont-vary"],
                #setenvif               => ["Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary"],
                directories             => [{
                        path            => "\.(html|htm|php)$",
                        provider        => "filesmatch",
                        headers         => ["set X-UA-Compatible \"IE=8\"","set X-UA-Compatible \"IE=EmulateIE8\""]},{
                        path            => "/",
                        provider        => "location",
                        custom_fragment => "SetOutputFilter DEFLATE
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    Header append Vary User-Agent env=!dont-vary"}],
                additional_includes     => ["php53.conf"]
        }

        # DRY prio 40

        apache::vhost { "axsdry.axsmarine.com_non-ssl":
                priority                => "40",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/axsdry.axsmarine.com",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                servername              => "axsdry.axsmarine.com",
                vhost_name              => "axsdry.axsmarine.com",
                #headers                => ["append Vary User-Agent env=!dont-vary"],
                #setenvif               => ["Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary"],
                directories             => [{
                        path            => "\.(html|htm|php)$",
                        provider        => "filesmatch",
                        headers         => ["set X-UA-Compatible \"IE=8\"","set X-UA-Compatible \"IE=EmulateIE8\""]},{
                        path            => "/",
                        provider        => "location",
                        custom_fragment => "SetOutputFilter DEFLATE
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    Header append Vary User-Agent env=!dont-vary"}],
                additional_includes     => ["php53.conf"],
                custom_fragment => '
#Cache is good
<IfModule mod_expires.c>
        <FilesMatch "\.(css|js)$">
          ExpiresActive On
          ExpiresDefault "access plus 1 week"
          Header append Cache-Control "public"
        </FilesMatch>
</IfModule>

# Removes ETag to fix issue on Apache 2.4 and 304 Not Modified header
<IfModule mod_headers.c>
        Header unset ETag
</IfModule>
FileETag None'

        }

         apache::vhost { "axsdry.axsmarine.com_ssl":
                priority                => "41",
                port                    => "443",
                ssl                     => true,
                ssl_cert                => "/etc/apache2/ssl/STAR_axsmarine_com.crt",
                ssl_key                 => "/etc/apache2/ssl/STAR_axsmarine_com.key",
                ssl_chain               => "/etc/apache2/ssl/axsmarine.ca-bundle",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/axsdry.axsmarine.com",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                servername              => "axsdry.axsmarine.com",
                vhost_name              => "axsdry.axsmarine.com",
                #headers                => ["append Vary User-Agent env=!dont-vary"],
                #setenvif               => ["Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary"],
                directories             => [{
                        path            => "\.(html|htm|php)$",
                        provider        => "filesmatch",
                        headers         => ["set X-UA-Compatible \"IE=8\"","set X-UA-Compatible \"IE=EmulateIE8\"","set Strict-Transport-Security \"max-age=31536000\""]},{
                        path            => "/",
                        provider        => "location",
                        custom_fragment => "SetOutputFilter DEFLATE
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    Header append Vary User-Agent env=!dont-vary"}],
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "axsdry2.axsmarine.com":
                priority                => "40",
                port                    => "80",
                docroot                 => "/data/axsdry.axsmarine.com2",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "axsdry2.axsmarine.com",
                #headers                        => ["append Vary User-Agent env=!dont-vary"],
                #setenvif               => ["Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary"],
                directories             => [{
                        path            => "\.(html|htm|php)$",
                        provider        => "filesmatch",
                        headers         => ["set X-UA-Compatible \"IE=8\"","set X-UA-Compatible \"IE=EmulateIE8\""]},{
                        path            => "/",
                        provider        => "location",
                        custom_fragment => "SetOutputFilter DEFLATE
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    Header append Vary User-Agent env=!dont-vary"}],
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "oc-vetting.axsmarine.com":
                priority                => "40",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/oldendorff/VettingTool",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "oc-vetting.axsmarine.com",
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "eotvbunker.axsmarine.com":
                priority                => "40",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/oldendorff/eotvbunker",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "eotvbunker.axsmarine.com",
                serveraliases           => ["www.eotvbunker.axsmarine.com"],
                additional_includes     => ["php53.conf"]
        }

        # TOPGALLANT prio 50

        apache::vhost { "topgallant.axsmarine.com":
                priority                => "50",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/topgallant",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "topgallant.axsmarine.com",
                directories             => [{
                        path            => "/",
                        allow_override  => "none"},{
                        path            => "/data/topgallant/server/",
                        options         => ["-Indexes"]},{
                        path            => "/data/www/topgallant/rsync",
                        allow_override  => "all"},{
                        path            => "/data/topgallant/server/modules/user/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/api/search/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/api/simpleselect/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/combo/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/broker/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/brokers/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/charter/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/charter2/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/files/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/droplist/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/select/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/tree/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/datagrid/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/prof/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/yacht/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/framework/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/include/",
                        auth_require    => "all denied"}],
                additional_includes     => ["php52.conf"]
        }


        # YPI prio 60

        apache::vhost { "ypigroup.webstore.fr":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "ypigroup.webstore.fr",
                override                => "all",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "manager.ypigroup.webstore.fr":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/manager/",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "manager.ypigroup.webstore.fr",
                serveraliases           => ["manager.ypigroup.com"],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "www.ypigroup.com":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "www.ypigroup.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "js.ypigroup.com":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/js",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "js.ypigroup.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "media.ypigroup.com":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/media",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "media.ypigroup.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "css.ypigroup.com":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/css",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "css.ypigroup.com",
                override                => "all",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "ypicrew.com":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/ypicrew",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "ypicrew.com",
                serveraliases           => ["www.ypicrew.com", "crewrecruitment.com", "www.crewrecruitment.com"],
                directories             => [{
                        path            => "/data/ypi_website/html/ypicrew",
                        allow_override  => "all"}],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "yacht-glaze.com":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "yacht-glaze.com",
                serveraliases           => ["www.yacht-glaze.com"],
                proxy_pass              => [
                        { "path" => "/css", "url" => "http://www.ypigroup.com/css", "reverse_urls" => "http://www.ypigroup.com/css" },
                        { "path" => "/open", "url" => "http://www.ypigroup.com/open", "reverse_urls" => "http://www.ypigroup.com/open" },
                        { "path" => "/js", "url" => "http://www.ypigroup.com/js", "reverse_urls" => "http://www.ypigroup.com/js" },
                        { "path" => "/", "url" => "http://www.ypigroup.com/open/glaze", "reverse_urls" => "http://www.ypigroup.com/open/glaze" }],
#               rewrites                => [{ rewrite_rule => [".* http://www.ypigroup.com/open/glaze"] }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "yacht-athos.com":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "yacht-athos.com",
                serveraliases           => ["www.yacht-athos.com"],
                proxy_pass              => [
                        { "path" => "/css", "url" => "http://www.ypigroup.com/css", "reverse_urls" => "http://www.ypigroup.com/css" },
                        { "path" => "/open", "url" => "http://www.ypigroup.com/open", "reverse_urls" => "http://www.ypigroup.com/open" },
                        { "path" => "/js", "url" => "http://www.ypigroup.com/js", "reverse_urls" => "http://www.ypigroup.com/js" },
                        { "path" => "/", "url" => "http://www.ypigroup.com/open/athos", "reverse_urls" => "http://www.ypigroup.com/open/athos" }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "yacht-marina-wonder.com":
                priority                => "60",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "yacht-marina-wonder.com",
                serveraliases           => ["www.yacht-marina-wonder.com"],
                proxy_pass              => [
                        { "path" => "/css", "url" => "http://www.ypigroup.com/css", "reverse_urls" => "http://www.ypigroup.com/css" },
                        { "path" => "/open", "url" => "http://www.ypigroup.com/open", "reverse_urls" => "http://www.ypigroup.com/open" },
                        { "path" => "/js", "url" => "http://www.ypigroup.com/js", "reverse_urls" => "http://www.ypigroup.com/js" },
                        { "path" => "/", "url" => "http://www.ypigroup.com/open/marina-wonder", "reverse_urls" => "http://www.ypigroup.com/open/marina-wonder" }],
                additional_includes     => ["php52.conf"]
        }

        # TERMINALS prio 70

        apache::vhost { "axsterminals.axsmarine.com":
                priority                => "70",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/axsterminals",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "axsterminals.axsmarine.com",
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "terminalsv4.axsmarine.com":
                priority                => "70",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/terminalsv4",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "terminalsv4.axsmarine.com",
                additional_includes     => ["php53.conf"]
        }

        # OFFSHORE & SNP prio 80

        apache::vhost { "offshore.axsmarine.com":
                priority                => "80",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/SNP",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "offshore.axsmarine.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "offshorev4.axsmarine.com":
                priority                => "80",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/offshorev4",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "offshorev4.axsmarine.com",
                additional_includes     => ["php53.conf"]
        }

        apache::vhost { "snp.axsmarine.com":
                priority                => "80",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www/SNP",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "snp.axsmarine.com",
                additional_includes     => ["php52.conf"]
        }

        # OTHER PROJECTS prio 85

        apache::vhost { "datamanager.axsmarine.com":
                priority                => "85",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/datamanager",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "datamanager.axsmarine.com",
                directories             => [{
                        path            => "/data/datamanager",
                        allow_override  => "all"}],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "alphabulk.com":
                priority                => "85",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/alphabulk.com",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "alphabulk.com",
                serveraliases           => ["www.alphabulk.com"],
                additional_includes     => ["php52.conf"]
        }

        # AIS prio 90

        apache::vhost { "axsais.axsmarine.com":
                priority                => "90",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/axsais",
                docroot_owner		=> "axsmarine",
                docroot_group		=> "axsmarine",
                vhost_name              => "axsais.axsmarine.com",
                directories             => [{
                        path            => "/data/axsais/equasis",
                        allow_override  => "AuthConfig"}],
                additional_includes     => ["php52.conf"]
        }

} #end node frontends


#
#
#
# NODE small-front-1
#
#
#

node "aws-small-front-1.aws.axsmarine.com" {

	#MySQL

        package { 'mysql-server-5.5':
                ensure => "installed",  
        }

        file {"/data/www":
                ensure  => "directory",
                owner   => "root",
                group   => "axsmarine",
                mode    => 775,
        }


	#PHP

        package {'php5':
                ensure  => installed
        }

        package {'php5-fpm':
                ensure  => installed,
                require => Package['php5']
        }

        service { 'php5-fpm':
                ensure => running,
                require => Package['php5-fpm'],
        }

        package {'php5-mysql':
                ensure  => installed,
                require => Package['php5']
        }

        package {'php5-common':
                ensure  => installed
        }

        package {'php5-json':
                ensure  => installed,
                require => Package['php5']
        }

        package {'php5-mcrypt':
                ensure  => installed,
                require => Package['php5']
        }
        package {'php5-readline':
                ensure  => installed,
                require => Package['php5']
        }

        file { '/etc/php5/fpm/conf.d/20-mcrypt.ini':
                ensure => 'link',
                target => '/etc/php5/mods-available/mcrypt.ini',
                require => [
                        Package['php5-mcrypt'],
                        Package['php5-fpm'],
                        ],
        notify => Service['php5-fpm'],

        }

#NODEJS

        class { 'nodejs':
                version => 'v0.10.40',
        }
        
        package { 'pm2':
               
                ensure => '0.12.7',
                provider => 'npm',
                require => Package['npm']
        }

# NPM package
        
        package { 'npm' :
                ensure => installed,
                require => Class['nodejs']
        }
# Redis Server

        package { "redis-server":
                ensure => '2:2.8.4-2',
        }

        service { 'redis-server':
                ensure => running,
                require => Package['redis-server'],
        }

#Nginx

        package { 'nginx':
                ensure => '1.4.6-1ubuntu3.4',
        }

        service { 'nginx':
                ensure => running,
                require => Package['nginx'],
        }

        file {"/etc/nginx/nginx.conf":
                content => template("nginx/conf.d/nginx_AWS_sm_front_1.erb"),
                ensure => present,
                owner   => "root",
                group   => "root",
                mode    => 640,
                require => Package['nginx'],
                notify  => Service['nginx']
        }

        file {"/etc/nginx/sites-enabled/alphashippingstore.com":
                content => template("nginx/vhost/alphashippingstore.erb"),
                ensure => present,
                owner   => "root",
                group   => "root",
                mode    => 640,
                require => Package['nginx'],
                notify  => Service['nginx']
        }

        file {"/etc/nginx/sites-enabled/axsdry.mobile.axsmarine.com":
                content => template("nginx/vhost/axsdry_mobile.erb"),
                ensure => present,
                owner   => "root",
                group   => "root",
                mode    => 640,
                require => Package['nginx'],
                notify  => Service['nginx']
        }

        file {"/etc/nginx/sites-enabled/com.axsmarine.bunkerprices.conf":
                content => template("nginx/vhost/bunkerprices.erb"),
                ensure => present,
                owner   => "root",
                group   => "root",
                mode    => 640,
                require => Package['nginx'],
                notify  => Service['nginx']
        }

        file {"/etc/init/bunkerprices.conf":
                content => template("init/bunkerprices.erb"),
                ensure => present,
                owner   => "root",
                group   => "root",
                mode    => 640,
                require => Package['nginx'],
                notify  => Service['nginx']
        }

} #end node small-front-1

#
#
#
# NODE small-front-2
#
#
#


node "aws-small-front-2.aws.axsmarine.com" {

        class {"apache": 
                service_ensure  => running,
                user            => "axsmarine",
                group           => "axsmarine",
                manage_group    => false,
                manage_user     => false,
                log_level       => "debug",
                docroot         => "/data/www",
                default_vhost   => false,
                serveradmin     => "sysadmin@axsmarine.com",
                server_tokens   => "Prod",
                server_signature=> "Off",
                mpm_module      => false,
                keepalive       => "On",
                keepalive_timeout => "15",
                max_keepalive_requests => "100",
                default_mods    => ["access_compat","actions","alias","auth_basic","authn_core","authn_file","authz_user","autoindex","cgi","deflate","dir","env","expires","filter","mime","negotiation","reqtimeout","rewrite","setenvif", "ssl", "status"],
        }


        class {"apache::mod::prefork": 
                        startservers    => 40, 
                        minspareservers => 30,
                        maxspareservers => 60,
                        serverlimit     => 2048,
                        maxclients      => 1024
        }

        class { 'apache::mod::status':
                        allow_from      => ['127.0.0.1','::1'],
                        extended_status => 'On',
                        status_path     => '/server-status',
        }

        apache::listen { '80': }

        #SSL CRT
        #apache::listen { '443': }
        #file {"/etc/apache2/ssl":
        #        ensure  => "directory",
        #        owner   => "root",
        #        group   => "root",
        #}

        #file {"/etc/apache2/ssl/STAR_axsmarine_com.crt":
        #        mode   => 644,
        #        owner  => root,
        #        group  => root,
        #        source => "puppet:///modules/apache/STAR_axsmarine_com.crt",
        #        ensure => present,
        #       require => File["/etc/apache2/ssl"]
        #}

        #file {"/etc/apache2/ssl/STAR_axsmarine_com.key":
        #        mode    => 644,
        #        owner   => root,
        #        group   => root,
        #        source  => "puppet:///modules/apache/STAR_axsmarine_com.key",
        #        ensure  => present,
        #        require => File["/etc/apache2/ssl"]
        #}

        #file {"/etc/apache2/ssl/axsmarine.ca-bundle":
        #        mode    => 644,
        #        owner   => root,
        #        group   => root,
        #        source  => "puppet:///modules/apache/axsmarine.ca-bundle",
        #        ensure  => present,
        #        require => File["/etc/apache2/ssl"]
        #}

        # VHOSTS
        # DEFAULT FRONT-END DECLARATION
        apache::vhost { "aws-small-front-2.aws.axsmarine.com":
                priority                => "00",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/www",
		manage_docroot		=> false,
                vhost_name              => "aws-small-front-2.aws.axsmarine.com",
                aliases                 => [{
                        alias           => "/topgallant",
                        path            => "/data/topgallant"}],
                additional_includes     => ["php52.conf"]
        }

        # TOPGALLANT prio 10

        apache::vhost { "topgallant.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/topgallant",
		manage_docroot		=> false,
                vhost_name              => "topgallant.axsmarine.com",
                directories             => [{
                        path            => "/",
                        allow_override  => "none"},{
                        path            => "/data/topgallant/",
                        options         => ["-Indexes"]},{
                        path            => "/data/topgallant/rsync",
                        allow_override  => "all"},{
                        path            => "/data/topgallant/server/modules/user/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/api/search/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/api/simpleselect/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/combo/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/broker/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/brokers/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/charter/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/charter2/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/files/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/droplist/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/select/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/tree/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/datagrid/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/interactions/prof/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/modules/yacht/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/framework/",
                        auth_require    => "all denied"},{
                        path            => "/data/topgallant/server/include/",
                        auth_require    => "all denied"}],
                additional_includes     => ["php52.conf"]
        }


        # YPI prio 20
        apache::vhost { "www.ypigroup.com":
                priority                => "20",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
		manage_docroot		=> false,
                vhost_name              => "www.ypigroup.com",
                serveraliases           => "ypigroup.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "ypigroup.webstore.fr":
                priority                => "21",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
		manage_docroot		=> false,
                vhost_name              => "ypigroup.webstore.fr",
                serveraliases           => "www.ypigroup.webstore.fr",
                override                => "all",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "manager.ypigroup.webstore.fr":
                priority                => "22",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/manager/",
		manage_docroot		=> false,
                vhost_name              => "manager.ypigroup.webstore.fr",
                serveraliases           => ["manager.ypigroup.com", "www.manager.ypigroup.webstore.fr", "www.manager.ypigroup.com"],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "js.ypigroup.com":
                priority                => "23",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/js",
		manage_docroot		=> false,
                vhost_name              => "js.ypigroup.com",
                serveraliases           => "www.js.ypigroup.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "media.ypigroup.com":
                priority                => "24",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/media",
		manage_docroot		=> false,
                vhost_name              => "media.ypigroup.com",
                serveraliases           => "www.media.ypigroup.com",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "css.ypigroup.com":
                priority                => "25",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/css",
		manage_docroot		=> false,
                vhost_name              => "css.ypigroup.com",
                serveraliases           => "www.css.ypigroup.com",
                override                => "all",
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "ypicrew.com":
                priority                => "26",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html/ypicrew",
		manage_docroot		=> false,
                vhost_name              => "ypicrew.com",
                serveraliases           => ["www.ypicrew.com", "crewrecruitment.com", "www.crewrecruitment.com"],
                directories             => [{
                        path            => "/data/ypi_website/html/ypicrew",
                        allow_override  => "all"}],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "yacht-glaze.com":
                priority                => "27",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
		manage_docroot		=> false,
                vhost_name              => "yacht-glaze.com",
                serveraliases           => ["www.yacht-glaze.com"],
                proxy_pass              => [
                        { "path" => "/css", "url" => "http://www.ypigroup.com/css", "reverse_urls" => "http://www.ypigroup.com/css" },
                        { "path" => "/open", "url" => "http://www.ypigroup.com/open", "reverse_urls" => "http://www.ypigroup.com/open" },
                        { "path" => "/js", "url" => "http://www.ypigroup.com/js", "reverse_urls" => "http://www.ypigroup.com/js" },
                        { "path" => "/", "url" => "http://www.ypigroup.com/open/glaze", "reverse_urls" => "http://www.ypigroup.com/open/glaze" }],
#               rewrites                => [{ rewrite_rule => [".* http://www.ypigroup.com/open/glaze"] }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "yacht-athos.com":
                priority                => "28",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
		manage_docroot		=> false,
                vhost_name              => "yacht-athos.com",
                serveraliases           => ["www.yacht-athos.com"],
                proxy_pass              => [
                        { "path" => "/css", "url" => "http://www.ypigroup.com/css", "reverse_urls" => "http://www.ypigroup.com/css" },
                        { "path" => "/open", "url" => "http://www.ypigroup.com/open", "reverse_urls" => "http://www.ypigroup.com/open" },
                        { "path" => "/js", "url" => "http://www.ypigroup.com/js", "reverse_urls" => "http://www.ypigroup.com/js" },
                        { "path" => "/", "url" => "http://www.ypigroup.com/open/athos", "reverse_urls" => "http://www.ypigroup.com/open/athos" }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "yacht-marinawonder.com":
                priority                => "29",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
		manage_docroot		=> false,
                vhost_name              => "yacht-marinawonder.com",
                serveraliases           => ["www.yacht-marinawonder.com"],
                proxy_pass              => [
                        { "path" => "/css", "url" => "http://www.ypigroup.com/css", "reverse_urls" => "http://www.ypigroup.com/css" },
                        { "path" => "/open", "url" => "http://www.ypigroup.com/open", "reverse_urls" => "http://www.ypigroup.com/open" },
                        { "path" => "/js", "url" => "http://www.ypigroup.com/js", "reverse_urls" => "http://www.ypigroup.com/js" },
                        { "path" => "/", "url" => "http://www.ypigroup.com/open/marina-wonder", "reverse_urls" => "http://www.ypigroup.com/open/marina-wonder" }],
                additional_includes     => ["php52.conf"]
        }

        apache::vhost { "archive.ypigroup.com":
                priority                => "24",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/data/ypi_website/html",
		manage_docroot		=> false,
                vhost_name              => "archive.ypigroup.com",
                serveraliases           => "www.archive.ypigroup.com",
                additional_includes     => ["php52.conf"]
        }

        package {'vsftpd':
                ensure => installed
        }
        
        service {'vsftpd':
                enable => true,
                ensure => running,
                require => Package['vsftpd']    
        }

        file {"/etc/vsftpd.conf":
                content => template("vsftpd/vsftpd_small_front-2.conf.erb"),
                ensure => present,
                notify => Service['vsftpd'],
                require => Package['vsftpd']
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
                owner   => "vsftpd",
                group   => "nogroup",
                mode    => 644,
                require => Package['vsftpd']
        }

        file {"/etc/vsftpd_user_conf/axsypi":
                content => file("vsftpd/axsypi"),
                ensure => present,
                notify => Service['vsftpd'],
                require =>File["/etc/vsftpd_user_conf"]
        }

        file {"/etc/vsftpd/ftpd.passwd":
                content => template("vsftpd/vsftpd_passwd_axs_small_front-2.conf.erb"),
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
                content => "boyan-milanov"
        }

        file {"/etc/pam.d/vsftpd":
                content => template("vsftpd/pamd_config_public.conf.erb"),
                ensure => present,
                notify => Service['vsftpd'],
                require => Package['vsftpd']
        }


} #end node small-front-2


#
#
#
# NODEs AWS-ELASTIC
#
#
#
node "aws-elastic-1.aws.axsmarine.com", "aws-elastic-2.aws.axsmarine.com", "aws-elastic-3.aws.axsmarine.com" {
        # DELETE EvERYTHING LAST AFTER 93 DAYS IN PAST TILL 100 DAYS IN PAST (Just in case we missed a day due to server missed daily cron execution because of server failure
        
        cron { "remove_3_months":
                 command         => 'for product in axsdry axsterminalsv4 axsoffshorev4 axstanker livescript-vessel-dry obi ovt axsliner livescript-vessel-tanker; do for days in {93..100}; do index=logstash-$(date -d $days\' days ago\' +%Y.%m.%d)-$product; curl -XDELETE http://localhost:9200/$index; echo $index; done;  done;',
                 user            => "root",
                 hour            => '3',
                 minute          => '0'
        }

        # /data/elasticsearch folder
        file {"/data/elasticsearch":
                ensure  => "directory",
                owner   => elasticsearch,
                group   => elasticsearch
        }

        # NPM package

        package { 'npm' :
                ensure => latest
        }

        # Nodejs requried for Elasticdump

        package { 'nodejs' :
                ensure => latest
        }

        # Elasticdump needed for dumping indexes older than 3 months because of their deletion

        exec { 'Install Elasticdump' :
                command => "npm install elasticdump -g",
                path => "/usr/bin",
                creates => "/usr/local/bin/elasticdump",
                require => [Package['npm'], Package['nodejs']]
        }

        #Symlink to nodejs required for elasticdump
        exec { 'Symlink to nodejs' :
                command => "ln -s /usr/bin/nodejs /usr/bin/node",
                path => "/usr/bin:/bin",
                creates => "/usr/bin/node"
        }

        # Installing Elastic search. Requires AXSMarine repo plus installed Oracle Java 7

        package { "elasticsearch":
                ensure => latest,
        }

        # Elastic Search Service to restart Definition

        service { "elasticsearch" :
                ensure => "running",
                enable => "true",
                require => Package["elasticsearch"]
        }

        # Logstash Service to restart Definition

        service { "logstash" :
                ensure => "running",
                enable => "true",
                require => Package["logstash"]
        }

        # Logstash web upstart disabled (We use Kibana for web services and do not need logstash web)

        file {"/etc/init/logstash-web.conf":
                source => "puppet:///modules/elk/logstash-web.conf",
                ensure => present,
                notify => Service["logstash"],
                require => Package["logstash"]
        }

        # Configuring  Elastic Search with tempalte configuration file. Require Elastic Search Installed

        file {"/etc/elasticsearch/elasticsearch.yml":
                content => template("elk/aws-elasticsearch.erb"),
                ensure => present,
                notify => Service["elasticsearch"], 
                require => Package["elasticsearch"]
        }

        # Installing custom upstart script to set the heap memory 

        file {"/etc/init.d/elasticsearch":
                source => "puppet:///modules/elk/elasticsearch",
                ensure => present,
                notify => Service["elasticsearch"],
                require => Package["elasticsearch"]
        }

        # Installing JDBC Plugin for elastic search. Required Elastic Search Installed

        exec { "jdbc plugin for elastic search":
                command => "/usr/share/elasticsearch/bin/plugin --install jdbc --url http://xbib.org/repository/org/xbib/elasticsearch/plugin/elasticsearch-river-jdbc/1.5.0.5/elasticsearch-river-jdbc-1.5.0.5-plugin.zip",
                creates => "/usr/share/elasticsearch/plugins/jdbc",
                require => Package["elasticsearch"]
        }

        # Installing KOPF plugin . Required Elastic Search Installed

        exec {"Install KOPF plugin":
               command => "/usr/share/elasticsearch/bin/plugin -install lmenezes/elasticsearch-kopf",
               creates => "/usr/share/elasticsearch/plugins/kopf",
               require => Package["elasticsearch"]
        }

        # Installing Mysql Connector for JBDC Plugin . Require JBDC Plugin installed

        file {"/usr/share/elasticsearch/plugins/jdbc/mysql-connector-java-5.1.32-bin.jar":
                source => "puppet:///modules/elk/mysql-connector-java-5.1.32-bin.jar",
                ensure => present,
                require => Exec["jdbc plugin for elastic search"]
        }

        # Installing Logstash. Requires Elastic Search Installed and AXSMarine repo added

        package { "logstash":
                ensure => latest,
        }

        # Configuring Logstash . Requires Logstash Installed

        file {"/etc/logstash/conf.d/logconfig":
                #source => "puppet:///modules/elk/logconfig",
                content => template("elk/aws-logconfig.erb"),
                ensure => present,
                require => Package["logstash"],
                notify => Service["logstash"]
        }

        # Configuring logstash-elasticsearch template . Requires Logstash & Elastic search installed

        file {"/etc/logstash/elasticsearch-template.json":
                source => "puppet:///modules/elk/elasticsearch-template.json",
                ensure => present,
                require => [Package["logstash"],Package['elasticsearch']],
                notify => Service["logstash"]
        }

#       # Installing Kibana 3 . Downloading archive 
#
#       file {"/usr/src/kibana-3.1.1.tar.gz":
#               source => "puppet:///modules/elk/kibana-3.1.1.tar.gz",
#               ensure => present,
#       }
#
#       # Unpack Kibana Archive Required File Archive of Kibana to be present
#
#       exec {"untar kibana":
#             command => "mkdir -p /var/www/ && cd /var/www/ && tar -xvf /usr/src/kibana-3.1.1.tar.gz",
#             path => "/usr/local/bin/:/bin/",
#             creates => "/var/www/kibana-3.1.1",
#             require => File["/usr/src/kibana-3.1.1.tar.gz"]
#       }
#

        #       # Installing Kibana 4 . Downloading archive 

        file {"/usr/src/kibana-4.1.1-linux-x64.tar.gz":
                source => "puppet:///modules/elk/kibana-4.1.1-linux-x64.tar.gz",
                ensure => present,
        }

        # Kibana Service

        file {"/etc/init.d/kibana4":
                source => "puppet:///modules/elk/kibana4",
		mode	=> 0755,
                ensure => present,
        }

        # Unpack Kibana Archive Required File Archive of Kibana to be present
        exec {"untar kibana":
              command => "mkdir -p /opt/ && cd /opt/ && tar -xvf /usr/src/kibana-4.1.1-linux-x64.tar.gz && mv kibana-4.1.1-linux-x64 kibana4",
              path => "/usr/local/bin/:/bin/",
              creates => "/opt/kibana4/",
              require => File["/usr/src/kibana-4.1.1-linux-x64.tar.gz"]
        }


#        exec {"Enable Kibana Service":
#                command => "chmod +x /etc/init.d/kibana4", # update-rc.d kibana4 defaults 96 9"
#                path => "/usr/local/bin/:/bin/",
#                require => File["/etc/init.d/kibana4"]
#        }

        service { "kibana4" :
                ensure => "running",
#                enable => "true",
                require => File["/etc/init.d/kibana4"]
        }


        # Confguring kibana htpasswd . Reqire ngninx installed

        file {"/etc/nginx/htpasswd.kibana":
                source => "puppet:///modules/elk/htpasswd.kibana",
                ensure => present,
                require => Class["nginx"]
        }

#       # Configuring kibana . Require Kibana installed 
#
#       file {"/var/www/kibana-3.1.1/config.js":
#               content => template("elk/config.js.erb"),
#               ensure => present,
#               require => Exec["untar kibana"]
#       }

        # apache 2 utils

        package { "apache2-utils":
                ensure => latest,
        }

        # Nginx Install / Port Proxing and vhost configuring

        class { "nginx": }
        nginx::resource::upstream { 'kibana':
                ensure  => present,
                members => [
                        'localhost:5601',
                        ],
        }

        nginx::resource::upstream { 'elasticsearch':
                ensure  => present,
                members => [
                        "$ipaddress_eth0:9200",
                        ],
        }

        nginx::resource::vhost { 'kibana.axsmarine.com':
                ensure               => present,
                server_name          => ['kibana.axsmarine.com'],
                listen_port          => 80,
                auth_basic           => "Restricted Access",
                auth_basic_user_file => "/etc/nginx/htpasswd.kibana",
                use_default_location => true,
                proxy                => "http://kibana",
#               www_root             => "/var/www/kibana-3.1.1",
        }

        nginx::resource::vhost { 'kopf.axsmarine.com':
                ensure               => present,
                server_name          => ['kopf.axsmarine.com'],
                listen_port          => 80,
                auth_basic           => "Restricted Access",
                auth_basic_user_file => "/etc/nginx/htpasswd.kibana",
                use_default_location => true,
                proxy                => "http://elasticsearch",
        }

        nginx::resource::location {"kopf.axsmarine.com" : 
                vhost => "kopf.axsmarine.com", 
                proxy_connect_timeout => 600,
                proxy_read_timeout => 600,
                location_cfg_append => {
                        proxy_send_timeout => 600,
                        send_timeout => 600
                },
                location => "~ ^/_plugin/kopf$",
                proxy => "http://elasticsearch"
        }

#      nginx::resource::location { "kibana.axsmarine.com":
#               vhost => "kibana.axsmarine.com",
#               location  => "~ ^/_aliases$",
#               proxy_connect_timeout => 600,
#               proxy => "http://elasticsearch",
#       }
#
#       nginx::resource::location { "kibana.axsmarine.com1":
#               vhost => "kibana.axsmarine.com",
#                location  => "~ ^/.*/_aliases$",
#                proxy => "http://elasticsearch",
#        }
#
#       nginx::resource::location { "kibana.axsmarine.com2":
#                vhost => "kibana.axsmarine.com",
#                location  => "~ ^/_nodes$",
#                proxy => "http://elasticsearch",
#        }
#
#       nginx::resource::location { "kibana.axsmarine.com3":
#                vhost => "kibana.axsmarine.com",
#                location  => "~ ^/.*/_search$",
#                proxy => "http://elasticsearch",
#        }
#
#       nginx::resource::location { "kibana.axsmarine.com4":
#                vhost => "kibana.axsmarine.com",
#                location  => "~ ^/.*/_mapping",
#               proxy => "http://elasticsearch",
#        }
#
#       nginx::resource::location { "kibana.axsmarine.com5":
#                vhost => "kibana.axsmarine.com",
#                location  => "~ ^/kibana-int/dashboard/.*$",
#                proxy => "http://elasticsearch",
#        }
#
#       nginx::resource::location { "kibana.axsmarine.com6":
#                vhost => "kibana.axsmarine.com",
#                location  => "~ ^/kibana-int/temp.*$",
#                proxy => "http://elasticsearch",
#        }

} #end node elastic


#
#
#
# NODEs AWS-SYSTEM
#
#
#

node "aws-system.aws.axsmarine.com" {

        class {"apache":
                service_ensure  => running,
                user            => "www-data",
                group           => "www-data",
                manage_group    => false,
                manage_user     => false,
                log_level       => "debug",
                docroot         => "/var/www/html",
                default_vhost   => false,
                serveradmin     => "sysadmin@axsmarine.com",
                server_tokens   => "Prod",
                server_signature=> "Off",
                mpm_module      => false,
                keepalive       => "On",
                keepalive_timeout => "15",
                max_keepalive_requests => "100",
                default_mods    => ["access_compat","actions","alias","auth_basic","authn_core","authn_file","authz_user","autoindex","cgi","deflate","dir","env","expires","filter","mime","negotiation","reqtimeout","rewrite","setenvif", "ssl", "status"],
        }


        class {"apache::mod::prefork":
                        startservers    => 40,
                        minspareservers => 30,
                        maxspareservers => 60,
                        serverlimit     => 2048,
                        maxclients      => 1024
        }

        class { 'apache::mod::status':
                        allow_from      => ['127.0.0.1','::1'],
                        extended_status => 'On',
                        status_path     => '/server-status',
        }

        apache::listen { '80': }


# VHOSTS
        # DEFAULT FRONT-END DECLARATION
        apache::vhost { "aws-system.aws.axsmarine.com":
                priority                => "00",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/var/www/html",
                manage_docroot          => false,
                vhost_name              => "aws-system.aws.axsmarine.com",
         }

apache::vhost { "apt.aws.axsmarine.com":
                priority                => "10",
                port                    => "80",
                ip                      => "*",
                add_listen              => false,
                docroot                 => "/var/repositories",
                manage_docroot          => false,
                vhost_name              => "apt.aws.axsmarine.com",
                serveraliases           => "www.apt.aws.axsmarine.com",
		directories             => [{
                        path            => "/var/repositories",
			custom_fragment => "
# Allow directory listings so that people can browse the repository from their browser too
Options Indexes FollowSymLinks MultiViews
                    DirectoryIndex index.html
                    Require all granted
                    AllowOverride Options"},{
                        path            => "/var/repositories/*/conf",
			auth_require    => "all denied"},{
#			custom_fragment => "
# Hide the conf/ directory for all repositories
#Require all denied"},{
                        path            => "/var/repositories/*/db",
			auth_require    => "all denied"}]
#			custom_fragment => "
# Hide the db/ directory for all repositories
#Require all denied"}]

        
        }

} #end node aws-system








