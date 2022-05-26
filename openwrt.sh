#!/bin/bash
# http://git.home/zhangbo/openwrt

set -e
# set -x

MODE=$1 # stable dev beta
if [ -z "$MODE" ]; then
    MODE='dev'
fi

REPO=https://github.com/deplives/lede.git
FIRST_SH=first.sh
SECOND_SH=second.sh
THIRD_SH=third.sh

# not using root
# adduser openwrt
# sudo usermod -a -G sudo openwrt
#sudo chown -R openwrt:openwrt /home/openwrt
# useradd -r -m -s /bin/bash openwrt
# su - openwrt

ROOT=/home/openwrt
WORKSPACE=$ROOT/openwrt-$MODE
CONFIG=.config
CONFIG_OLD=.config.old

BACKUPCONFIG_PATH=$ROOT/config
BACKUPCONFIG_STABLE=x86.stable.config
BACKUPCONFIG_DEV=x86.dev.config
BACKUPCONFIG_BETA=x86.beta.config

BACKUPCONFIG=$BACKUPCONFIG_DEV
BRANCH='dev'
if [ "$MODE" == "stable" ]; then
    BRANCH='master'
    BACKUPCONFIG=$BACKUPCONFIG_STABLE
elif [ "$MODE" == "dev" ]; then
    BRANCH='dev'
    BACKUPCONFIG=$BACKUPCONFIG_DEV
elif [ "$MODE" == "beta" ]; then
    BRANCH='beta'
    BACKUPCONFIG=$BACKUPCONFIG_BETA
else
    echo "MODE '$MODE' ERROR! choose from 'stable' 'dev' 'beta'"
    exit -1
fi

# echo 'sync datetime...'
# sudo ntpdate ntp.ntsc.ac.cn >/dev/null 2>&1

echo 'cleanup...'
rm -rf $WORKSPACE

# echo 'install dependencies...'
# sudo apt update >/dev/null 2>&1
# sudo apt -y upgrade >/dev/null 2>&1
# sudo apt -y autoremove >/dev/null 2>&1
# sudo apt -y install $(curl -fsSL https://git.io/openwrt-ubuntu-2004) >/dev/null 2>&1

echo 'clone source code...'
git clone $REPO -b $BRANCH $WORKSPACE >/dev/null 2>&1
cd $WORKSPACE
COMMITHASH=$(git rev-parse HEAD)

echo 'run first.sh...'
cp -f $ROOT/$FIRST_SH $WORKSPACE
cd $WORKSPACE
chmod +x $FIRST_SH
./$FIRST_SH $MODE >/dev/null 2>&1

echo 'update feeds...'
cd $WORKSPACE && ./scripts/feeds update -a >/dev/null 2>&1

echo 'run second.sh...'
cp -f $ROOT/$SECOND_SH $WORKSPACE
cd $WORKSPACE
chmod +x $SECOND_SH
./$SECOND_SH $MODE $COMMITHASH >/dev/null 2>&1

echo 'install feeds...'
cd $WORKSPACE && ./scripts/feeds install -a >/dev/null 2>&1

echo 'run third.sh...'
cp -f $ROOT/$THIRD_SH $WORKSPACE
cd $WORKSPACE
chmod +x $THIRD_SH
./$THIRD_SH >/dev/null 2>&1

echo 'collecting information...'
cd $WORKSPACE/feeds/packages
PKG_REMOTE=$(git remote -v | grep fetch | awk '{print $2}')
PKG_BRANCH=$(git branch | awk '{print $2}')
cd $WORKSPACE/feeds/luci
LUCI_REMOTE=$(git remote -v | grep fetch | awk '{print $2}')
LUCI_BRANCH=$(git branch | awk '{print $2}')
cd $WORKSPACE/feeds/helloworld
HW_REMOTE=$(git remote -v | grep fetch | awk '{print $2}')
HW_BRANCH=$(git branch | awk '{print $2}')
cd $WORKSPACE/feeds/bobby
BOBBY_REMOTE=$(git remote -v | grep fetch | awk '{print $2}')
BOBBY_BRANCH=$(git branch | awk '{print $2}')

if [ -f $BACKUPCONFIG_PATH/$BACKUPCONFIG ]; then
    echo 'restore config...'
    cp -f $BACKUPCONFIG_PATH/$BACKUPCONFIG $WORKSPACE/$CONFIG
fi

echo 'run make defconfig...'
cd $WORKSPACE && make defconfig >/dev/null 2>&1
cp -f $WORKSPACE/$CONFIG $BACKUPCONFIG_PATH/$BACKUPCONFIG

echo ''
if [ -f "$WORKSPACE/$CONFIG_OLD" ]; then
    echo 'Configuration written to .config'
else
    echo 'No change to .config'
fi

printf "%100s\n" | tr " " -
printf "%-20s%-80s\n" "mode" "$MODE"
printf "%-20s%-80s\n" "repo lede" "$REPO:$BRANCH"
printf "%-20s%-80s\n" "lede commit" "$COMMITHASH"
printf "%-20s%-80s\n" "repo packages" "$PKG_REMOTE:$PKG_BRANCH"
printf "%-20s%-80s\n" "repo luci" "$LUCI_REMOTE:$LUCI_BRANCH"
printf "%-20s%-80s\n" "repo helloworld" "$HW_REMOTE:$HW_BRANCH"
printf "%-20s%-80s\n" "repo bobby" "$BOBBY_REMOTE:$BOBBY_BRANCH"
printf "%-20s%-80s\n" "workspace" "$WORKSPACE"
printf "%-20s%-80s\n" "config path" "$BACKUPCONFIG_PATH"
printf "%-20s%-80s\n" "config file" "$BACKUPCONFIG"
printf "%100s\n" | tr " " -
