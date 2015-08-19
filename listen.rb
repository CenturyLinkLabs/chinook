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
    project = Project.new(
      name: repo_name,
      clone_url: clone_url
    )
    environment = Environment.new(
      persister: Persister.instance,
      project: project,
      name: ref,
      sha: sha
    )
    environment.find_or_create
    environment.deploy
  end
end
