require 'log4r'
require 'vagrant/util/retryable'

module VagrantPlugins
  module OVirtProvider
    module Action
      class CreateVM
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt::action::create_vm")
          @app = app
        end

        def call(env)
          # Get config.
          config = env[:machine].provider_config

          # Gather some info about domain
          name = env[:domain_name]
          console = config.console
          cpus = config.cpus
          memory_size = config.memory*1024

          # Get cluster
          if config.cluster == nil
            cluster = env[:ovirt_compute].clusters.first
          else
            cluster = OVirtProvider::Util::Collection.find_matching(
              env[:ovirt_compute].clusters.all, config.cluster)
          end
          raise Error::NoClusterError if cluster == nil
          # TODO fill env also with other ovirtoptions.
          env[:ovirt_cluster] = cluster

          # Get template
          template = OVirtProvider::Util::Collection.find_matching(
            env[:ovirt_compute].templates.all, config.template)
          if template == nil
            raise Error::NoTemplateError,
              :template_name => config.template
          end

          # Output the settings we're going to use to the user
          env[:ui].info(I18n.t("vagrant_ovirt.creating_vm"))
          env[:ui].info(" -- Name:          #{name}")
          env[:ui].info(" -- Cpus:          #{cpus}")
          env[:ui].info(" -- Memory:        #{memory_size/1024}M")
          env[:ui].info(" -- Base box:      #{env[:machine].box.name}")
          env[:ui].info(" -- Template:      #{template.name}")
          env[:ui].info(" -- Datacenter:    #{config.datacenter}")
          env[:ui].info(" -- Cluster:       #{cluster.name}")
          env[:ui].info(" -- Console:       #{console}")

          # Create oVirt VM.
          attr = {
              :name     => name,
              :cores    => cpus,
              :memory   => memory_size*1024,
              :cluster  => cluster.id,
              :template => template.id,
              :display  => {:type => console },
          }

          begin
            server = env[:ovirt_compute].servers.create(attr)
          rescue OVIRT::OvirtException => e
            raise Errors::FogCreateServerError,
              :error_message => e.message
          end

          # Immediately save the ID since it is created at this point.
          env[:machine].id = server.id

          # Wait till all volumes are ready.
          env[:ui].info(I18n.t("vagrant_ovirt.wait_for_ready_vm"))
          for i in 0..5
            ready = true
            server.volumes.each do |volume|
              if volume.status != 'ok'
                ready = false
                break
              end
            end
            break if ready
            sleep 2
          end

          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          # Undo the import
          env[:ui].info(I18n.t("vagrant_ovirt.error_recovering"))
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end
      end
    end
  end
end
