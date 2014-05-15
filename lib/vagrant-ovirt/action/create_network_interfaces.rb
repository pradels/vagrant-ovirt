require 'log4r'
require 'vagrant/util/scoped_hash_override'

module VagrantPlugins
  module OVirtProvider
    module Action
      # Create network interfaces for machine, before VM is running.
      class CreateNetworkInterfaces
        include Vagrant::Util::ScopedHashOverride

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

          env[:machine].config.vm.networks.each do |type, options|
            # We support private and public networks only. They mean both the
            # same right now.
            next if type != :private_network and type != :public_network

            # Get options for this interface. Options can be specified in
            # Vagrantfile in short format (:ip => ...), or provider format
            # (:ovirt__network_name => ...).
            options = scoped_hash_override(options, :ovirt)
            options = {
              :netmask      => '255.255.255.0',
              :network_name => 'rhevm'
            }.merge(options)

            if options[:adapter]
              if adapters[options[:adapter]]
                raise Errors::InterfaceSlotNotAvailable
              end

              free_slot = options[:adapter].to_i
            else
              free_slot = find_empty(adapters, start=1)
              raise Errors::InterfaceSlotNotAvailable if free_slot == nil
            end

            adapters[free_slot] = options
          end

          # Create each interface as new domain device
          adapters.each_with_index do |opts, slot_number|
            next if slot_number == 0 or opts.nil?
            iface_number = slot_number + 1

            #require 'pp'
            #pp env[:ovirt_client].networks(:cluster => env[:ovirt_cluster].id)

            # Get network id
            network = OVirtProvider::Util::Collection.find_matching(
              env[:ovirt_client].networks(:cluster_id => env[:ovirt_cluster].id),
              opts[:network_name])
            if network == nil
              raise Errors::NoNetworkError,
                :network_name => opts[:network_name]
            end

            @logger.info("Creating network interface nic#{iface_number}")
            begin
              machine.add_interface(
                :name    => "nic#{iface_number}",
                :network => network.id,
                :interface => network.name,
              )
            rescue => e
              raise Errors::AddInterfaceError,
                :error_message => e.message
            end
          end

          # Continue the middleware chain.
          @app.call(env)

          # Configure interfaces that user requested. Machine should be up and
          # running now.
          networks_to_configure = []

          adapters.each_with_index do |opts, slot_number|
            # Skip configuring first interface. It's used for provisioning and
            # it has to be available during provisioning - ifdown command is
            # not acceptable here.
            next if slot_number == 0

            network = {
              :interface => slot_number,
              #:mac => ...,
            }

            if opts[:ip]
              network = {
                :type    => :static,
                :ip      => opts[:ip],
                :netmask => opts[:netmask],
                :gateway => opts[:gateway],
              }.merge(network)
            else
              network[:type] = :dhcp
            end

            networks_to_configure << network
          end

          env[:ui].info I18n.t("vagrant.actions.vm.network.configuring")
          env[:machine].guest.capability(
            :configure_networks, networks_to_configure)
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

