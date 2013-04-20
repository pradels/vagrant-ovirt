require 'pathname'
require 'vagrant-ovirt/plugin'

module VagrantPlugins
  module OVirtProvider
    lib_path = Pathname.new(File.expand_path("../vagrant-ovirt", __FILE__))
    autoload :Action, lib_path.join("action")
    autoload :Errors, lib_path.join("errors")
    autoload :Util, lib_path.join("util")

    # Hold connection handler so there is no need to connect more times than
    # one. This can be annoying when there are more machines to create, or when
    # doing state action first and then some other.
    #
    # TODO Don't sure if this is the best solution
    @@ovirt_connection = nil
    @@ovirt_client = nil
    def self.ovirt_connection
      @@ovirt_connection
    end

    def self.ovirt_connection=(conn)
      @@ovirt_connection = conn
    end

    def self.ovirt_client
      @@ovirt_client
    end

    def self.ovirt_client=(conn)
      @@ovirt_client = conn
    end


    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end

# Set default provider with bash environment variable like this:
# export VAGRANT_DEFAULT_PROVIDER=ovirt
Vagrant::Environment.class_eval do
  def default_provider
    (ENV['VAGRANT_DEFAULT_PROVIDER'] || :virtualbox).to_sym
  end
end
