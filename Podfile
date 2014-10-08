target "OAuth2Client.framework" do

end

target "OAuth2Client" do
platform :ios, "4.3" #that shit cray!

end

target "OAuth2ClientTests" do
  platform :ios, "5.0"

  pod 'Specta',      '~> 0.2'
  pod 'Expecta',     '~> 0.3'
  pod 'OCMock',      '~> 3.1'
  pod 'OHHTTPStubs', '~> 3.1'


  post_install do |installer|

  	# fixing Specta for Xcode 6
  	# http://stackoverflow.com/a/25078857/25724
  	puts "Fixing Specta pod for Xcode 6"
    target = installer.project.targets.find { |t| t.to_s == "Pods-OAuth2ClientTests-Specta" }
    if (target)
        target.build_configurations.each do |config|
            s = config.build_settings['FRAMEWORK_SEARCH_PATHS']
            s = [ '$(inherited)' ] if s == nil;
            s.push('$(PLATFORM_DIR)/Developer/Library/Frameworks')
            config.build_settings['FRAMEWORK_SEARCH_PATHS'] = s
        end
    else
        puts "WARNING: Pods-OAuth2ClientTests-Specta target not found"
    end
  end
end

