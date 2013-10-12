# Configure the foreman service using passenger
class foreman::config::passenger (
  # specifiy which interface to bind passenger to eth0, eth1, ...
  $listen_on_interface = '',
  $scl_prefix          = undef,
  $ssl                 = $::foreman::params::ssl,) inherits foreman::params {
  # validate parameter values
  validate_bool($ssl)
  validate_string($listen_on_interface)

  include apache

  # Check the value in case the interface doesn't exist, otherwise listen on all interfaces
  if $listen_on_interface in split($::interfaces, ',') {
    $listen_interface = inline_template("<%= @ipaddress_${listen_on_interface} %>")
  } else {
    $listen_interface = '*'
  }

  if $ssl {
    include apache::mod::ssl

    apache::listen { 443: }
    
    # Add ssl fragment to vhost if needed
    $ssl_fragment = template('foreman/foreman-vhost-ssl.conf.erb')
  }

  $listen_ports = 80

  include apache::mod::passenger

  if $scl_prefix {
    class { '::foreman::install::passenger_scl': prefix => $scl_prefix, }
  }
  
  if $foreman::params::use_vhost {
	  file { "${app_root}/public":
	    ensure => link,
	    target => '/var/lib/foreman/public/',
	    before => Apache::Vhost['foreman'],
	  }

    apache::vhost { 'foreman':
      custom_fragment => $ssl_fragment,
      port            => $listen_ports,
      docroot         => "${app_root}/public",
      priority        => '15',
      serveraliases   => [ 'foreman' ],
      notify          => Service['httpd'],
      require         => Class['foreman::install'],
    }
  } else {
    file { 'foreman_vhost':
      path    => "${foreman::params::apache_conf_dir}/foreman.conf",
      content => template('foreman/foreman-apache.conf.erb'),
      mode    => '0644',
      notify  => Service['httpd'],
      require => Class['foreman::install'],
    }
  }

  exec { 'restart_foreman':
    command     => "/bin/touch ${foreman::params::app_root}/tmp/restart.txt",
    refreshonly => true,
    cwd         => $foreman::params::app_root,
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  file { ["${foreman::params::app_root}/config.ru", "${foreman::params::app_root}/config/environment.rb"]:
    owner   => $foreman::params::user,
    require => Class['foreman::install'],
  }
}
