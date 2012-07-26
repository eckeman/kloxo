### begin content - please not remove this line

<?php

$ipports = '';

if ($reverseproxy) {
    $port = '30080';
    $portssl = '30443';
} else {
    $port = '80';
    $portssl = '443';
}

/*
foreach ($iplist as &$ip) {
    $ipports .= "    {$ip}:{$port} {$ip}:{$portssl}\\\n";
}

$ipports .= "    127.0.0.1:{$port}";
*/

$ipports = "    *:{$port} *:{$portssl}";

if ($ipssllist) {
    foreach ($ipssllist as &$ipssl) {
        $ipsslports .= "    {$ipssl}:{$port} {$ipssl}:{$portssl}\\\n";
    }

    $ipsslports .= "    127.0.0.1:{$port}";
} else {
    $ipsslports = $ipports;
}

$statsapp = $stats['app'];
$statsprotect = ($stats['protect']) ? true : false;

$serveralias = "www.{$domainname}";

if ($wildcards) {
    $serveralias .= " *.{$domainname}";
}

if ($serveraliases) {
    foreach ($serveraliases as &$sa) {
        $serveralias .= "\\\n        {$sa}";
    }
}

if ($parkdomains) {
    foreach ($parkdomains as $pk) {
        $pa = $pk['parkdomain'];
        $serveralias .= "\\\n        {$pa} www.{$pa}";
    }
}

if ($webmailapp === $webmailappdefault) {
    $webmailapp = null;
} else {
    if ($webmailapp) {
        $webmaildocroot = "/home/kloxo/httpd/webmail/{$webmailapp}";
    } else {
        $webmaildocroot = "/home/kloxo/httpd/webmail";
    }
}

if ($indexorder) {
    $indexorder = implode(' ', $indexorder);
}

$userinfo = posix_getpwnam($user);
$fpmport = (50000 + $userinfo['uid']);

$disablepath = "/home/kloxo/httpd/disable";
?>

## web for '<?php echo $domainname; ?>'
<VirtualHost \
<?php echo $ipsslports; ?>\
        >

    ServerAdmin webmaster@<?php echo $domainname; ?>


    ServerName <?php echo $domainname; ?>


    ServerAlias <?php echo $serveralias; ?>

<?php
    if ($wwwredirect) {
?>

    RewriteEngine On
    RewriteCond %{HTTP_HOST} ^<?php echo str_replace('.', '\.', $domainname); ?>$ [NC]
    RewriteRule ^(.*)$ http://www.<?php echo $domainname; ?>$1 [R=301,L]

<?php
    }

    if ($disabled) {
        $rootpath = $disablepath;
    }
?>

    DocumentRoot "<?php echo $rootpath; ?>/"

    DirectoryIndex <?php echo $indexorder; ?>

<?php
    if ($redirectionlocal) {
        foreach ($redirectionlocal as $rl) {
?>

    Alias <?php echo $rl[0]; ?> "<?php echo $rootpath; ?><?php echo $rl[1]; ?>/"
<?php
        }
    }

    if ($redirectionremote) {
        foreach ($redirectionremote as $rr) {
            if ($rr[2] === 'both') {
?>

    Redirect <?php echo $rr[0]; ?> "<?php echo $rr[1]; ?>"
#    Redirect <?php echo $rr[0]; ?> "<?php echo str_replace("http://", "https://", $rr[1]); ?>"
<?php
            } else {
?>

    Redirect <?php echo $rr[0]; ?> "<?php echo $rr[1]; ?>"
<?php
            }
        }
    }
