# Installs & configure the savanna API service

class savanna::api (
  $enabled              = true,
  $keystone_host        = '127.0.0.1',
  $keystone_port        = '35357',
  $keystone_protocol    = 'http',
  $keystone_user        = 'savanna',
  $keystone_tenant      = 'services',
  $keystone_password    = 'savanna',
  $bind_port            = '8386',
  $node_domain          = 'novalocal',
  $plugins              = 'vanilla,hdp',
  $vanilla_plugin_class = 'savanna.plugins.vanilla.plugin:VanillaProvider',
  $hdp_plugin_class     = 'savanna.plugins.hdp.ambariplugin:AmbariPlugin',
  $sql_connection       = 'mysql://savanna:savanna@localhost/savanna',
  $use_neutron          = false,
  $use_floating_ips     = true,
) inherits savanna::params {

  validate_string($keystone_password)

  package { 'savanna':
    ensure => installed,
    name   => $savanna::params::savanna_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if $use_neutron {
    $use_neutron_value = true
  } else {
    $use_neutron_value = false
  }

  if $use_floating_ips {
    $use_floating_ips_value = true
  } else {
    $use_floating_ips_value = false
  }

  service { 'savanna-api':
    ensure     => $service_ensure,
    name       => $savanna::params::savanna_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  savanna_config {
    'DEFAULT/os_admin_tenant_name'         : value => $keystone_tenant;
    'DEFAULT/os_admin_username'            : value => $keystone_user;
    'DEFAULT/os_admin_password'            : value => $keystone_password;
    'DEFAULT/os_auth_host'                 : value => $keystone_host;
    'DEFAULT/os_auth_port'                 : value => $keystone_port;
    'DEFAULT/use_floating_ips'             : value => $use_floating_ips_value;
    'DEFAULT/use_neutron'                  : value => $use_neutron_value;
    'DEFAULT/node_domain'                  : value => $node_domain;
    'DEFAULT/plugins'                      : value => $plugins;
    'plugin:vanilla/plugin_class'          : value => $vanilla_plugin_class;
    'plugin:hdp/plugin_class'              : value => $hdp_plugin_class;
    'database/connection'                  : value => $sql_connection;
  }

  nova_config {
    'DEFAULT/scheduler_driver'             : value => 'nova.scheduler.filter_scheduler.FilterScheduler';
    'DEFAULT/scheduler_default_filters'    : value => 'DifferentHostFilter,SameHostFilter';
  }

  Package['savanna'] -> Savanna_config<||> -> Service['savanna-api']

}
