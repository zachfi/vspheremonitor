Gem::Specification.new do |gem|

  gem.name    = 'vspheremonitor'
  gem.version = '0.1.0'
  gem.date    = Date.today.to_s

  gem.summary     = "A tool to get some basic statistics out of a vSphere installation."
  gem.description = "Collects host and cluster metrics from vsphere and outputs json"

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


