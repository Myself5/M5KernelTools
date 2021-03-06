# AnyKernel 2.0 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# EDIFY properties
do.devicecheck=1
do.initd=0
do.modules=1
do.cleanup=1

# shell variables
block=/dev/block/platform/msm_sdcc.1/by-name/boot;

## end setup


## AnyKernel methods (DO NOT CHANGE)
# set up extracted files and directories
ramdisk=/tmp/anykernel/ramdisk;
bin=/tmp/anykernel/tools;
split_img=/tmp/anykernel/split_img;
patch=/tmp/anykernel/patch;

chmod -R 755 $bin;
mkdir -p $ramdisk $split_img;
cd $ramdisk;

OUTFD=`ps | grep -v "grep" | grep -oE "update(.*)" | cut -d" " -f3`;
ui_print() { echo "ui_print $1" >&$OUTFD; echo "ui_print" >&$OUTFD; }

# dump boot and extract ramdisk
dump_boot() {
  dd if=$block of=/tmp/anykernel/boot.img;
  $bin/unpackbootimg -i /tmp/anykernel/boot.img -o $split_img;
  if [ $? != 0 ]; then
    ui_print " "; ui_print "Dumping/unpacking image failed. Aborting...";
    echo 1 > /tmp/anykernel/exitcode; exit;
  fi;
  gunzip -c $split_img/boot.img-ramdisk.gz | cpio -i;
}

# repack ramdisk then build and write image
write_boot() {
  cd $split_img;
  cmdline=`cat *-cmdline`;
  if [ "$(file_getprop /tmp/anykernel/M5Installer.sh is.permissive)" == 1 ]; then
    if [[ cmdline == *"permissive"* ]]; then
      ui_print "Skipping Permissive Modification, Permissive was already found in the cmdline";
    else
      cmdline="$cmdline androidboot.selinux=permissive";
    fi;
  fi;

  board=`cat *-board`;
  base=`cat *-base`;
  pagesize=`cat *-pagesize`;
  kerneloff=`cat *-kerneloff`;
  ramdiskoff=`cat *-ramdiskoff`;
  tagsoff=`cat *-tagsoff`;
  if [ -f *-second ]; then
    second=`ls *-second`;
    second="--second $split_img/$second";
    secondoff=`cat *-secondoff`;
    secondoff="--second_offset $secondoff";
  fi;
  if [ -f /tmp/anykernel/zImage ]; then
    kernel=/tmp/anykernel/zImage;
  else
    kernel=`ls *-zImage`;
    kernel=$split_img/$kernel;
  fi;
  if [ -e /tmp/anykernel/dt.img ]; then
    dtb="--dt /tmp/anykernel/dt.img";
  elif [ -f *-dtb ]; then
    ui_print " "; ui_print "no dt.img found, aborting!"
    abort;
  fi;
  cd $ramdisk;
  if [ -e $ramdisk/fstab.qcom ]; then
    find . | cpio -H newc -o | gzip > /tmp/anykernel/ramdisk-new.cpio.gz;
    $bin/mkbootimg --kernel $kernel --ramdisk /tmp/anykernel/ramdisk-new.cpio.gz --cmdline "$cmdline" --base $base --pagesize $pagesize $dtb --ramdisk_offset $ramdiskoff --tags_offset $tagsoff --output /tmp/anykernel/boot-new.img;
    # check if this zip get's flashed in MultiROM, it appears like the ifcheck does not get fullfuilled in Secondary Roms
    if [ ! -e /tmp/mrom_last_updater_script ] || [ "$(cat /tmp/mrom_last_updater_script)" != "$(cat /tmp/anykernel/META-INF/com/google/android/updater-script)" ]; then
      echo 1 > /tmp/anykernel/bootchecked
      if [ $? != 0 -o `wc -c < /tmp/anykernel/boot-new.img` -gt `wc -c < /tmp/anykernel/boot.img` ]; then
        ui_print " "; ui_print "Repacking image failed. Aborting...";
        echo 1 > /tmp/anykernel/exitcode; exit;
      fi;
    fi;
    dd if=/tmp/anykernel/boot-new.img of=$block;
  else
    ui_print "Error creating working boot image, aborting install!";
    ui_print "Are you running a compatible recovery?";
    ui_print "Remember that CM Recovery is not supported by this Installer!";
    echo 2 > /tmp/anykernel/exitcode; exit;
  fi;
}

# backup_file <file>
backup_file() { cp $1 $1~; }

# replace_string <file> <if search string> <original string> <replacement string>
replace_string() {
  if [ -z "$(grep "$2" $1)" ]; then
      sed -i "s;${3};${4};" $1;
  fi;
}

# insert_line <file> <if search string> <before/after> <line match string> <inserted line>
insert_line() {
  if [ -z "$(grep "$2" $1)" ]; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | cut -d: -f1` + offset));
    sed -i "${line}s;^;${5};" $1;
  fi;
}

# replace_line <file> <line replace string> <replacement line>
replace_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | cut -d: -f1`;
    sed -i "${line}s;.*;${3};" $1;
  fi;
}

# remove_line <file> <line match string>
remove_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | cut -d: -f1`;
    sed -i "${line}d" $1;
  fi;
}

# prepend_file <file> <if search string> <patch file>
prepend_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo "$(cat $patch/$3 $1)" > $1;
  fi;
}

# append_file <file> <if search string> <patch file>
append_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo -ne "\n" >> $1;
    cat $patch/$3 >> $1;
    echo -ne "\n" >> $1;
  fi;
}

# replace_file <file> <permissions> <patch file>
replace_file() {
  cp -fp $patch/$3 $1;
  chmod $2 $1;
}

# file_getprop <file> <property>
file_getprop() { grep "^$2" "$1" | cut -d= -f2; }

## end methods


## AnyKernel permissions
# set permissions for included files
chmod -R 755 $ramdisk


## AnyKernel install
dump_boot;

# begin ramdisk changes

# fstab.qcom
backup_file fstab.qcom;
replace_file fstab.qcom 755 fstab.qcom

#LZMA Patch
backup_file sbin/init.sh;
replace_file sbin/init.sh 755 init.sh

# end ramdisk changes
write_boot;
## end install
