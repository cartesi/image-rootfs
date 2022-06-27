################################################################################
#
# txiki
#
################################################################################

TXIKI_VERSION = 22.4.1
TXIKI_SITE = $(call github,saghul,txiki.js,v$(TXIKI_VERSION))
TXIKI_INSTALL_TARGET = YES
TXIKI_DEPENDENCIES = openssl libcurl libuv
TXIKI_LICENSE = MIT
TXIKI_LICENSE_FILES = LICENSE

define TXIKI_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/tjs $(TARGET_DIR)/usr/bin/tjs
endef

$(eval $(cmake-package))
