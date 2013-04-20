require 'log4r'

module VagrantPlugins
  module OVirtProvider
    module Action
      # Create network interfaces for machine, before VM is running.
      class CreateNetworkInterfaces

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt::action::create_network_interfaces")
          @app = app
        end

        def call(env)
          # Get machine first.
          begin
            machine = OVirtProvider::Util::Collection.find_matching(
              env[:ovirt_compute].servers.all, env[:machine].id.to_s)
          rescue => e
            raise Errors::NoVMError,
              :vm_name => env[:machine].id.to_s
          end

          # Setup list of interfaces before creating them
          adapters = []

          # First interface is for provisioning, so this slot is not usable.
          # This interface should be available already from template.
          adapters[0] = :reserved

          env[:machine].config.vm.networks.each do |type, options|
            # Other types than bridged are not supported for now.
            next if type != :bridged

            network_name = 'rhevm'
            network_name = options[:bridge] if options[:bridge]

            if options[:adapter]
              if adapters[options[:adapter]]
                raise Errors::InterfaceSlotNotAvailable
              end

              adapters[options[:adapter].to_i] = network_name
            else
              empty_slot = find_empty(adapters, start=1)
              raise Errors::InterfaceSlotNotAvailable if empty_slot == nil

              adapters[empty_slot] = network_name
            end           
          end

          # Create each interface as new domain device
          adapters.each_with_index do |network_name, slot_number|
            next if network_name == :reserved
            iface_number = slot_number + 1

            # Get network id
            network = OVirtProvider::Util::Collection.find_matching(
              env[:ovirt_client].networks(:cluster => env[:ovirt_cluster].id),
              network_name)
            if network == nil
              raise Errors::NoNetworkError,
                :network_name => network_name
            end

            @logger.info("Creating network interface nic#{iface_number}")
            begin
              machine.add_interface(
                :name    => "nic#{iface_number}",
                :network => network.id,

                # TODO This should be configurable in Vagrantfile.
                :interface => 'virtio',
              )
            rescue => e
              raise Errors::AddInterfaceError,
                :error_message => e.message
            end
          end

          @app.call(env)
        end

        private

        def find_empty(array, start=0, stop=8)
          for i in start..stop
            return i if !array[i]
          end
          return nil
        end
      end
    end
  end
end

