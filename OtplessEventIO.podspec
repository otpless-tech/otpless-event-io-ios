Pod::Spec.new do |s|
  s.name             = 'OtplessEventIO'
  s.version          = '1.0.0'
  s.summary          = 'Otpless event tracking SDK for iOS.'

  s.description      = <<-DESC
                       OtplessEventIO is a lightweight event-tracking SDK for iOS apps.
                       It captures device and tracking events, persists them locally in
                       SQLite, and reliably forwards them to the Otpless events backend
                       with automatic retry for failed sends.
                       DESC

  s.homepage         = 'https://github.com/otpless-tech/otpless-event-io-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Otpless' => 'digvijay.singh@otpless.com' }
  s.source           = { :git => 'https://github.com/otpless-tech/otpless-event-io-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_versions        = ['5.5']

  s.source_files = 'Sources/OtplessEventIO/**/*.swift'

  s.frameworks = 'Foundation'
  s.libraries  = 'sqlite3'
end
