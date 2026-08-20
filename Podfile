platform :ios, '16.6'
inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/SumSubstance/Specs.git'
#Source 'https://github.com/Tencent/wcdb.git'
target 'demo' do
    use_frameworks!
    # 按需打开注释，不需要的就注释掉
    pod 'YYModel'
    pod 'YYImage'
    pod 'YYWebImage'
    pod 'YYKeyboardManager'
    pod 'YYDispatchQueuePool'
    pod 'YYCategories'
    
    pod 'Aspects', '~> 1.4.1' #, :configurations => ['Debug', 'Test']
    pod 'WCDB.swift', :git => 'https://gitee.com/mirrors_Tencent/wcdb.git', :tag => 'v2.1.16'
end

target 'demoTests' do
  inherit! :search_paths
  # 不需要重复写pod，inherit! :search_paths 继承主target的pod依赖
end

target 'demoUITests' do
  inherit! :search_paths
  # 不需要重复写pod，inherit! :search_paths 继承主target的pod依赖
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 1. 强制关闭用户脚本沙盒，解决 rsync 权限错误
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      # 将 '16.6' 替换为你的项目支持的最低版本，建议设为 iOS 15.0 或更高
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.6'
    end
  end
end
