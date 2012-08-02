Gem::Specification.new do |gem|

  gem.name    = 'vspheremonitor'
  gem.version = '0.0.6'
  gem.date    = Date.today.to_s

  gem.summary     = "A tool to get the highlights from the Puppet Dashboard"
  gem.description = "Parses json from the various node states on puppet dashboard and returns those values in a json blob"

  gem.author   = 'Zach Leslie'
  gem.email    = 'xaque208@gmail.com'
  gem.homepage = 'https://github.com/xaque208/vspheremonitor'

  # ensure the gem is built out of versioned files
   gem.files = Dir['Rakefile', '{bin,lib}/**/*', 'etc/*.sample', 'README*', 'LICENSE*'] & %x(git ls-files -z).split("\0")

   gem.executables << 'vspheremonitor'

   gem.add_dependency('json')
   gem.add_dependency('rbvmomi')
   gem.add_dependency('alchemist')

end


