require 'net/https'
require 'pp'
require 'json'

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
    if ! (post_body_hash['uuid'] && 
          post_body_hash['settings']['name'] &&
          post_body_hash['settings']['enabled'] &&
          post_body_hash['settings']['text_targets'])
      p ""
      exit(1)
    end

    response = post('/scans', post_body_hash)
  end

  def launch(post_body_hash)
    if ! post_body_hash['scan_id']
      p "scan_id is required."
      exit(1)
    end

    response = post('/scans/' + post_body_hash['scan_id'] + '/launch',
                    post_body_hash)
  end

  def export_request(post_body_hash)
    if ! (post_body_hash['scan_id'] &&
          post_body_hash['format'])
      p "scan_id and format is required."
      exit(1)
    end

    response = post('/scans/' + post_body_hash['scan_id']+ '/export',
                    post_body_hash)
  end
end


