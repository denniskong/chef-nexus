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

nexus_tarball = "http://www.sonatype.org/downloads/nexus-2.2-01-bundle.tar.gz"
nexus_tarball_basename = ::File.basename(nexus_tarball)
local_nexus_tarball = ::File.join("/tmp", nexus_tarball_basename)
nexus_folder = ::File.basename(nexus_tarball_basename, "-bundle.tar.gz")

remote_file local_nexus_tarball do
  action :create
end

bash "install_nexus" do
  cwd "/tmp"
  code <<-EOH
  tar -zxf #{local_nexus_tarball}
  mv #{nexus_folder} /usr/lcoal
  EOH
end

#TODO link /usr/local/nexus -> only if /usr/local/#{nexus_folder}

