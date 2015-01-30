# = Class: foreman::compute::libvirt
#
class foreman::compute::libvirt {
  realize Package['foreman-libvirt']
}
