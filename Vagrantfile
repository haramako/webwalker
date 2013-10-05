# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  # config.vm.box = "base"
  config.vm.box = "ubuntu-12.04"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network :forwarded_port, guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "192.168.33.10"

  # Assign this VM to a bridged network, allowing you to connect directly to a
  # network using the host's network device. This makes the VM appear as another
  # physical device on your network.
  # config.vm.network :public_network

  # Share an additional folder to the guest VM. The first argument is
  # an identifier, the second is the path on the guest to mount the
  # folder, and the third is the path on the host to the actual folder.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding 
  # some recipes and/or roles.
  #
  config.librarian_chef.cheffile_dir = "chef"

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "./chef/cookbooks"
    chef.roles_path = "./chef/roles"
    chef.data_bags_path = "./chef/data_bags"
    
    # You may also specify custom JSON attributes:
    chef.json = { 
      mysql: {
        server_debian_password: '', 
        server_root_password: '',
        server_repl_password: ''
      },
      rbenv: {
        user_installs: [{
                          user: "vagrant",
                          rubies: ["1.9.3-p448"],
                          global: "1.9.3-p448",
                          gems: {"1.9.3-p448" => [{name: "bundler"}]}
                        }]
      },
    }

    chef.run_list = 
      [ 
       'apt',
       'git',
#       'mysql',
       'ruby_build', 
       'rbenv::user',
      ]
  end

end
