InstallSystemPlugins
====================

>A long time ago, in System 7, one could double-click a system extension or a plugin, and the Finder would simply copy it to the correct location in the System Folder.
>This tool is an attempt to recreate this.
>
>The icon is the color version of the “Happy Mac” by Susan Kare.

What files types does it handle ?
=================================

* Color Pickers (`.colorPicker,` -> `~/Library/ColorPickers/`)
* QuickLook Generators (`.qlgenerator` -> `~/Library/QuickLook/`)
* Xcode Snippets (`.codesnippet` -> `~/Library/Developer/Xcode/UserData/CodeSnippets/`)
* Xcode Color Themes (`.dvcolortheme` -> `~/Library/Developer/Xcode/UserData/FontAndColorThemes/`)
* Mail.app Plugins (`.mailbundle` -> `~/Library/Mail/Bundles/`)

Why not <Some other plugin type> ?
==================================

Mac OS X (as of ML) correctly installs other plugins when double-clicked: 
* Preference Panels (handled by *System Preferences*)
* Screen Savers (handled by *System Preferences*)
* Automator Actions and Services (handled by *Automator*)
* Fonts (handled by *Font Book*)
* Widgets (handled by *Widget Installer* - it’s in Dock.app)
* Safari extensions (handled by *Safari*)

Why not Internet Plugins ?
==========================

It’s 2013.

Why not Quicktime Plugins ?
===========================

See previous answer.

Why not <Some other plugin type> ?
==================================

I may have
Well, [ask me.](https://github.com/n-b/InstallSystemPlugins/issues)
