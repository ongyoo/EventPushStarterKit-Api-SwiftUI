# Day-to-day commands. Run `make` to see them.

SIMULATOR ?= iPhone 16 Pro
DESTINATION = platform=iOS Simulator,name=$(SIMULATOR)

.PHONY: help feature scene project templates strings lint test coverage size build open clean android android-run android-test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  make %-10s %s\n", $$1, $$2}'

feature: ## New feature folder: make feature NAME=Profile [UI=uikit]
	@scripts/new-feature.sh $(NAME) $(if $(filter uikit,$(UI)),--uikit,)

scene: ## New screen in a feature: make scene FEATURE=Profile NAME=EditProfile [UI=uikit]
	@scripts/new-scene.sh $(FEATURE) $(NAME) $(if $(filter uikit,$(UI)),--uikit,)

project: ## New app from this kit: make project NAME=ShopApp BUNDLE=com.acme.shop DEST=~/Projects [TEAM=ABCDE12345]
	@scripts/new-project.sh $(NAME) $(BUNDLE) $(DEST) $(TEAM)

templates: ## Install Xcode file templates (File > New > File > VIPER)
	@scripts/install-xcode-templates.sh

strings: ## Regenerate String Catalogs from scripts/strings.py
	@python3 scripts/strings.py

lint: ## Crash-safety lint + layer dependency check
	@scripts/lint.sh

test: ## Run every unit test (app modules + LiquidGlassKit + ServerDrivenUI)
	cd Modules && xcodebuild test -scheme Modules-Package -destination '$(DESTINATION)' -quiet
	cd Packages/LiquidGlassKit && xcodebuild test -scheme LiquidGlassKit -destination '$(DESTINATION)' -quiet
	cd Packages/ServerDrivenUI && xcodebuild test -scheme ServerDrivenUI -destination '$(DESTINATION)' -quiet

coverage: ## Tests + per-layer coverage report (MIN_LOGIC_COVERAGE=95 to enforce)
	@scripts/coverage.sh "$(SIMULATOR)"

size: ## Release app size report (MAX_DOWNLOAD_KB=3000 to enforce a budget)
	@scripts/app-size.sh

build: ## Build the app
	xcodebuild -project EventPushStarterKit.xcodeproj -scheme EventPushStarterKit -destination '$(DESTINATION)' -quiet build

open: ## Open the project in Xcode
	open EventPushStarterKit.xcodeproj

android: ## Swift-on-Android demo: build Swift + debug APK (docs/SWIFT_ANDROID.md)
	cd Android && JAVA_HOME="$${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}" ./gradlew assembleDebug -q

android-run: android ## Install and launch the Android demo on the running emulator/device
	$${ANDROID_HOME:-$$HOME/Library/Android/sdk}/platform-tools/adb install -r Android/app/build/outputs/apk/debug/app-debug.apk
	$${ANDROID_HOME:-$$HOME/Library/Android/sdk}/platform-tools/adb shell am start -n com.eventpush.android/.MainActivity

android-test: ## Test the Swift logic shared with Android (runs on the Mac)
	cd Android/SwiftCore && swift test

clean: ## Remove local build output
	rm -rf .build Modules/.build Android/SwiftCore/.build Android/app/build
