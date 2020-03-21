include $(TOPDIR)/rules.mk

PKG_NAME:=iptmon
PKG_VERSION:=0.0.1
PKG_RELEASE:=1
PKG_MAINTAINER:=Jordan Sokolic <oofnik@gmail.com>

PKG_SOURCE_PROTO=git
PKG_SOURCE_URL:=https://github.com/oofnikj/iptmon
PKG_SOURCE_DATE:=2020-03-20
PKG_SOURCE_VERSION:=v0.0.1


include $(INCLUDE_DIR)/package.mk

define Package/iptmon
	SECTION:=net
	CATEGORY:=Network
	TITLE:=simple iptables-based network bandwidth monitor
	DEPENDS:=+luci-app-statistics +collectd-mod-iptables +dnsmasq
	MAINTAINER:=$(PKG_MAINTAINER)
	URL:=https://github.com/oofnikj/iptmon
	PKGARCH:=all
endef

define Package/iptmon/description
	iptmon is a script used to create and update 
	iptables firewall rules to count transmit 
	and recieve traffic to/from each host.
endef

define Package/iptmon/conffiles
	/etc/collectd/conf.d/iptables.conf
	/etc/dnsmasq.d/iptmon.conf
endef

define Build/Compile
endef

define Package/iptmon/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/sbin/iptmon $(1)/usr/sbin/iptmon
	$(INSTALL_DIR) $(1)/etc/collectd/conf.d
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/etc/collectd/conf.d/iptables.conf $(1)/etc/collectd/conf.d/iptables.conf
	$(INSTALL_DIR) $(1)/etc/dnsmasq.d
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/etc/dnsmasq.d/iptmon.conf $(1)/etc/dnsmasq.d/iptmon.conf
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/statistics/rrdtool/definitions
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/usr/lib/lua/luci/statistics/rrdtool/definitions/ip6tables.lua $(1)/usr/lib/lua/luci/statistics/rrdtool/definitions/ip6tables.lua
endef

define Package/iptmon/postinst
	#!/bin/sh
	## dnsmasq configuration
	uci set dhcp.@dnsmasq[0].dhcpscript=/usr/sbin/iptmon
	uci set dhcp.@dnsmasq[0].confdir=/etc/dnsmasq.d/
	uci commit
	/etc/init.d/dnsmasq restart
  ## firewall configuration
	echo '/usr/sbin/iptmon init' >> /etc/firewall.user
	/etc/init.d/firewall restart
  ## luci_statistics/collectd configuration
	uci set luci_statistics.collectd.Include='/etc/collectd/conf.d'
	uci commit
	/etc/init.d/luci_statistics restart
	rm -rf /tmp/luci-modulecache/
endef

define Package/iptmon/postrm
	#!/bin/sh
	uci set dhcp.@dnamsasq[0].dhcpscript=''
	uci commit
	/etc/init.d/dnsmasq restart
	sed -i 's@/usr/sbin/iptmon init@@g' /etc/firewall.user
	/etc/init.d/firewall restart
	/etc/init.d/luci_statistics restart
	rm -rf /tmp/luci-modulecache/
endef

	

# This command is always the last, it uses the definitions and variables we give above in order to get the job done
$(eval $(call BuildPackage,iptmon))
