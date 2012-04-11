#
# Author:: Cary Penniman (<cary@rightscale.com>)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provides "rackspace"

require 'ohai/mixin/cloud'

require_plugin "kernel"
require_plugin "network"

extend Ohai::Mixin::Cloud

# Checks for matching rackspace kernel name
#
# === Return
# true:: If kernel name matches
# false:: Otherwise
def has_rackspace_kernel?
  kernel[:release].split('-').last.eql?("rscloud")
end

# Checks for matching rackspace arp mac
#
# === Return
# true:: If mac address matches
# false:: Otherwise
def has_rackspace_mac?
  network[:interfaces].values.each do |iface|
    unless iface[:arp].nil?
      return true if iface[:arp].value?("00:00:0c:07:ac:01") or iface[:arp].value?("00:00:0c:9f:f0:01")
    end
  end
  false
end

# Identifies the rackspace cloud
#
# === Return
# true:: If the rackspace cloud can be identified
# false:: Otherwise
def looks_like_rackspace?
  cloud_file?('rackspace') || has_rackspace_mac? || has_rackspace_kernel?
end

# Names rackspace ip address
#
# === Parameters
# name<Symbol>:: Use :public_ip or :private_ip
# eth<Symbol>:: Interface name of public or private ip
def get_ip_address(name, eth)
  network[:interfaces][eth][:addresses].each do |key, info|
    rackspace[name] = key if info['family'] == 'inet'
  end
end

# Adds rackspace Mash
if looks_like_rackspace?
  rackspace Mash.new
  get_ip_address(:public_ip, :eth0)
  get_ip_address(:private_ip, :eth1)
  # public_ip + private_ip are deprecated in favor of public_ipv4 and local_ipv4 to standardize.
  rackspace[:public_ipv4] = rackspace[:public_ip]
  rackspace[:public_hostname] = "#{rackspace[:public_ip].gsub('.','-')}.static.cloud-ips.com"
  rackspace[:local_ipv4] = rackspace[:private_ip]
  rackspace[:local_hostname] = hostname
end
