require 'yaml'

class Environment
  def initialize(persister:, project:nil, name:)
    @persister = persister
    @project = project
    @name = name
  end

  def find_or_create(sha)
    puts 'DOIN WORK'
    @project.clone
    @project.in_directory do
      `git checkout #{sha}`
    end
    puts 'about to provision...'
    provision_machine
  end

  def provision_machine
    if @persister.exists?(@name)
      puts "using existing machine: #{@name}"
    else
      puts "creating #{@name}...\n"
      create
      save
    end
    set_env
  end

  def create
    #TODO: make this not specific to DO
    `docker-machine create --driver digitalocean --digitalocean-access-token #{ENV['DO_TOKEN']} #{@name}`
  end

  def save
    puts "machine created, setting envs...\n"
    env_lines = `docker-machine env #{@name}`
    env = {}
    env_lines.each_line do |line|
      k, v = line.to_s.gsub("export ", "").strip.split("=")
      if k && v 
        env[k]=YAML.load(v)
      end
    end
    props = { 
      env: env,
      created_at: Time.now
    }
    @persister.write(@name, props)
  end

  def set_env
    puts "switching env vars to #{@name}'s"
    props = @persister.read(@name)
    props['env'].each do |k,v|
      ENV[k] = v
    end
  end

  def deploy
    puts "deploying... to #{ENV['DOCKER_HOST']}"
    @project.in_directory do
      `docker-compose up -d`
    end
    puts "done deploying...\n\n"
  end

  def delete
    `docker-machine kill #{@name}`
    `docker-machine rm -f #{@name}`
    Persister.instance.delete(@name)
  end
end
