require 'sinatra'
require 'json'
require 'haml'
require 'pp'
require 'pry'
require 'yaml'
require 'redis'
require 'json'
require 'singleton'

set :bind, '0.0.0.0'

get '/dashboard' do
  @envs = Persister.instance.list
  haml :dashboard
end

post '/gh-hook' do
  res = JSON.parse(request.body.read)
  action = res['action']
  ref = res['pull_request']['head']['ref']
  clone_url = res['pull_request']['head']['repo']['git_url']
  repo_name = res['pull_request']['head']['repo']['name']
  sha = res['pull_request']['head']['sha']

  puts "-------------------------"
  #pp res
  puts "action: #{action}"
  puts "SHA: #{sha}"
  puts "REF: #{ref}"
  puts "CLONE URL: #{clone_url}"
  puts "REPO NAME: #{repo_name}"
  puts "-------------------------"

  if %w(opened reopened).include? action
    machine_name = ref # TODO: concat this with repo_name to make unique
    possibly_create_environment_then_definitely_deploy(machine_name, clone_url, repo_name, sha)
  end
end

private

def possibly_create_environment_then_definitely_deploy(machine_name, clone_url, repo_name, sha)
    puts 'DOIN WORK'
    `mkdir projects`
    Dir.chdir 'projects'
    `git clone #{clone_url} #{repo_name}`
    Dir.chdir repo_name
    `git checkout #{sha}`
    puts 'about to provision...\n'
    provision_machine(machine_name)
    build_and_run
    Dir.chdir '../../'
end

def build_and_run
  puts "deploying... to #{ENV['DOCKER_HOST']}"
  `docker-compose up -d`
  puts "done deploying...\n\n"
end

def provision_machine(machine_name)
  persister = Persister.instance
  if persister.exists?(machine_name)
    puts "using existing machine: #{machine_name}"
  else
    puts "creating #{machine_name}...\n"
    machine_create(machine_name)
    save(machine_name)
  end
  set_env_for(machine_name)
end

def save(machine_name)
  puts "machine created, setting envs...\n"
  env_lines = `docker-machine env #{machine_name}`
  env = {}
  env_lines.each_line do |line|
    k, v = line.to_s.gsub("export ", "").strip.split("=")
    if k && v 
      env[k]=YAML.load(v)
    end
  end
  props = { env: env }
  Persister.instance.write(machine_name, props)
end

def delete(machine_name)
  `docker-machine kill #{machine_name}`
  `docker-machine rm -f #{machine_name}`
  Persister.instance.delete(machine_name)
end

def set_env_for(machine_name)
  puts "switching env vars to #{machine_name}'s"
  props = Persister.instance.read(machine_name)
  props['env'].each do |k,v|
    ENV[k] = v
  end
end

def machine_create(name)
  #TODO: make this not specific to DO
  `docker-machine create --driver digitalocean --digitalocean-access-token #{ENV['DO_TOKEN']} #{name}`
end

class Persister
  include Singleton
  extend Forwardable

  def initialize
    @redis = Redis.new(:host => "0.0.0.0", :port => 6379, :db => 15)
  end

  #def_delegators :@redis, :exists

  #alias_method :exists?, :exists

  def exists?(k)
    @redis.exists(k)
  end

  def list
    @redis.keys.each_with_object({}) do |k, h|
      h[k] = read(k)
    end
  end

  def write(k,v)
    @redis.set(k, v.to_json)
  end

  def read(k)
    JSON.parse(@redis.get(k))
  end
end
