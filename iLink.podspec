Pod::Spec.new do |s|
  s.name     = 'iLink'
  s.version  = '1.0.5'
  s.license  = 'zlib'
  s.summary  = 'A handy class that create links needed to app store etc. Can also prompts users to update your application if there is a new version.'
  s.homepage = 'https://github.com/sidan5/iLink'
  s.authors  = 'Idan S'
  s.source   = { :git => 'https://github.com/sidan5/iLink.git', :tag => '1.0.5' }
  s.source_files = 'iLink/iLink.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.7'
  s.prefix_header_contents = ''
end
