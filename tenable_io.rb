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
                          {'X-ApiKeys' => @x_apikeys}).body)
  end
end

class Editor < TenableIO
  def list(parameter_hash)
    if ! parameter_hash['type']
      p "Editor.list must specify 'type' string as The 'type' of templates to retrieve ('scan' or 'policy')."
      exit(1)
    end

    response = get('editor/' + parameter_hash['type'] + '/templates', 
                   parameter_hash)
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
pp Editor.new(YAML.load_file(OPTS[:configfile])).list({'type' => 'scan'})
