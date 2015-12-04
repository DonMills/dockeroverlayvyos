# -*- mode: ruby -*-
# vi: set ft=ruby :

###########
# Set MINION_COUNT equal to the number of servers (besides the etcd server) you
# would like.  Set GUI to true for the VirtualBox to open a window for the
# machines, and false to run headless...
###3
MINION_COUNT = 1
GUI = true
# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "sepetrov/trusty64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
config.vm.define "etcdmaster" do |etcdmaster|
  etcdmaster.vm.provider "virtualbox" do |v|
  v.name = "etcdmaster"
  v.gui = GUI
  v.cpus = 1
  end
  etcdmaster.vm.hostname = "etcdmaster"
  etcdmaster.vm.network :private_network, ip: "192.168.2.15",
    virtualbox__intnet: "blue"
  etcdmaster.vm.provision "chef_solo" do |chef|
    chef.roles_path = "roles"
    chef.add_role("etcdmaster")
  end
  etcdmaster.vm.provision "shell", inline: "ip route add 192.168.30.0/24 via 192.168.2.1"
end

MINION_COUNT.times do |minion|
  ip_start="20"
  minion_id = "minion#{minion}"
  config.vm.define minion_id do |node|
    node.vm.provider "virtualbox" do |v|
      v.name="#{minion_id}"
      v.gui = GUI
      v.cpus = 1
    end
    node.vm.hostname = "#{minion_id}"
    node.vm.network :private_network, ip: "192.168.30.#{ip_start+minion.to_s}",
      virtualbox__intnet: "red"
    node.vm.provision "chef_solo" do |chef|
      chef.roles_path = "roles"
      chef.add_role("minion")
    end
    node.vm.provision "shell", inline: "ip route add 192.168.2.0/24 via 192.168.30.1"
  end
end

$routerscript = <<SCRIPT
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 192.168.2.1/24
set interfaces ethernet eth2 address 192.168.30.1/24
set system flow-accounting interface eth1
set system flow-accounting interface eth2
commit
save
SCRIPT

config.vm.define "vyos" do |vyos|
  vyos.vm.box = "higebu/vyos-1.0.4-amd64"
  vyos.vm.provider "virtualbox" do |v|
    v.name = "vyos_router"
    v.gui = GUI
    v.cpus = 1
  end
   vyos.vm.network :private_network, ip: "192.168.2.1", auto_config: false,
    virtualbox__intnet: "blue"
   vyos.vm.network :private_network, ip: "192.168.30.1", auto_config: false,
    virtualbox__intnet: "red"
   vyos.vm.provision "shell", inline: $routerscript, privileged: false
end
end
