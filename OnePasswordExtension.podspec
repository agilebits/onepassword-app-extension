
Pod::Spec.new do |s|

  s.name         = "OnePasswordExtension"
  s.version      = "1.0."
  s.summary      = "With just a few lines of code, your app can add 1Password support."

  s.description  = <<-DESC
                   With just a few lines of code, your app can add 1Password support, enabling your users to:

                  - Access their 1Password Logins to automatically fill your login page.
                  - Use the Strong Password Generator to create unique passwords during registration, and save the new Login within 1Password.
                  - Quickly fill 1Password Logins directly into web views.

                   Empowering your users to use strong, unique passwords has never been easier.
                   DESC

  s.homepage     = "https://github.com/AgileBits/onepassword-app-extension"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  #s.license      = "MIT (example)"

  s.authors              = { "Dave Teare", "Michael Fey", "Rad Azzouz", "Roustem Karimov" }
  s.social_media_url   = "https://twitter.com/1PasswordBeta"

  s.source       = { :git => "https://github.com/AgileBits/onepassword-app-extension.git", :tag => s.version }

  s.source_files  = "*.{h,m}"
  s.exclude_files = "Demos"
  s.resources = "1Password.xcassets/*.*"
end
