#!~/.rbenv/shims/ruby

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
    @uri.path = path

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
    response = JSON.parse(https.get(@uri.request_uri,
                                    {'X-ApiKeys' => @x_apikeys}).body)
  end

  def post(path, post_body_hash)
    @uri.path = path

    https = Net::HTTP.new(@uri.host, @uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(@uri.request_uri,
                               {'X-ApiKeys' => @x_apikeys,
                                'Content-Type' => 'application/json'})
    request.body = post_body_hash.to_json
    response = https.request(request)
  end
end

class Editor < TenableIO
  def list(parameter_hash)
    if ! parameter_hash['type']
      p "Editor.list must specify 'type' key and its value string as a parameter. The 'type' of templates to retrieve ('scan' or 'policy')."
      exit(1)
    end

    response = get('/editor/' + parameter_hash['type'] + '/templates', 
                   parameter_hash)
  end
end

class Folders < TenableIO
  def list(parameter_hash)
    response = get('/folders', parameter_hash)
  end
end

class Scanners < TenableIO
  def list(parameter_hash)
    response = get('/scanners', parameter_hash)
  end
end

class Scans < TenableIO
  def copy(post_body_hash)
    scan_id = post_body_hash['scan_id']
    response = post('/scans/' + scan_id + '/copy', post_body_hash)
  end

  def list(parameter_hash)
    response = get('/scans', parameter_hash)
  end

  def create(post_body_hash)
    if ! (parameter_hash['uuid'] && 
          parameter_hash['settings']['name'] &&
          parameter_hash['settings']['enabled'] &&
          parameter_hash['settings']['text_targets'])
      p ""
      exit(1)
    end

    response = post('/scans', parameter_hash, post_body_hash)
  end
end


# sample code
# editors = Editor.new(YAML.load_file(OPTS[:configfile]))
# editors_templates = editors.list({'type' => 'scan'})['templates']
# editors_templates.each{|template|
  # printf("%s\t%s\n", template['uuid'], template['name'])
# }

scans = Scans.new(YAML.load_file(OPTS[:configfile]))
# scans.list({})['scans'].each{|scan|
  # printf("%s\n", scan['name'])
# }

# post_body_hash = {"uuid" => "731a8e52-3ea6-a291-ec0a-d2ff0619c19d7bd788d6be818b65",
#                   "settings" => {
#                     "name" => `uuidgen`.chomp,
#                     "enabled" => "true",
#                     "text_targets" => "133.1.25.16"
#                   }
#                  }

# pp parameter_hash.to_json

# response = scans.create(post_body_hash)
# pp response
# pp response.code
# pp response.body

response = scans.copy({"scan_id" => "784"})
pp response
pp response.code
pp response.body
