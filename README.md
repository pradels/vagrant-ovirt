# Vagrant oVirt/RHEV Provider

This is a [Vagrant](http://www.vagrantup.com) 1.1+ plugin that adds an
[oVirt](http://ovirt.org) and
[rhev](http://www.redhat.com/products/virtualization/) provider to Vagrant,
allowing Vagrant to control and provision machines in oVirt and RHEV.

In this document, both oVirt and RHEV names are used interchangeably and
represent the same platform on top of which this provider should work.

**Note:** Actual version (0.0.2) is still a development one. It was developed
and tested on RHEV 3.1 only.

## Features (Version 0.0.2)

* Vagrant `up` and `destroy` commands.
* Create and boot oVirt machines from templates.
* SSH into domains.
* Provision domains with any built-in Vagrant provisioner.
* Minimal synced folder support via `rsync`.

## Future work

* Validation of configuration parameters.
* Test it on other versions of oVirt and RHEV.
* Template preparation scripts for other distros than RHEL.
* Vagrant commands `halt`, `resume`, `ssh`, `provision`, `suspend` and `resume`.
* Take a look at [open issues](https://github.com/pradels/vagrant-ovirt/issues?state=open).

## Installation

Install using standard [Vagrant 1.1+](http://downloads.vagrantup.com) plugin installation methods. After
installing, `vagrant up` and specify the `ovirt` provider. An example is shown below.

```
$ vagrant plugin install vagrant-ovirt
```

## Vagrant Project Preparation

After installing the plugin (instructions above), the quickest way to get
started is to actually use a dummy oVirt box and specify all the details
manually within a `config.vm.provider` block. So first, add the dummy box using
any name you want:

```
$ vagrant box add ovirt https://raw.github.com/pradels/vagrant-ovirt/master/example_box/ovirt.box
```

And then make a Vagrantfile that looks like the following, filling in
your information where necessary.

```ruby
Vagrant.configure("2") do |config|
  config.vm.define :test_vm do |test_vm|
    test_vm.vm.box = "ovirt"
    test_vm.vm.network :private_network,
      :ip => '10.20.30.40',
      :ovirt__network_name => 'ovirt_network',

    test_vm.vm.provider :ovirt do |ovirt|
      ovirt.template = "Template name"
      ovirt.quota = "Quota name"
      ovirt.cpus = 1
      ovirt.memory = 1024
    end
  end

  config.vm.provider :ovirt do |ovirt|
    ovirt.url = "https://ovirt.example.com:443"
    ovirt.username = "Username"
    ovirt.password = "Secret"
    ovirt.datacenter = "Datacenter name"
  end
end

```

### RHEV/oVirt Configuration Options

This provider exposes quite a few provider-specific configuration options:

* `url` - URL to management interface.
* `username` - Username to access oVirt.
* `password` - Password to access oVirt.
* `datacenter` - oVirt datacenter name, where machines will be created.
* `cluster` - oVirt cluster name. Defaults to first cluster found.
* `ip_command` - Shell command, which shoud return IP address string for
 MAC address specified in environment variable named $MAC. By default, this
 command searches IP in local arp table.

### Domain Specific Options

* `memory` - Amount of memory in MBytes. Defaults to 512 if not set.
* `cpus` - Number of virtual cpus. Defaults to 1 if not set.
* `template` - Name of template from which new VM should be created.
* `quota` - Name of oVirt quota for VM. Defaults to first quota found in
  datacenter.

Specific domain settings can be set for each domain separately in multi-VM
environment. Example below shows a part of Vagrantfile, where specific options
are set for dbserver domain.

```ruby
Vagrant.configure("2") do |config|
  config.vm.define :dbserver do |dbserver|
    dbserver.vm.box = "ovirt"
    dbserver.vm.provider :ovirt do |vm|
      vm.memory = 2048
      vm.cpus = 2
      vm.template = "centos63-vagrant-base"
    end
  end

  # ...
```

## Create Project - Vagrant up

In prepared project directory, run following command:

```
$ vagrant up --provider=ovirt
```

Vagrant needs to know that we want to use oVirt and not default VirtualBox.
That's why there is `--provider=ovirt` option specified. Other way to tell
Vagrant to use oVirt provider is to setup environment variable
`export VAGRANT_DEFAULT_PROVIDER=ovirt`.

### How Project Is Created

Vagrant goes through steps below when creating new project:

1.	Connect to oVirt via REST API on every REST query.
2.	Create new oVirt machine from template with additional network interfaces.
3.	Start oVirt machine.
4.	Check for IP address of VM with `ip_command`.
5.	Wait till SSH is available.
6.	Sync folders via `rsync` and run Vagrant provisioner on new domain if
	setup in Vagrantfile.

## Network Interfaces

Networking features in the form of `config.vm.network` support private networks
concept. No public network or port forwarding are supported in current version
of provider.

An examples of network interface definitions:

```ruby
  config.vm.define :test_vm1 do |test_vm1|
    test_vm1.vm.network :private_network,
      :ip      => "10.20.30.40",
      :netmask => "255.255.255.0",
      :ovirt__network_name => "ovirt_networkname"
  end
```

In example below, one additional network interface is created for VM test_vm1.
Interface is connected to `ovirt_networkname` network and configured to ip
address `10.20.30.40/24`. If you omit ip address, interface will be configured
dynamicaly via dhcp.


## Obtaining Domain IP Address

OVirt API doesn't provide standard way how to find out an IP address of running
VM. But we know, what is MAC address of virtual machine. Problem is, where to
get mapping MAC to IP address.

There is an option named ip_command, which by default looks into local arp
table and searches there IP for MAC address specified as a MAC shell variable.
Maybe you need to customize this behaviour, so setup your own ip_commands to
your needs.

## Synced Folders

There is minimal support for synced folders. Upon `vagrant up`, the oVirt
provider will use `rsync` (if available) to uni-directionally sync the folder
to the remote machine over SSH.

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

## Box Format

Every provider in Vagrant must introduce a custom box format. This provider
introduces oVirt boxes. You can view an example box in the
[example_box](https://github.com/pradels/vagrant-ovirt/tree/master/example_box)
directory. That directory also contains instructions on how to build a box.

The box is a tarball containing:

* `metadata.json` file describing box image (just a provider name).
* `Vagrantfile` that does default settings for the provider-specific configuration for this provider.

## Development

To work on the `vagrant-ovirt` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

```
$ git clone https://github.com/pradels/vagrant-ovirt.git
$ cd vagrant-ovirt
$ bundle install
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
that uses it. Don't forget to add following line at the beginning of your
`Vagrantfile` while in development mode:

```ruby
Vagrant.require_plugin "vagrant-ovirt"
```

Now you can use bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=ovirt
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

