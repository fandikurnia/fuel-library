class quantum::agents::ovs (
  $package_ensure       = 'present',
  $enabled              = true,
  $bridge_uplinks       = ['br-ex:eth1'],
  $bridge_mappings      = ['br-virtual:br-ex'],
  $integration_bridge   = 'br-int',
  $enable_tunneling     = false,
  $local_ip             = false,
  $tunnel_bridge        = 'br-tun'
) {

  include 'quantum::params'
  if $enable_tunneling and ! $local_ip {
    fail('Local ip for ovs agent must be set when tunneling is enabled')
  }

  include 'quantum::params'
  require 'vswitch::ovs'

  if $::quantum::params::ovs_agent_package {
    Package['quantum'] ->  Package['quantum-plugin-ovs-agent']

    $ovs_agent_package = 'quantum-plugin-ovs-agent'

    package { 'quantum-plugin-ovs-agent':
      name    => $::quantum::params::ovs_agent_package,
      ensure  => $package_ensure,
    }
  } else {
    $ovs_agent_package = $::quantum::params::ovs_server_package
  }

  Package[$ovs_agent_package] -> Quantum_plugin_ovs<||>

  vs_bridge {$integration_bridge:
    external_ids => "bridge-id=${ingration_bridge}",
    ensure       => present,
    require      => Service['quantum-plugin-ovs-service'],
  }

  if $enable_tunneling {
    vs_bridge {$tunnel_bridge:
      external_ids => "bridge-id=${tunnel_bridge}",
      ensure       => present,
      require      => Service['quantum-plugin-ovs-service'],
    }
  }

  quantum::plugins::ovs::bridge{$bridge_mappings:
    require      => Service['quantum-plugin-ovs-service'],
  }
  quantum::plugins::ovs::port{$bridge_uplinks:
    require      => Service['quantum-plugin-ovs-service'],
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  quantum_plugin_ovs {
    'OVS/local_ip': value => $local_ip;
  }

  service { 'quantum-plugin-ovs-service':
    name    => $::quantum::params::ovs_agent_service,
    enable  => $enable,
    ensure  => $service_ensure,
    require => [Package[$ovs_agent_package]]
  }
}