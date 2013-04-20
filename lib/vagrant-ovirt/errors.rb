require 'vagrant'

module VagrantPlugins
  module OVirtProvider
    module Errors
      class VagrantOVirtError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_ovirt.errors")
      end

      class FogOVirtConnectionError < VagrantOVirtError
        error_key(:fog_ovirt_connection_error)
      end

      class NoDatacenterError < VagrantOVirtError
        error_key(:no_datacenter_error)
      end

      class NoClusterError < VagrantOVirtError
        error_key(:no_cluster_error)
      end

      class NoTemplateError < VagrantOVirtError
        error_key(:no_template_error)
      end

      class NoQuotaError < VagrantOVirtError
        error_key(:no_template_error)
      end

      class FogCreateServerError < VagrantOVirtError
        error_key(:fog_create_server_error)
      end

      class InterfaceSlotNotAvailable < VagrantOVirtError
        error_key(:interface_slot_not_available)
      end

      class AddInterfaceError < VagrantOVirtError
        error_key(:add_interface_error)
      end

      class NoVMError < VagrantOVirtError
        error_key(:no_vm_error)
      end

      class StartVMError < VagrantOVirtError
        error_key(:start_vm_error)
      end

      class NoIpAddressError < VagrantOVirtError
        error_key(:no_ip_address_error)
      end

      class NoNetworkError < VagrantOVirtError
        error_key(:no_network_error)
      end

    end
  end
end

