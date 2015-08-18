require 'sinatra'
require 'json'
require 'pp'
require 'pry'
require 'yaml'

set :bind, '0.0.0.0'

get '/hi' do
  "HI THERE"
end

post '/pr' do
  puts "-------------------------"
  res = JSON.parse(request.body.read)
  pp res
  puts "action: #{res['action']}"
  puts "SHA: #{res['pull_request']['head']['sha']}"
  puts "REF: #{res['pull_request']['head']['ref']}"
  puts "CLONE URL: #{res['pull_request']['head']['repo']['git_url']}"
  puts "REPO NAME: #{res['pull_request']['head']['repo']['name']}"
  puts "-------------------------"

  action = res['action']
  clone_url = res['pull_request']['head']['repo']['git_url']
  repo_name = res['pull_request']['head']['repo']['name']
  sha = res['pull_request']['head']['sha']

  if %w(opened reopened).include?(action)
    puts 'DOIN WORK'
    `mkdir projects`
    Dir.chdir 'projects'
    `git clone #{clone_url} #{repo_name}`
    Dir.chdir repo_name
    `git checkout #{sha}`
    machine_name = "zazzle" # todo allow_name_to_be_configurable
    puts 'about to provision...\n'
    provision_machine(machine_name)
    build_and_run
  end
end

def build_and_run
  puts "deploying... to #{ENV['DOCKER_HOST']}"
  `docker-compose up -d`
  puts "done deploying...\n\n"
end

def provision_machine(machine_name)
  if name = ENV['DOCKER_MACHINE_NAME'].to_s.empty?
    puts "creating #{machine_name}...\n"
    `docker-machine create --driver digitalocean --digitalocean-access-token #{ENV['DO_TOKEN']} #{machine_name}`
  else
    puts "using existing machine: #{ENV['DOCKER_MACHINE_NAME']}"
  end
  #TODO: clean up 
  puts "machine created, setting envs...\n"
  env_lines = `docker-machine env #{machine_name}`
  env_lines.each_line do |line|
    k, v = line.to_s.gsub("export ", "").strip.split("=")
    if k && v 
      ENV[k]=YAML.load(v)
    end
  end
  binding.pry
end
