Pod::Spec.new do |s|  
    s.name              = 'ATTAnalytics'
    s.version           = '1.0.0'
    s.summary           = 'A really cool SDK for simplifying the use of differnet analytics.'
    s.homepage          = 'https://github.com/sreekanthrad/ATTAnalytics'

    s.author            = { 'Sreekanth' => 'sreekanthrad@gmail.com' }
    s.license           = { :type => 'Apache-2.0', :file => 'LICENSE' }

    s.platform          = :ios
    s.source            = { :git => 'https://github.com/sreekanthrad/ATTAnalytics.git', :tag => s.version.to_s }

    s.ios.deployment_target = '8.0'
    s.ios.vendored_frameworks = 'ATTAnalytics.framework'
    s.ios.framework  = ['CoreLocation', 'CoreData']

end 