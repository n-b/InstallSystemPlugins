InstallSystemPlugins
====================

Easily install Mac OS X plugins.

>A long time ago, in System 7, one could double-click a system extension or a plugin, and the Finder would simply copy it to the correct location in the System Folder.

This tool is an attempt to recreate this.

### How does it work ?

Just [download it](https://github.com/n-b/InstallSystemPlugins/raw/master/Archive/InstallSystemPlugins.zip) and forget about it. It will launch when you double-click on a supported plugin.

### Which types of plugins can it install ?


* Color Pickers (`.colorPicker`) → `~/Library/ColorPickers/`
* QuickLook Generators (`.qlgenerator`) → `~/Library/QuickLook/`
* Xcode Snippets (`.codesnippet`) → `~/Library/Developer/Xcode/UserData/CodeSnippets/`
* Xcode Color Themes (`.dvcolortheme`) → `~/Library/Developer/Xcode/UserData/FontAndColorThemes/`
* Mail.app Plugins (`.mailbundle`) → `~/Library/Mail/Bundles/`

### Why not *XXX plugin yype* ?

Mac OS X (as of ML) correctly installs other plugins when double-clicked: 
* Preference Panels (handled by *System Preferences*)
* Screen Savers (handled by *System Preferences*)
* Automator Actions and Services (handled by *Automator*)
* Fonts (handled by *Font Book*)
* Widgets (handled by *Widget Installer* - it’s in Dock.app)
* Safari extensions (handled by *Safari*)

### Why not Internet plugins ?

It’s 2013.

### Why not Quicktime plugins ?

See previous answer.

### Why not *XXX plugin type* ?

I don’t know. If you think it should, [ask me](https://github.com/n-b/InstallSystemPlugins/issues).

---

A few great plugins sources :

* Quick Look Plugins : 
	* http://www.quicklookplugins.com
	* http://www.qlplugins.com
* Xcode Snippets
	* https://github.com/n-b/Xcode-Snippets
	* http://www.icodeblog.com/2011/12/06/using-xcode-4-snippets/
	* https://github.com/scelis/Xcode-CodeSnippets
* Xcode color themes
	* http://amychr.wordpress.com/2011/06/05/xcode-color-themes/
	* http://nearthespeedoflight.com/article/xcode_4_colour_themes
* Color Pickers :
	* [DeveloperColorPicker](http://panic.com/~wade/picker/)
	* [HexColorPicker](http://wafflesoftware.net/hexpicker/)
