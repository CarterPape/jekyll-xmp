require_relative "lib/jekyll-xmp/version"

Gem::Specification.new do |spec|
    spec.name          = "jekyll-xmp"
    spec.version       = Jekyll::XMP::VERSION
    spec.authors       = ["Carter Pape"]
    spec.email         = ["jekyll-xmp@carterpape.com"]
    spec.summary       = "A Jekyll plugin for extracting image metadata"
    spec.homepage      = "https://github.com/carterpape/jekyll-xmp"
    spec.license       = "GPL-3.0-or-later"
    
    spec.files              = Dir["lib/**/*"]
    spec.extra_rdoc_files   = Dir["README.md", "LICENSE"]
    spec.require_paths      = ["lib"]
    
    spec.add_dependency "jekyll"
    spec.add_dependency "xmpr"
    spec.add_dependency "classifier-reborn"
    spec.add_dependency "nokogiri"
    spec.add_dependency "webrick"
end
