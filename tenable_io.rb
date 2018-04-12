#!~/.rbenv/shims/ruby
# coding: euc-jp

require 'optparse'
require 'yaml'
require 'net/https'
require 'pp'
require 'json'


opt = OptionParser.new
OPTS = Hash.new
OPTS[:configfile] = "conf.yaml"
opt.on('-c VAL', '--configfile VAL') {|v| OPTS[:configfile] = v}
opt.parse!(ARGV)

if ! OPTS[:configfile]
  print "--configfile [config YAML file] is required.\n"
  exit(1)
end

CONF = YAML.load_file(OPTS[:configfile])

class TenableIO
  def initialize(conf)
    accessKey = conf[:accessKey]
    secretKey = conf[:secretKey]
    @x_apikeys = sprintf("accessKey=%s; secretKey=%s",
                         accessKey, secretKey)
    @uri = URI.parse(conf[:uri]) 
  end

  def get(path, parameter_hash)
    @uri.path = '/' + path

    if parameter_hash
      query = String.new
      parameter_hash.each{|key,value|
	query = query + sprintf("%s=%s&", key, value)
      }
      query.gsub!(/&$/,"")
      @uri.query = query
    end
    
    https = Net::HTTP.new(@uri.host, @uri.port)
    https.use_ssl = true
    result = JSON.parse(https.get(@uri.request_uri,
                          {'X-ApiKeys' => @x_apikeys}).body)[path]
  end
end

class Folders < TenableIO
  def list(parameter_hash)
    response = get('folders', parameter_hash)
  end
end

class Scanners < TenableIO
  def list(parameter_hash)
    response = get('scanners', parameter_hash)
  end
end

class Scans < TenableIO
  def list(parameter_hash)
    response = get('scans', parameter_hash)
  end
end



# sample code
tenable_io = TenableIO.new(CONF)
# folders = tenable.get_folders
# folders.each{|folder|
#   pp folder
# }
# scans = tenable.get_scans_of_folder(folders[1]['id'])
# scans.each {|scan|
#   pp scan['uuid']
# }

pp Folders.new(CONF).list(nil)
pp Scanners.new(CONF).list(nil)
pp Scans.new(CONF).list(nil)
