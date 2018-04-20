#!~/.rbenv/shims/ruby

require 'optparse'
require 'yaml'
require './tenable_io.rb'


opt = OptionParser.new
OPTS = Hash.new
OPTS[:configfile] = "conf.yaml" # default value
opt.on('-c VAL', '--configfile VAL') {|v| OPTS[:configfile] = v}
opt.parse!(ARGV)

if ! OPTS[:configfile]
  print "--configfile [config YAML file] is required.\n"
  exit(1)
end

config = YAML.load_file(OPTS[:configfile])

editors = Editor.new(config)
basic_scan_uuid = String.new
editors_templates = editors.list({'type' => 'scan'})['templates']
editors_templates.each{|template|
  basic_scan_uuid = template['uuid'] if template['name'] == 'basic'
  # printf("%s\t%s\n", template['uuid'], template['name'])
}
p basic_scan_uuid

scanner_id = String.new
Scanners.new(config).list({})['scanners'].each{|scanner|
  scanner_id = scanner['id'] if scanner['name'] == 'scanner'
}
p scanner_id

scans = Scans.new(YAML.load_file(OPTS[:configfile]))

post_body_hash = {"uuid" => basic_scan_uuid, 
                  "settings" => {
                    "name" => `uuidgen`.chomp,
                    "scanner_id" => scanner_id,
                    "enabled" => "true",
                    "launch" => "ON_DEMAND",
                    "text_targets" => "133.1.25.16", 
                    "emails" => "reo@cmc.osaka-u.ac.jp", 
                  }
                 }

response = scans.create(post_body_hash)

pp response
pp response.code
response_hash = JSON.parse(response.body)['scan']
pp response_hash

scan_id = response_hash['id']
pp scan_id

response = scans.launch({"scan_id" => scan_id.to_s})
pp response
pp response.code
pp JSON.parse(response.body)

response = scans.export_request({"scan_id" => scan_id.to_s,
                      "format" => "PDF"
                     }
                    )
pp response
pp response.code
pp JSON.parse(response.body)

# response_hash = JSON.parse(response.body)['scan']
# pp response_hash
