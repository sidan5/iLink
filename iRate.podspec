Pod::Spec.new do |s|
  s.name     = 'iLink'
  s.version  = '1.0'
  s.license  = 'zlib'
  s.summary  = 'A handy class that create the links needed for the app page, developer profile or rating for iOS or Mac. The class also prompts users of your iPhone or Mac App Store app to update your application if there is a new version.'
  s.homepage = 'https://github.com/sidan5/iLink'
  s.authors  = 'Idan S'
  s.source   = { :git => 'https://github.com/sidan5/iLink.git', :tag => '1.0' }
  s.source_files = 'iLink/iLink.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '4.3'
  s.osx.deployment_target = '10.6'
end
