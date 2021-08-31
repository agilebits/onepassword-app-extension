## Retirement

As 1Password continues to evolve on iOS we’ve been given new opportunities to take advantage of additions to the operating system that fulfill some of the functionality originally provided by our action extension. With <a href="https://developer.apple.com/documentation/security/password_autofill/">Password AutoFill</a> in iOS 12 and the addition of Safari Web Extensions in iOS 15 we have decided that going forward we will not be continuing support for this action extension. When we originally shipped this extension it provided a critical means of filling into web pages and applications on a system that was brand new for all of us. In the intervening time the landscape has changed dramatically and we feel the time has arrived to let go of this extension that served many in the community well.

## Recommendations

To provide an excellent filling experience for everyone on iOS, you will absolutely want to make use of Apple's <a href="https://developer.apple.com/documentation/xcode/supporting-associated-domains">Associated Domains</a> support to ensure that the Password Manager gets contextual information about your app when they attempt to use the system's Password AutoFill functionality. This, combined with putting the <a href="https://developer.apple.com/documentation/security/password_autofill/enabling_password_autofill_on_a_text_input_view"> correct content type tags on your fields</a>, ensures that your customers are able to both get the appropriate content displayed by their Password Manager and that when they've chosen to fill that the filled content goes to the right fields.

## Resolutions

We will continue to push to improve filling on all of the platforms we support. This includes helping Apple improve their filling solutions. If you want to participate in that process we highly recommend reading through the <a href="https://github.com/apple/password-manager-resources">Password Manager Resources project</a> and contributing energy and passion to help improve filling. 

We also realize while Password AutoFill solves many of the problems this extension was meant to solve, it doesn't currently handle all of them. We would ask that you take a look at what Password AutoFill offers and, if your use case is not served by it, that you take the opportunity to file Feedback with Apple to let them know about areas where they can improve the filling story on Password AutoFill.

Thank you for your support over the years and for adopting our filling extension. We see a bright future with Password AutoFill that will allow us to focus our energy on improving other aspects of the 1Password experience for everyone.