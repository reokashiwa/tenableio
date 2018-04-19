#!~/.rbenv/shims/ruby

require 'optparse'
require 'yaml'
require './tenable_io.rb'


opt = OptionParser.new
OPTS = Hash.new
OPTS[:configfile] = "conf.yaml"
opt.on('-c VAL', '--configfile VAL') {|v| OPTS[:configfile] = v}
opt.parse!(ARGV)

if ! OPTS[:configfile]
  print "--configfile [config YAML file] is required.\n"
  exit(1)
end

editors = Editor.new(YAML.load_file(OPTS[:configfile]))
basic_scan_uuid = String.new
editors_templates = editors.list({'type' => 'scan'})['templates']
editors_templates.each{|template|
  basic_scan_uuid = template['uuid'] if template['name'] == 'basic'
  # printf("%s\t%s\n", template['uuid'], template['name'])
}
p basic_scan_uuid

scans = Scans.new(YAML.load_file(OPTS[:configfile]))
# scans.list({})['scans'].each{|scan|
  # printf("%s\n", scan['name'])
# }

post_body_hash = {"uuid" => basic_scan_uuid, 
                  "settings" => {
                    "name" => `uuidgen`.chomp,
                    "enabled" => "true",
                    "text_targets" => "133.1.25.16"
                  }
                 }

response = scans.create(post_body_hash)
pp response
pp response.code
pp response.body

# response = scans.copy({"scan_id" => "784"})
# pp response
# pp response.code
# pp response.body
