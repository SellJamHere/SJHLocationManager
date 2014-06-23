Pod::Spec.new do |s|
  s.name          = 'SJHLocationManager'
  s.version       = '0.0.3'
  s.summary       = 'A location manager that handles regions through GPS location.'
  s.homepage      = 'https://github.com/SellJamHere/SJHLocationManager'
  s.license       = 'MIT'
  s.author        = { 'James Heller' => 'jaheller5@gmail.com' }
  s.source        = { :git => 'https://github.com/SellJamHere/SJHLocationManager.git', :tag => '0.0.3' }
  s.requires_arc  = true

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'

  s.source_files = 'SJHLocationManager'
  s.public_header_files = 'SJHLocationManager/*.h'
  
  s.framework = 'CoreLocation'

end
