class GistTestClass
  def self.hello_world
    10.times do
      puts "Hello World!"
    end
  end

  def hello_world
    10.times do
      puts "Hello World!"
    end
  end
end

# execute the defined methods as part of your gist
GistTestClass.hello_world
GistTestClass.new.hello_world
