#
# Cookbook Name:: docker
# Recipe:: default
#
# Copyright 2015, Don Mills
#
# All rights reserved - Do Not Redistribute
#

bash "install_docker" do
  code <<-EOH
  curl -sSL https://get.docker.com/ | sh
  EOH
end

cookbook_file "/etc/default/docker" do
  source node['docker']['dockerdef']
end

service "docker" do
  action :restart
end

group 'docker' do
  action :modify
  members 'vagrant'
  append true
end

link '/var/run/netns' do
  to '/var/run/docker/netns'
end