?>

    <IfModule suexec.c>
        SuexecUserGroup <?php echo $user; ?> <?php echo $user; ?>

    </IfModule>

    <IfModule !mod_fastcgi.c>
        <IfModule !mod_fcgid.c>
            <IfModule mod_suphp.c>
                AddHandler x-httpd-php .php
                AddHandler x-httpd-php .php .php4 .php3 .phtml
                suPHP_AddHandler x-httpd-php
                SuPhp_UserGroup <?php echo $user; ?> <?php echo $user; ?>

                suPHP_Configpath "/home/httpd/<?php echo $domainname; ?>/"
            </IfModule>
        </IfModule>
    </IfModule>

    <IfModule mod_ruid2.c>
        RMode config
        RUidGid <?php echo $user; ?> <?php echo $user; ?>

        RMinUidGid <?php echo $user; ?> <?php echo $user; ?>

    </IfModule>

    <IfModule itk.c>
        AssignUserId <?php echo $user; ?> <?php echo $user; ?>

        <Location /awstats/>
            AssignUserId lxlabs lxlabs
        </Location>
    </IfModule>

    <IfModule mod_fastcgi.c>
        Alias /<?php echo $domainname; ?>.fake "<?php echo $rootpath; ?>/<?php echo $domainname; ?>.fake"
        FastCGIExternalServer <?php echo $rootpath; ?>/<?php echo $domainname; ?>.fake -host 127.0.0.1:<?php echo $fpmport; ?>

        AddType application/x-httpd-fastphp .php
        Action application/x-httpd-fastphp /<?php echo $domainname; ?>.fake

        <Files "<?php echo $domainname; ?>.fake">
            RewriteCond %{REQUEST_URI} !<?php echo $domainname; ?>.fake
        </Files>
    </IfModule>

    <IfModule mod_fcgid.c>
        <Directory <?php echo $rootpath; ?>/>
            Options +ExecCGI
            AllowOverride All
            AddHandler fcgid-script .php
            FCGIWrapper /home/httpd/<?php echo $domainname; ?>/php5.fcgi .php
            Order allow,deny
            Allow from all
        </Directory>
    </IfModule>

    <IfModule mod_proxy_fcgi.c>
        ProxyPass / fcgi://127.0.0.1:<?php echo $fpmport; ?>/
        ProxyPassReverse / fcgi://127.0.0.1:<?php echo $fpmport; ?>/
    </IfModule>

    Alias /__kloxo "/home/<?php echo $user; ?>/kloxoscript/"

    Redirect /kloxo "https://cp.<?php echo $domainname; ?>:7777"
    Redirect /kloxononssl "http://cp.<?php echo $domainname; ?>:7778"

    Redirect /webmail "http://webmail.<?php echo $domainname; ?>"

    <Directory "/home/httpd/<?php echo $domainname; ?>/kloxoscript/">
        AllowOverride All
    </Directory>

    <IfModule mod_php5.c>
        php_admin_value sendmail_path "/usr/sbin/sendmail -t -i"
        php_admin_value sendmail_from "<?php echo $domainname; ?>"
    </IfModule>

    ScriptAlias /cgi-bin/ "/home/<?php echo $user; ?>/<?php echo $domainname; ?>/cgi-bin/"

    <Directory "<?php echo $rootpath; ?>/">
        AllowOverride All
        allow from all
        Options +Indexes +FollowSymlinks
    </Directory>

    <Location />
        Options +Includes +FollowSymlinks
    </Location>

    <Location />
        <IfModule mod_php5.c>
            php_admin_value open_basedir "/home/<?php echo $user; ?>:/home/<?php echo $user; ?>/kloxoscript:/home/<?php echo $domainname; ?>:/home/<?php echo $domainname; ?>/httpdocs:/tmp:/usr/share/pear:/var/lib/php/session/:/home/kloxo/httpd/script::/home/kloxo/httpd/disable/:<?php echo $extrabasedir; ?>"
        </IfModule>
    </Location>
<?php
    if (!$reverseproxy) {
?>

    CustomLog "/home/httpd/<?php echo $domainname ?>/stats/<?php echo $domainname ?>-custom_log" combined
    ErrorLog "/home/httpd/<?php echo $domainname ?>/stats/<?php echo $domainname ?>-error_log"
<?php
    }

    if ($statsapp === 'awstats') {
?>

    ScriptAlias /awstats/ "/home/kloxo/httpd/awstats/wwwroot/cgi-bin/"

    Alias /awstatscss "/home/kloxo/httpd/awstats/wwwroot/css/"
    Alias /awstatsicons "/home/kloxo/httpd/awstats/wwwroot/icon/"

    Redirect /stats "http://<?php echo $domainname; ?>/awstats/awstats.pl?config=<?php echo $domainname; ?>"
    Redirect /stats/ "http://<?php echo $domainname; ?>/awstats/awstats.pl?config=<?php echo $domainname; ?>"

    <Location /stats>
        Options +Indexes
    </Location>
<?php
        if ($statsprotect) {
?>

    <Location /stats>
        AuthType Basic
        AuthName "stats"
        AuthUserFile "/home/<?php echo $user; ?>/__dirprotect/__stats"
        require valid-user
    </Location>
<?php
        }

    } elseif ($statsapp === 'webalizer') {
?>

    Alias /stats "/home/httpd/<?php echo $domainname; ?>/webstats/"

    <Location /stats>
        Options +Indexes
    </Location>
<?php
        if ($statsprotect) {
?>

    <Location /awstats>
        AuthType Basic
        AuthName "Awstats"
        AuthUserFile "/home/<?php echo $user; ?>/__dirprotect/__stats"
        require valid-user
    </Location>
<?php
        }
    }

    if ($apacheextratext) {
?>

    # Extra Tags - begin
    <?php echo $apacheextratext; ?>

    # Extra Tags - end
<?php
    }

    if ($disablephp) {
?>
    AddType application/x-httpd-php-source .php
<?php
    }

    if ($dirprotect) {
        foreach ($dirprotect as $k) {
            $protectpath = $k['path'];
            $protectauthname = $k['authname'];
            $protectfile = str_replace('/', '_', $protectpath) . '_';
?>

    <Location /<?php echo $protectpath; ?>>
        AuthType Basic
        AuthName "<?php echo $protectauthname; ?>"
        AuthUserFile "/home/httpd/<?php echo $domainname; ?>/__dirprotect/<?php echo $protectfile; ?>"
        require valid-user
    </Location>
<?php
        }
    }

    if ($blockips) {
?>

    <Location />
        Order allow,deny
        deny from <?php echo $blockips; ?>
        allow from all
    </Location>
<?php
    }
