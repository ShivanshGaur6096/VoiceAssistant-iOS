# VoiceAssistant.framework

VoiceAssistant is a powerful framework designed to enable seamless call capabilities in your iOS app with AI-Assistant. It provides an easy-to-use interface for interaction, making it simple to integrate high-quality voice communication into your project.

---

## Installation

VoiceAssistant is available through [CocoaPods](https://cocoapods.org/pods/VoiceAssistant). To install it, simply add the following line to your Podfile:

```ruby
pod 'VoiceAssistant'
```

Or, specify a specific version:

```ruby
pod 'VoiceAssistant', '~> 0.0.6'
```

Then, run:

```sh
pod install
```

---

## Publishing a New Version to CocoaPods

### Step 1: Tag the New Version
Before publishing, ensure your `.podspec` version matches your Git tag:

```sh
git tag 0.0.6
git push origin 0.0.6
```

### Step 2: Validate the Podspec

Run the following command to validate your podspec before pushing:

```sh
pod spec lint VoiceAssistant.podspec --verbose
```

If the validation fails, fix any errors and re-run the command.

### Step 3: Publish to CocoaPods

First-time users need to register their CocoaPods account:

```sh
pod trunk register shivansh.gaur@blackngreen.com "Shivansh Gaur"
```

You will receive an email—click the link to verify your account.

Once registered, publish the pod:

```sh
pod trunk push VoiceAssistant.podspec --allow-warnings
```

This makes `VoiceAssistant` available for all CocoaPods users.

---

## Updating VoiceAssistant
Whenever you update the framework, follow these steps to publish the changes:

1. **Update the version number** in `VoiceAssistant.podspec`
2. **Commit your changes** and push them to GitHub:
   ```sh
   git commit -am "Updated VoiceAssistant to version 0.0.6"
   git push origin main
   ```
3. **Tag the new version** and push it:
   ```sh
   git tag 0.0.6
   git push origin 0.0.6
   ```
4. **Validate and publish** the new version:
   ```sh
   pod spec lint VoiceAssistant.podspec --verbose
   
   pod trunk push VoiceAssistant.podspec --allow-warnings
   ```

Now, users can update to the latest version by running:

```sh
pod update VoiceAssistant
```

---

## License
VoiceAssistant is available under the MIT license. See the LICENSE file for more info.

---
