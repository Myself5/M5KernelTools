#!/bin/bash
version=$1
device=$2
device_common=$3
permissive=$4
android_version="L"
folder="cm12_1"

if [ -z $permissive ]; then
  permissive=false
fi

set -e

rm -rf AnyKernel2/system
rm -rf AnyKernel2/modules
rm -rf AnyKernel2/patch
mkdir -p AnyKernel2/system/etc
mkdir -p AnyKernel2/modules
mkdir -p AnyKernel2/patch
mkdir -p RELEASE/$device
rm -f AnyKernel2/M5Installer.sh
rm -f AnyKernel2/kernel
rm -f AnyKernel2/dt.img
cp ../$folder/device/sony/$device/thermanager.xml AnyKernel2/system/etc/thermanager.xml
cp ../$folder/device/sony/$device_common/rootdir/fstab.qcom AnyKernel2/patch/fstab.qcom
cp ../$folder/device/sony/msm8974-common/boot/init.sh AnyKernel2/patch/init.sh
cp -r ../$folder/out/target/product/$device/kernel AnyKernel2/zImage
cp -r ../$folder/out/target/product/$device/dt.img AnyKernel2/dt.img
cp -r ../$folder/out/target/product/$device/system/lib/modules AnyKernel2/

case $device in
    amami)
        # export assets_line='assert(getprop("ro.product.device") == "D5503" || getprop("ro.build.product") == "D5503" || getprop("ro.product.device") == "amami" || getprop("ro.build.product") == "amami" || getprop("ro.product.device") == "anami" || getprop("ro.build.product") == "anami" || abort("This package is for device: D5503,amami,anami; this device is " + getprop("ro.product.device") + "."););'
        device1="D5503"
        device2="amami"
        device3="anami"
        device4=""
        device5=""
    ;;
    sirius)
        # export assets_line='assert(getprop("ro.product.device") == "D6502" || getprop("ro.build.product") == "D6502" || getprop("ro.product.device") == "D6503" || getprop("ro.build.product") == "D6503" || getprop("ro.product.device") == "D6506" || getprop("ro.build.product") == "D6506" || getprop("ro.product.device") == "D6543" || getprop("ro.build.product") == "D6543" || getprop("ro.product.device") == "sirius" || getprop("ro.build.product") == "sirius" || abort("This package is for \"D6502,D6503,D6506,D6543,sirius\" devices; this is a \"" + getprop("ro.product.device") + "\"."););'
        device1="D6502"
        device2="D6503"
        device3="D6506"
        device4="D6543"
        device5="sirius"
    ;;
    z3)
        # export assets_line='assert(getprop("ro.product.device") == "D6602" || getprop("ro.build.product") == "D6602" || getprop("ro.product.device") == "D6603" || getprop("ro.build.product") == "D6603" || getprop("ro.product.device") == "D6633" || getprop("ro.build.product") == "D6633" || getprop("ro.product.device") == "D6643" || getprop("ro.build.product") == "D6643" || getprop("ro.product.device") == "z3" || getprop("ro.build.product") == "z3" || abort("This package is for device: D6602,D6603,D6633,D6643,z3; this device is " + getprop("ro.product.device") + "."););'
        device1="D6602"
        device2="D6603"
        device3="D6633"
        device4="D6643"
        device5="z3"
    ;;
    z3c)
        # export assets_line='assert(getprop("ro.product.device") == "D5803" || getprop("ro.build.product") == "D5803" || getprop("ro.product.device") == "D5833" || getprop("ro.build.product") == "D5833" || getprop("ro.product.device") == "z3c" || getprop("ro.build.product") == "z3c" || abort("This package is for device: D5803,D5833,z3c; this device is " + getprop("ro.product.device") + "."););'
        device1="D5803"
        device2="D5833"
        device3="z3c"
        device4=""
        device5=""
    ;;
    honami)
        # export assets_line='assert(getprop("ro.product.device") == "C6902" || getprop("ro.build.product") == "C6902" || getprop("ro.product.device") == "C6903" || getprop("ro.build.product") == "C6903" || getprop("ro.product.device") == "C6906" || getprop("ro.build.product") == "C6906" || getprop("ro.product.device") == "C6943" || getprop("ro.build.product") == "C6943" || getprop("ro.product.device") == "honami" || getprop("ro.build.product") == "honami" || abort("This package is for device: C6902,C6903,C6906,C6943,honami; this device is " + getprop("ro.product.device") + "."););'
        device1="C6902"
        device2="C6903"
        device3="C6906"
        device4="C6943"
        device5="honami"
    ;;
    *)
        echo "wrong Device specified. You set $device, it needs to be amami, sirius, z3 or z3c"
        exit 1
    ;;
esac

if [ $permissive == "permissive" ]; then
  permissive="1"
  version="$version-Permissive"
else
  permissive="0"
fi

kernel_name=M5-Kernel-V$version-L-$device

cat <<EOT>> AnyKernel2/M5Installer.sh
device.name1=$device1
device.name2=$device2
device.name3=$device3
device.name4=$device4
device.name5=$device5
is.permissive=$permissive
EOT

cd AnyKernel2
zip -r ../M5-Kernel-V$version-unsigned.zip *
cd ..
java -Xmx2048m -jar signing/signapk.jar -w signing/testkey.x509.pem signing/testkey.pk8 M5-Kernel-V$version-unsigned.zip M5-Kernel-V$version-false-signed.zip
rm -f M5-Kernel-V$version-unsigned.zip
signing/zipadjust M5-Kernel-V$version-false-signed.zip M5-Kernel-V$version-adjusted-unsigned.zip
rm -f M5-Kernel-V$version-false-signed.zip
java -Xmx2048m -jar signing/minsignapk.jar signing/testkey.x509.pem signing/testkey.pk8 M5-Kernel-V$version-adjusted-unsigned.zip RELEASE/$device/$kernel_name.zip
rm -f M5-Kernel-V$version-adjusted-unsigned.zip
echo "M5 Kernel for $device Sucessfully Packed and Signed as $kernel_name"