?>

</VirtualHost>

<?php
    if ($disabled) {
?>

## webmail for '<?php echo $domainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName webmail.<?php echo $domainname; ?>


    DocumentRoot "<?php echo $disablepath; ?>/"

    DirectoryIndex <?php echo $indexorder; ?>


    <IfModule mod_suphp.c>
        AddHandler x-httpd-php .php
        AddHandler x-httpd-php .php .php4 .php3 .phtml
        suPHP_AddHandler x-httpd-php
        SuPhp_UserGroup lxlabs lxlabs
    </IfModule>

    <Location />
        allow from all
        Options +Indexes +FollowSymlinks
    </Location>

</VirtualHost>

<?php
    } else {
        if ($webmailremote) {
?>

## webmail for '<?php echo $domainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName webmail.<?php echo $domainname; ?>


    Redirect / "http://<?php echo $webmailremote; ?>"

</VirtualHost>

<?php
        } elseif ($webmailapp) {
?>

## webmail for '<?php echo $domainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName webmail.<?php echo $domainname; ?>


    DocumentRoot "<?php echo $webmaildocroot; ?>/"

    DirectoryIndex <?php echo $indexorder; ?>


    <IfModule mod_suphp.c>
        AddHandler x-httpd-php .php
        AddHandler x-httpd-php .php .php4 .php3 .phtml
        suPHP_AddHandler x-httpd-php
        SuPhp_UserGroup lxlabs lxlabs
    </IfModule>

    <Location />
        allow from all
        Options +Indexes +FollowSymlinks
    </Location>

</VirtualHost>

<?php
        } else {
?>

## webmail for '<?php echo $domainname; ?>' handled by ../defaults/webmail.conf

<?php
        }
    }

    if ($domainredirect) {
        foreach ($domainredirect as $domredir) {
            $redirdomainname = $domredir['redirdomain'];
            $redirpath = ($domredir['redirpath']) ? $domredir['redirpath'] : null;
            $webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

            $randnum = rand(0, 32767);

            if ($redirpath) {
                if ($disabled) {
                    $$redirfullpath = $disablepath;
                } else {
                    $redirfullpath = str_replace('//', '/', $rootpath . '/' . $redirpath);
                }
?>

## web for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName <?php echo $redirdomainname; ?>


    DocumentRoot "<?php echo $redirfullpath; ?>/"

    DirectoryIndex <?php echo $indexorder; ?>


    <IfModule suexec.c>
        SuexecUserGroup <?php echo $user; ?> <?php echo $user; ?>

    </IfModule>

    <IfModule !mod_fastcgi.c>
        <IfModule mod_suphp.c>
            AddHandler x-httpd-php .php
            AddHandler x-httpd-php .php .php4 .php3 .phtml
            suPHP_AddHandler x-httpd-php
            SuPhp_UserGroup <?php echo $user; ?> <?php echo $user; ?>

            suPHP_Configpath "/home/httpd/<?php echo $domainname; ?>/"
        </IfModule>
    </IfModule>

    <IfModule mod_ruid2.c>
        RMode config
        RUidGid <?php echo $user; ?> <?php echo $user; ?>

        RMinUidGid <?php echo $user; ?> <?php echo $user; ?>

    </IfModule>

    <IfModule itk.c>
        AssignUserId <?php echo $user; ?> <?php echo $user; ?>

        <Location /awstats/>
            AssignUserId lxlabs lxlabs
        </Location>
    </IfModule>

    <IfModule mod_fastcgi.c>
        Alias /<?php echo $redirdomainname; ?>.fake <?php echo $rootpath; ?>/<?php echo $redirdomainname; ?>.fake
        FastCGIExternalServer <?php echo $rootpath; ?>/<?php echo $redirdomainname; ?>.fake -host 127.0.0.1:<?php echo $fpmport; ?>

        AddType application/x-httpd-fastphp .php
        Action application/x-httpd-fastphp /<?php echo $redirdomainname; ?>.fake
        <Files "<?php echo $redirdomainname; ?>.fake">
            RewriteCond %{REQUEST_URI} !<?php echo $redirdomainname; ?>.fake
        </Files>
    </IfModule>

    <IfModule mod_proxy_fcgi.c>
        ProxyPass / fcgi://127.0.0.1:<?php echo $fpmport; ?>/
        ProxyPassReverse / fcgi://127.0.0.1:<?php echo $fpmport; ?>/
    </IfModule>

    <Directory "<?php echo $redirfullpath; ?>/">
        AllowOverride All
        allow from all
        Options +Indexes +FollowSymlinks
    </Directory>

</VirtualHost>

<?php
            } else {
?>

## web for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName <?php echo $redirdomainname; ?>


    Redirect / "http://<?php echo $domainname; ?>/"

</VirtualHost>

<?php
            }
        }
    }

    if ($parkdomains) {
        foreach ($parkdomains as $dompark) {
            $parkdomainname = $dompark['parkdomain'];
            $webmailmap = ($dompark['mailflag'] === 'on') ? true : false;

            if ($disabled) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName webmail.<?php echo $parkdomainname; ?>


    DocumentRoot "<?php echo $disablepath; ?>/"

    DirectoryIndex <?php echo $indexorder; ?>


    <IfModule mod_suphp.c>
        AddHandler x-httpd-php .php
        AddHandler x-httpd-php .php .php4 .php3 .phtml
        suPHP_AddHandler x-httpd-php
        SuPhp_UserGroup lxlabs lxlabs
    </IfModule>

    <Location />
        allow from all
        Options +Indexes +FollowSymlinks
    </Location>

</VirtualHost>

<?php
            } else {
                if ($webmailremote) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName webmail.<?php echo $parkdomainname; ?>


    Redirect / "http://<?php echo $webmailremote; ?>"

</VirtualHost>

<?php
                } elseif ($webmailmap) {
                    if ($webmailapp) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName webmail.<?php echo $parkdomainname; ?>


    DocumentRoot "<?php echo $webmaildocroot; ?>/"

    DirectoryIndex <?php echo $indexorder; ?>


    <IfModule mod_suphp.c>
        AddHandler x-httpd-php .php
        AddHandler x-httpd-php .php .php4 .php3 .phtml
        suPHP_AddHandler x-httpd-php
        SuPhp_UserGroup lxlabs lxlabs
    </IfModule>

    <Location />
        allow from all
        Options +Indexes +FollowSymlinks
    </Location>

</VirtualHost>

<?php
                    } else {
?>

## webmail for parked '<?php echo $parkdomainname; ?>' handled by ../defaults/webmail.conf

<?php
                    }
                } else {
?>

## No mail map for parked '<?php echo $parkdomainname; ?>'

<?php
                }
            }
        }
    }

    if ($domainredirect) {
        foreach ($domainredirect as $domredir) {
            $redirdomainname = $domredir['redirdomain'];
            $webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

            if ($disabled) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName webmail.<?php echo $redirdomainname; ?>


    DocumentRoot "<?php echo $disablepath; ?>"

    DirectoryIndex <?php echo $indexorder; ?>


    <IfModule mod_suphp.c>
        AddHandler x-httpd-php .php
        AddHandler x-httpd-php .php .php4 .php3 .phtml
        suPHP_AddHandler x-httpd-php
        SuPhp_UserGroup lxlabs lxlabs
    </IfModule>

    <Location />
        allow from all
        Options +Indexes +FollowSymlinks
    </Location>

</VirtualHost>

<?php
            } else {
                if ($webmailremote) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName webmail.<?php echo $redirdomainname; ?>


    Redirect / "http://<?php echo $webmailremote; ?>"

</VirtualHost>

<?php
                } elseif ($webmailmap) {
                    if ($webmailapp) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost \
<?php echo $ipports; ?>\
        >

    ServerName webmail.<?php echo $redirdomainname; ?>


    DocumentRoot "<?php echo $webmaildocroot; ?>/"

    DirectoryIndex <?php echo $indexorder; ?>


    <IfModule mod_suphp.c>
        AddHandler x-httpd-php .php
        AddHandler x-httpd-php .php .php4 .php3 .phtml
        suPHP_AddHandler x-httpd-php
        SuPhp_UserGroup lxlabs lxlabs
    </IfModule>

    <Location />
        allow from all
        Options +Indexes +FollowSymlinks
    </Location>

</VirtualHost>

<?php
                    } else {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>' handled by ../defaults/webmail.conf

<?php
                    }
                } else {
?>

## No mail map for redirect '<?php echo $redirdomainname; ?>'

<?php
                }
            }
        }
    }
?>

### end content - please not remove this line