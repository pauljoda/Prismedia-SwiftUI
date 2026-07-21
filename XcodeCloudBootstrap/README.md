# Xcode Cloud bootstrap

This dependency-free project exists only to work around Xcode 27 beta's first-
workflow assistant incorrectly requiring GitHub App installation on every public
Swift package dependency owner. It uses Prismedia's bundle identifier so the
repository and App Store Connect product can be initialized without granting
access to third-party repositories.

After the first Xcode Cloud build enables workflow management in App Store
Connect, create the real Xcode 26 workflows for `../Prismedia.xcodeproj`, disable
the bootstrap workflow, and remove this directory.
