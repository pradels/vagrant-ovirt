require "log4r"

module VagrantPlugins
  module OVirtProvider
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_ovirt::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(
            env[:ovirt_compute], env[:machine])

          @app.call(env)
        end

        def read_ssh_info(ovirt, machine)
          return nil if machine.id.nil?

          # Get config.
          config = machine.provider_config

          # Find the machine
          server = ovirt.servers.get(machine.id.to_s)

          if server.nil?
            # The machine can't be found
            @logger.info("Machine couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end

          # oVirt doesn't provide a way how to find out IP of VM via API.
          # IP command should return IP address of MAC defined as a shell
          # variable.
          # TODO place code for obtaining IP in one place.
          first_interface = OVirtProvider::Util::Collection.find_matching(
            server.interfaces, 'nic1')
          ip_command = "MAC=#{first_interface.mac}; #{config.ip_command}"

          for i in 1..3
            # Get IP address via ip_command.
            ip_address = %x{#{ip_command}}
            break if ip_address != ''
            sleep 2
          end
          if ip_address == nil or ip_address == ''
            raise Errors::NoIpAddressError
          end

          # Return the info
          # TODO: Some info should be configurable in Vagrantfile
          return {
            :host          => ip_address.chomp!,
            :port          => 22,
            :username      => 'root',
            :forward_agent => true,
            :forward_x11   => true,
          }
        end 
      end
    end
  end
end
