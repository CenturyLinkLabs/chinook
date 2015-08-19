class Project

  def initialize(name:, clone_url:)
    @name = name
    @clone_url = clone_url
  end

  attr_reader :name


  def in_directory(&block)
    Dir.chdir "projects/#{@name}"
    yield
    Dir.chdir '../..'
  end

  def clone
    Dir.chdir 'projects'
    `git clone #{@clone_url} #{@name}`
    Dir.chdir '../'
  end

  private
end
