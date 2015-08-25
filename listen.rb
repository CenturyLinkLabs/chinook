require_relative 'persister'
require_relative 'project'
require_relative 'environment'
require 'sinatra'
require 'haml'

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
    create_and_deploy(repo_name, clone_url, ref, sha)
  end
end

post '/environment/delete/:name' do |name|
    environment = Environment.new(
      persister: Persister.instance,
      name: name
    )
    environment.delete
end

get '/environment/refresh/:name' do |name|
    environment = Environment.new(
      persister: Persister.instance,
      name: name
    )
    environment.save
end

private

def create_and_deploy(repo_name, clone_url, ref, sha)
    project = Project.new(
      name: repo_name,
      clone_url: clone_url
    )
    environment = Environment.new(
      persister: Persister.instance,
      project: project,
      name: ref
    )
    environment.find_or_create(sha)
    environment.deploy
end
