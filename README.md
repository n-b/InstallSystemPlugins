InstallSystemPlugins
====================

Easily install Mac OS X plugins.

>A long time ago, in System 7, one could double-click a system extension or a plugin, and the Finder would simply copy it to the correct location in the System Folder.

This tool is an attempt to recreate this.

Which types of plugins can it install ?
---------------------------------------

* Color Pickers (`.colorPicker`) → `~/Library/ColorPickers/`
* QuickLook Generators (`.qlgenerator`) → `~/Library/QuickLook/`
* Xcode Snippets (`.codesnippet`) → `~/Library/Developer/Xcode/UserData/CodeSnippets/`
* Xcode Color Themes (`.dvcolortheme`) → `~/Library/Developer/Xcode/UserData/FontAndColorThemes/`
* Mail.app Plugins (`.mailbundle`) → `~/Library/Mail/Bundles/`

Why not *XXX plugin yype* ?
---------------------------

Mac OS X (as of ML) correctly installs other plugins when double-clicked: 
* Preference Panels (handled by *System Preferences*)
* Screen Savers (handled by *System Preferences*)
* Automator Actions and Services (handled by *Automator*)
* Fonts (handled by *Font Book*)
* Widgets (handled by *Widget Installer* - it’s in Dock.app)
* Safari extensions (handled by *Safari*)

Why not Internet plugins ?
--------------------------

It’s 2013.

Why not Quicktime plugins ?
---------------------------

See previous answer.

Why not *XXX plugin type* ?
---------------------------

I don’t know. If you think it should, [ask me](https://github.com/n-b/InstallSystemPlugins/issues).
