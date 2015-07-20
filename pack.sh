#!/bin/bash
version=$1
device=$2
kernel_name=$3
android_version=$4
if [ -z $android_version ]
  then
    android_version="L"
    folder="cm12_1"
fi

rm -f FILES/$device/boot.img
rm -f FILES/$device/META-INF/com/google/android/updater-script
rm -rf FILES/$device/system
mkdir -p FILES/$device/system
cp ../$folder/out/target/product/$device/boot.img FILES/$device/boot.img
cp -r ../$folder/out/target/product/$device/system/etc FILES/$device/system
cp ../$folder/device/sony/$device/thermanager.xml FILES/$device/system/etc/thermanager.xml
cp -r ../$folder/out/target/product/$device/system/lib FILES/$device/system

if [ $device == "amami" ]; then
    export assets_line='assert(getprop("ro.product.device") == "D5503" || getprop("ro.build.product") == "D5503" || getprop("ro.product.device") == "amami" || getprop("ro.build.product") == "amami" || getprop("ro.product.device") == "anami" || getprop("ro.build.product") == "anami" || abort("This package is for device: D5503,amami,anami; this device is " + getprop("ro.product.device") + "."););'
else
if [ $device  == "sirius" ]; then
    export assets_line='assert(getprop("ro.product.device") == "D6502" || getprop("ro.build.product") == "D6502" || getprop("ro.product.device") == "D6503" || getprop("ro.build.product") == "D6503" || getprop("ro.product.device") == "D6506" || getprop("ro.build.product") == "D6506" || getprop("ro.product.device") == "D6543" || getprop("ro.build.product") == "D6543" || getprop("ro.product.device") == "sirius" || getprop("ro.build.product") == "sirius" || abort("This package is for \"D6502,D6503,D6506,D6543,sirius\" devices; this is a \"" + getprop("ro.product.device") + "\"."););'
else
if [ $device  == "z3" ]; then
    export assets_line='assert(getprop("ro.product.device") == "D6602" || getprop("ro.build.product") == "D6602" || getprop("ro.product.device") == "D6603" || getprop("ro.build.product") == "D6603" || getprop("ro.product.device") == "D6633" || getprop("ro.build.product") == "D6633" || getprop("ro.product.device") == "D6643" || getprop("ro.build.product") == "D6643" || getprop("ro.product.device") == "z3" || getprop("ro.build.product") == "z3" || abort("This package is for device: D6602,D6603,D6633,D6643,z3; this device is " + getprop("ro.product.device") + "."););'
else
if [ $device  == "z3c" ]; then
    export assets_line='assert(getprop("ro.product.device") == "D5803" || getprop("ro.build.product") == "D5803" || getprop("ro.product.device") == "D5833" || getprop("ro.build.product") == "D5833" || getprop("ro.product.device") == "z3c" || getprop("ro.build.product") == "z3c" || abort("This package is for device: D5803,D5833,z3c; this device is " + getprop("ro.product.device") + "."););'
else
echo "wrong Device specified. You set $device, it needs to be amami, sirius, z3 or z3c"
exit 1
fi
fi
fi
fi

cat <<EOT>> FILES/$device/META-INF/com/google/android/updater-script
$assets_line
show_progress(0.500000, 0);
ui_print("                                        ");
ui_print("               __  _________            ");
ui_print("              /  |/  / ____/            ");
ui_print("             / /|_/ /___ \              ");
ui_print("            / /  / /___/ /              ");
ui_print("           /_/  /_/_____/               ");
ui_print("               ______                   ");
ui_print("              /_____/                   ");
ui_print("      __ __                     __      ");
ui_print("     / //_/__  _________  ___  / /      ");
ui_print("    / ,< / _ \/ ___/ __ \/ _ \/ /       ");
ui_print("   / /| /  __/ /  / / / /  __/ /        ");
ui_print("  /_/ |_\___/_/  /_/ /_/\___/_/         ");
ui_print("                                        ");
show_progress(0.200000, 0);
show_progress(0.200000, 10);
ui_print("|> Extracting kernel modules...");
delete_recursive("/system/lib/modules");
delete("/system/etc/thermanager.xml");
package_extract_dir("system", "/system");
set_perm_recursive(1023, 1023, 0775, 0777, "/system/lib/modules/");
set_perm_recursive(1023, 1023, 0775, 0777, "/system/etc/thermanager.xml");
ui_print("|> Flashing boot.img...");
show_progress(0.200000, 10);
package_extract_file("boot.img", "/dev/block/platform/msm_sdcc.1/by-name/boot");
show_progress(0.100000, 0);
EOT

cd FILES/$device
zip -r ../../M5-Kernel-V$version-unsigned.zip *
cd ../..
java -Xmx2048m -jar signing/signapk.jar -w signing/testkey.x509.pem signing/testkey.pk8 M5-Kernel-V$version-unsigned.zip RELEASE/$device/$kernel_name.zip
rm -f M5-Kernel-V$version-unsigned.zip

echo "M5 Kernel for $device Sucessfully Packed and Signed as $kernel_name"
