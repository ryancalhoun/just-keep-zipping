Gem::Specification.new {|s|
  s.name = 'just-keep-zipping'
  s.version = '0.0.2'
  s.licenses = ['MIT']
  s.summary = 'Just Keep Zipping'
  s.description = 'Produce a zip archive from a large number of parts, in smaller batches.'
  s.homepage = 'https://github.com/ryancalhoun/just-keep-zipping'
  s.authors = ['Ryan Calhoun']
  s.email = ['ryanjamescalhoun@gmail.com']
  
  s.files = Dir["{lib}/**/*"] + %w(LICENSE README.md)

  s.add_runtime_dependency 'rubyzip', '~> 1.2'
}
