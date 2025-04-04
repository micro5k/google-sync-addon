..
   SPDX-FileCopyrightText: (c) 2016 ale5000
   SPDX-License-Identifier: GPL-3.0-or-later
   SPDX-FileType: DOCUMENTATION

=========
Changelog
=========

All notable changes to this project will be documented in this file.


`Unreleased`_
-------------
- Click above to see all the changes.

`1.2.0-beta`_ - 2022-12-31
--------------------------
- Update Google Contacts Sync to 8.1.0 on recent devices (tested)
- Update Google Calendar Sync to 5.2.3 on older devices
- Add Google Calendar Sync 6.0.44 for recent devices (tested)
- Improve installation performance by verifying only the files that are really installed
- Add support for addon.d
- Improve uninstaller
- Refactored some code, now most apps can be enabled/disabled directly in the Live setup
- Add an helper script (:code:`zip-install.sh`) for the installation of the flashable zip via terminal or via ADB (recovery not needed)
- Sync setup with microG unofficial installer

`1.0.3-beta`_
-------------
- Updated Google Contacts Sync to 8.0.0 for Nougat (tested)
- Improved Google sync add-on / GApps uninstaller

`1.0.2-alpha`_
--------------
- Released sources on GitHub
- Added Google Calendar Sync for KitKat
- Changed signing process to fix a problem with Dingdong Recovery and maybe other old recoveries
- Added default permissions
- Reset permissions on dirty installations
- Temporarily disabled support for Marshmallow until the problems are fixed
- Almost complete rewrite of the installer, so the error 4 is finally gone
- Too many changes to remember

1.0.1-beta
----------
- Added support for Android 6.0 - 8.0
- Added Google Contacts Sync O
- Added Google Calendar Sync 5.2.3-99827563

1.0.0-beta
----------
- Initial release


.. _Unreleased: https://github.com/micro5k/google-sync-addon/compare/v1.2.0-beta...HEAD
.. _1.2.0-beta: https://github.com/micro5k/google-sync-addon/compare/7d869eb31a90645b742c434001df9f0ac6df0a76...v1.2.0-beta
.. _1.0.3-beta: https://github.com/micro5k/google-sync-addon/compare/572b41b384523f24028ff5c11dc898054b0b3145...7d869eb31a90645b742c434001df9f0ac6df0a76
.. _1.0.2-alpha: https://github.com/micro5k/google-sync-addon/tree/572b41b384523f24028ff5c11dc898054b0b3145
