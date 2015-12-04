#
# Cookbook Name:: etcd2
# Recipe:: default
#
# Copyright 2015, Don Mills
#
# All rights reserved - Do Not Redistribute
#
bash 'unzip_etcd' do
  cwd '/tmp'
  code <<-EOH
  tar -zxvf /tmp/etcd2.tar.gz
  mv ./etcd-v2.2.2-linux-amd64/etcd* /usr/local/bin/
  EOH
  action :nothing
end

remote_file '/tmp/etcd2.tar.gz' do
  source 'https://github.com/coreos/etcd/releases/download/v2.2.2/etcd-v2.2.2-linux-amd64.tar.gz'
  action :create
  notifies :run, 'bash[unzip_etcd]', :immediately
end

directory '/var/etcd' do
  owner 'root'
  group 'root'
  action :create
end

cookbook_file '/etc/init/etcd.conf' do
  source 'etcd.conf'
  action :create
end

cookbook_file '/etc/default/etcd' do
  source node['etcd']['deffile']
  action :create
end

service "etcd" do
  action :start
end
