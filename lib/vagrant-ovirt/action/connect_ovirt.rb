require 'fog'
require 'log4r'
require 'pp'
require 'rbovirt'

module VagrantPlugins
  module OVirtProvider
    module Action
      class ConnectOVirt
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt::action::connect_ovirt")
          @app = app
        end

        def call(env)

          # We need both, fog and rbovirt client. Sometimes fog doesn't
          # support some operations like managing quotas, or working with
          # networks. For this rbovirt client is used.
          env[:ovirt_client] = OVirtProvider.ovirt_client if \
            OVirtProvider.ovirt_client != nil

          if OVirtProvider.ovirt_connection != nil
            env[:ovirt_compute] = OVirtProvider.ovirt_connection
            return @app.call(env)
          end
          
          # Get config options for ovirt provider.
          config = env[:machine].provider_config

          conn_attr = {}
          conn_attr[:provider] = 'ovirt'
          conn_attr[:ovirt_url] = "#{config.url}/api"
          conn_attr[:ovirt_username] = config.username if config.username
          conn_attr[:ovirt_password] = config.password if config.password

          # We need datacenter id in fog connection initialization. But it's
          # much simpler to use datacenter name in Vagrantfile. So get
          # datacenter id here from rbovirt client before connecting to fog.
          env[:ovirt_client] = ovirt_connect(conn_attr)
          begin
            datacenter = OVirtProvider::Util::Collection.find_matching(
              env[:ovirt_client].datacenters, config.datacenter)
          rescue OVIRT::OvirtException => e
            raise Errors::FogOVirtConnectionError,
              :error_message => e.message
          end

          raise Errors::NoDatacenterError if datacenter == nil
          conn_attr[:ovirt_datacenter] = datacenter.id

          # Reconnect and prepar rbovirt client with datacenter set from
          # configuration.
          env[:ovirt_client] = ovirt_connect(conn_attr)
          OVirtProvider.ovirt_client = env[:ovirt_client]
          
          # Establish fog connection now.
          @logger.info("Connecting to oVirt (#{config.url}) ...")
          begin
            env[:ovirt_compute] = Fog::Compute.new(conn_attr)
          rescue OVIRT::OvirtException => e
            raise Errors::FogOVirtConnectionError,
              :error_message => e.message
          end
          OVirtProvider.ovirt_connection = env[:ovirt_compute]

          @app.call(env)
        end

        private

        def ovirt_connect(credentials)
          OVIRT::Client.new(
            credentials[:ovirt_username],
            credentials[:ovirt_password],
            credentials[:ovirt_url],
            credentials[:ovirt_datacenter],
          )
        end
      end
    end
  end
end

