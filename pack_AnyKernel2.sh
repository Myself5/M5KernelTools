#!/bin/bash
version=$1
device=$2
device_common=$3
permissive=$4
android_version="L"
folder="cm12_1"

set -e

rm -rf AnyKernel2/system
rm -rf AnyKernel2/modules
rm -rf AnyKernel2/patch
mkdir -p AnyKernel2/system/etc
mkdir -p AnyKernel2/modules
mkdir -p AnyKernel2/patch
rm -f AnyKernel2/M5Installer.sh
rm -f AnyKernel2/kernel
rm -f AnyKernel2/dt.img
cp ../$folder/device/sony/$device/thermanager.xml AnyKernel2/system/etc/thermanager.xml
cp ../$folder/device/sony/$device_common/rootdir/fstab.qcom AnyKernel2/patch/fstab.qcom
cp ../$folder/device/sony/msm8974-common/boot/init.sh AnyKernel2/patch/init.sh
cp -r ../$folder/out/target/product/$device/kernel AnyKernel2/zImage
cp -r ../$folder/out/target/product/$device/dt.img AnyKernel2/dt.img
cp -r ../$folder/out/target/product/$device/system/lib/modules AnyKernel2/

if [ $device == "amami" ]; then
    export assets_line='assert(getprop("ro.product.device") == "D5503" || getprop("ro.build.product") == "D5503" || getprop("ro.product.device") == "amami" || getprop("ro.build.product") == "amami" || getprop("ro.product.device") == "anami" || getprop("ro.build.product") == "anami" || abort("This package is for device: D5503,amami,anami; this device is " + getprop("ro.product.device") + "."););'
    device1="D5503"
    device2="amami"
    device3="anami"
    device4=""
    device5=""
else
if [ $device  == "sirius" ]; then
    export assets_line='assert(getprop("ro.product.device") == "D6502" || getprop("ro.build.product") == "D6502" || getprop("ro.product.device") == "D6503" || getprop("ro.build.product") == "D6503" || getprop("ro.product.device") == "D6506" || getprop("ro.build.product") == "D6506" || getprop("ro.product.device") == "D6543" || getprop("ro.build.product") == "D6543" || getprop("ro.product.device") == "sirius" || getprop("ro.build.product") == "sirius" || abort("This package is for \"D6502,D6503,D6506,D6543,sirius\" devices; this is a \"" + getprop("ro.product.device") + "\"."););'
    device1="D6502"
    device2="D6503"
    device3="D6506"
    device4="D6543"
    device5="sirius"
else
if [ $device  == "z3" ]; then
    export assets_line='assert(getprop("ro.product.device") == "D6602" || getprop("ro.build.product") == "D6602" || getprop("ro.product.device") == "D6603" || getprop("ro.build.product") == "D6603" || getprop("ro.product.device") == "D6633" || getprop("ro.build.product") == "D6633" || getprop("ro.product.device") == "D6643" || getprop("ro.build.product") == "D6643" || getprop("ro.product.device") == "z3" || getprop("ro.build.product") == "z3" || abort("This package is for device: D6602,D6603,D6633,D6643,z3; this device is " + getprop("ro.product.device") + "."););'
    device1="D6602"
    device2="D6603"
    device3="D6633"
    device4="D6643"
    device5="z3"
else
if [ $device  == "z3c" ]; then
    export assets_line='assert(getprop("ro.product.device") == "D5803" || getprop("ro.build.product") == "D5803" || getprop("ro.product.device") == "D5833" || getprop("ro.build.product") == "D5833" || getprop("ro.product.device") == "z3c" || getprop("ro.build.product") == "z3c" || abort("This package is for device: D5803,D5833,z3c; this device is " + getprop("ro.product.device") + "."););'
    device1="D5803"
    device2="D5833"
    device3="z3c"
    device4=""
    device5=""
else
echo "wrong Device specified. You set $device, it needs to be amami, sirius, z3 or z3c"
exit 1
fi
fi
fi
fi

if [ $permissive == "permissive" ]; then
  permissive_line="echo 1 > /tmp/anykernel/permissive;"
  version="$version-Permissive"
else
  permissive_line=""
fi

kernel_name=M5-Kernel-V$version-L-$device

cat <<EOT>> AnyKernel2/M5Installer.sh
$assets_line
show_progress(0.500000, 0);
show_progress(0.200000, 0);
show_progress(0.200000, 10);
ui_print("|> Installing Thermanager...");
delete("/system/etc/thermanager.xml");
package_extract_dir("system", "/system");
set_perm_recursive(1023, 1023, 0775, 0777, "/system/etc/thermanager.xml");
show_progress(0.100000, 0);
echo 1 > /tmp/anykernel/m5exitcode;
$permissive_line
EOT

cd AnyKernel2
zip -r ../M5-Kernel-V$version-unsigned.zip *
cd ..
java -Xmx2048m -jar signing/signapk.jar -w signing/testkey.x509.pem signing/testkey.pk8 M5-Kernel-V$version-unsigned.zip RELEASE/$device/$kernel_name.zip
rm -f M5-Kernel-V$version-unsigned.zip

echo "M5 Kernel for $device Sucessfully Packed and Signed as $kernel_name"
