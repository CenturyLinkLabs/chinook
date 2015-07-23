require 'sinatra'
require 'json'
require 'pp'

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
  puts "CLONE URL: #{res['pull_request']['head']['repo']['clone_url']}"
  puts "REPO NAME: #{res['pull_request']['head']['repo']['name']}"
  puts "-------------------------"

  action = res['action']
  clone_url = res['pull_request']['head']['repo']['clone_url']
  repo_name = res['pull_request']['head']['repo']['name']
  sha = res['pull_request']['head']['sha']

  if action == 'opened'
    puts 'DOIN WORK'
    `mkdir projects`
    Dir.chdir 'projects'
    `git clone #{clone_url} #{repo_name}`
    Dir.chdir repo_name
    `git checkout #{sha}`
  else
    puts 'DO NOTHING'
  end
end
