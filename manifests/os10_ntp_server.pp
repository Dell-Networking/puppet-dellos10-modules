# Sample manifest file for os10_ntp_server resource

os10_ntp_server {'time.domain.com':
  ensure => present,
  key    => 123,
  prefer => true,
}
