require 'singleton'
require 'json'
require 'redis'

class Persister
  include Singleton

  def initialize
    @redis = Redis.new(:host => "0.0.0.0", :port => 6379, :db => 15)
  end

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
