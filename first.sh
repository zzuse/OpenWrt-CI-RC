#!/bin/bash
# https://github.com/deplives/OpenWrt-CI

# Run after clone lede

# Delete defalut luci-app-ipsec-server
echo 'Delete defalut luci-app-ipsec-server...'
rm -rf package/lean/luci-app-ipsec-server
