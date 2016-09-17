# Uncomment this line to define a global platform for your project
# platform :ios, ‘9.0’
# Uncomment this line if you're using Swift
# use_frameworks!

xcodeproj ‘FlowerCards.xcodeproj'
workspace ‘FlowerCards.xcworkspace'
platform :ios, ‘9.0’

source 'https://github.com/artsy/Specs.git'
source 'https://github.com/CocoaPods/Specs.git'


def shared_pods
      pod 'RealmSwift', '>= 0.92.3'
end
use_frameworks!

target 'FlowerCards' do
shared_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '2.3' # or '3.0'
        end
    end
end
# target 'FlowerCardsTests' do
# shared_pods
# end

# target 'FlowerCardsUITests' do
# shared_pods
# end



