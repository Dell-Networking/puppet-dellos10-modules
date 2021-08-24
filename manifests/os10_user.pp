# Sample manifest file for os10_ntp_server resource

os10_user {'my_username':
  ensure       => present,
  password     => 'my_secret_password',
  role         => 'netadmin',
  priv_level   => 15,
  ssh_key_type => key,
  ssh_key      => 'ssh-rsa jhghgdjhgdjvgjvgh',
}
