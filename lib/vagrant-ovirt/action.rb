require 'vagrant/action/builder'

module VagrantPlugins
  module OVirtProvider
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action is called to bring the box up from nothing.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOVirt
          b.use Call, IsCreated do |env, b2|
            if env[:result]
              b2.use MessageAlreadyCreated
              next
            end

            b2.use SetNameOfDomain
            b2.use CreateVM

            b2.use TimedProvision
            b2.use CreateNetworkInterfaces

            b2.use SetHostname
            b2.use StartVM
            b2.use WaitTillUp
            b2.use SyncFolders
          end
        end
      end

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use ConnectOVirt
            b2.use DestroyVM
          end
        end
      end

      # This action is called to read the state of the machine. The resulting
      # state is expected to be put into the `:machine_state_id` key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOVirt
          b.use ReadState
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOVirt
          b.use ReadSSHInfo
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use SSHExec
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use SSHRun
          end
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use SyncFolders
            b2.use Provision
          end
        end
      end

      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :ConnectOVirt, action_root.join("connect_ovirt")
      autoload :IsCreated, action_root.join("is_created")
      autoload :SetNameOfDomain, action_root.join("set_name_of_domain")
      autoload :CreateVM, action_root.join("create_vm")
      autoload :CreateNetworkInterfaces, action_root.join("create_network_interfaces")
      autoload :StartVM, action_root.join("start_vm")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :DestroyVM, action_root.join("destroy_vm")
      autoload :ReadState, action_root.join("read_state")
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :TimedProvision, action_root.join("timed_provision")
      autoload :WaitTillUp, action_root.join("wait_till_up")
      autoload :SyncFolders, action_root.join("sync_folders")
      autoload :MessageAlreadyCreated, action_root.join("message_already_created")
    end
  end
end

