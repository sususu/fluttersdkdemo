Pod::Spec.new do |s|
  s.name             = 'HwBluetoothSDK'
  s.version          = '3.2.10'
  s.summary          = 'Local HwBluetoothSDK framework'
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Huawo' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.vendored_frameworks = 'Frameworks/HwBluetoothSDK.framework'
  s.platform         = :ios, '12.0'
  s.requires_arc     = true
end
