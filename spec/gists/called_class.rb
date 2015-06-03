class GistTestClass
  def self.gist_testing
    10.times do
      puts "Hello"
    end
  end

  def gist_testing
    10.times do
      puts "Hello"
    end
  end
end

GistTestClass.gist_testing
GistTestClass.new.gist_testing
