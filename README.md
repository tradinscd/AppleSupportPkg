AppleSupportPkg
==============

[![Build Status](https://travis-ci.org/acidanthera/AppleSupportPkg.svg?branch=master)](https://travis-ci.org/acidanthera/AppleSupportPkg) [![Scan Status](https://scan.coverity.com/projects/16467/badge.svg?flat=1)](https://scan.coverity.com/projects/16467)

-----

## ApfsDriverLoader
Open source apfs.efi loader based on reverse-engineered Apple's ApfsJumpStart driver. It chain loads the apfs.efi driver that is already embedded in the APFS container from this container.

- Loads apfs.efi from APFS container located on the block device.
- Apfs driver verbose logging suppressed.
- Version system: connects each apfs.efi to the device from which it was retrieved.
- Embedded signature verification of chainloaded apfs.efi driver, what prevents possible implant injection.

## AppleImageLoader
Secure AppleEfiFat binary driver with implementation of AppleLoadImage protocol with EfiBinary signature verification.

It provides secure loading of Apple EFI binary files into memory by pre-authenticating its signature.

## AppleUiSupport
Driver which implements set of protocol for support EfiLoginUi which used for FileVault as login window. In short, it implements FileVault support and replaces AppleKeyMapAggregator.efi, AppleEvent.efi, AppleUiTheme.efi, FirmwareVolume.efi, AppleImageCodec.efi. Also, it contains hash service fixes and unicode collation for some boards. These fixes removed from AptioMemoryFix in R23.

## AppleEfiSignTool
Open source tool for verifying Apple EFI binaries. It supports ApplePE and AppleFat binaries.

## AppleDxeImageVerificationLib
This library provides Apple's crypto signature algorithm for EFI binaries.

## VBoxHfs
This driver, based on [VBoxHfs](https://www.virtualbox.org/browser/vbox/trunk/src/VBox/Devices/EFI/FirmwareNew/VBoxPkg/VBoxFsDxe) from [VirtualBox OSE](https://www.virtualbox.org) project driver, implements HFS+ support with bless extensions. Note, that unlike other drivers, its source code is licensed under GPLv2.

## Credits
- [Brad Conte](https://github.com/B-Con) for Sha256 implementation
- [Chromium OS project](https://github.com/chromium) for Rsa2048Sha256 signature verification implementation
- [cugu](https://github.com/cugu) for awesome research according APFS structure
- [Download-Fritz](https://github.com/Download-Fritz) for Apple EFI reverse-engineering
- [nms42](https://github.com/nms42) for advancing VBoxHfs driver
- [savvas](https://github.com/savvamitrofanov)
- [VirtualBox OSE project](https://www.virtualbox.org) for original VBoxHfs driver
- [vit9696](https://github.com/vit9696) for codereview and support in the development
