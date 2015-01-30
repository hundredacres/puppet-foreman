class foreman::smartproxy {
  package { 'foreman-proxy':
    ensure => present,
  }
}
