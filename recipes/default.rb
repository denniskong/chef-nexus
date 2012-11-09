#
# Cookbook Name:: chef-nexus
# Recipe:: default
#
# Copyright 2012, Dennis Kong
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

include_recipe "java"
include_recipe "nginx"

nexus_tarball = node[:nexus][:tarball_url]
nexus_tarball_basename = ::File.basename(nexus_tarball)
local_nexus_tarball = ::File.join("/tmp", nexus_tarball_basename)
nexus_folder = ::File.basename(nexus_tarball_basename, "-bundle.tar.gz")
install_dir = node[:nexus][:install_dir]
working_dir = node[:nexus][:working_dir]
pid_dir = node[:nexus][:pid_dir]
nexus_properties_file = ::File.join(install_dir,"conf","nexus.properties")



group node[:nexus][:group] do
  system true
end

user node[:nexus][:user] do
  home "/var/lib/#{node[:nexus][:user]}"
  shell  "/bin/bash"
  gid    node[:nexus][:group]
  system true
end


remote_file local_nexus_tarball do
  source nexus_tarball
  action :create
end

bash "install_nexus" do
  cwd "/tmp"
  code <<-EOH
  tar -zxf #{local_nexus_tarball}
  mv #{nexus_folder} #{install_dir}
  chown -R #{node[:nexus][:user]}:#{node[:nexus][:group]} #{install_dir}
  EOH
  not_if "test -d #{install_dir}"
end

#TODO link /usr/local/nexus -> only if /usr/local/#{nexus_folder}

template nexus_properties_file do
  source "nexus.properties.erb"
  owner node[:nexus][:user]
  group node[:nexus][:group]
  notifies :restart, "service[nexus]", :immediately
  variables(:working_dir => working_dir)
end

directory pid_dir do
  owner node[:nexus][:user]
  group node[:nexus][:group]
  action :create
end

directory working_dir do
  owner node[:nexus][:user]
  group node[:nexus][:group]
  recursive true
  action :create
end

template "/etc/init.d/nexus" do
  mode "0755"
  variables(:nexus_home => install_dir,
            :pid_dir => pid_dir,
            :user => node[:nexus][:user])

end

service "nexus" do
  action [ :enable, :start ]
  #notifies :restart, "service[nginx]", :immediately
end

directory "/etc/nginx/certificates" do
  owner "nginx"
  group "nginx"
  mode "700"
end

bash "Create SSL Certificates" do
  cwd "/etc/nginx/certificates"
  code <<-EOH
  umask 077
  openssl genrsa 2048 > nexus-proxy.key
  openssl req -subj "#{node['nexus']['ssl_req']}" -new -x509 -nodes -sha1 -days 3650 -key nexus-proxy.key > nexus-proxy.crt
  cat nexus-proxy.key nexus-proxy.crt > nexus-proxy.pem
  EOH
  not_if { ::File.exists?("/etc/nginx/certificates/nexus-proxy.pem") }
end


template "#{node[:nginx][:dir]}/sites-available/nexus_proxy.conf" do
  source "nexus_proxy.nginx.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(
    :ssl_certificate => "/etc/nginx/certificates/nexus-proxy.crt",
    :ssl_key         => "/etc/nginx/certificates/nexus-proxy.key",
  )
end

nginx_site 'nexus_proxy.conf'
