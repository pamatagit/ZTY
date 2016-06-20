#!/usr/bin/perl
# ---------------------------
# upgrade nova from v1.0.1 to v1.0.3
# upgrade qemu from v2.2 to v2.3
#
# Edit by Tony Cheng
# Update : 20160615
# Version : v0.3
# Node : compute node
# Usage : nova_qemu_upgrade.pl
# ----------------------------

until ($#ARGV < 0) {
   print "\nUsage: nova_qemu_upgrade.pl\n\n";
   exit 1;
}

# Env vars:
chomp($datetime = `/bin/date +'%F'`);
chomp($datetimes = `/bin/date +'%F %H:%M:%S'`);

#$base_dir = '/root/tony/';
$base_dir = '/root/qemu_nova-patch';
$backup_dir = $base_dir;
$patch_dir = $base_dir.'/nova/';
$patch_pkg = 'nova-v1.0.3.tar.gz';
$python_dist_dir = '/usr/local/lib/python2.7/dist-packages';
$nova_dir = $python_dist_dir.'/nova';
$nova_egg_dir = $python_dist_dir.'/nova*egg-info';
$computer_daemon_name = 'nova-compute';
$controller_daemon_name = 'nova-schedule';
$log_file = $base_dir.'/'.'nova_qemu_upgrade.log';

@check_dir = ($base_dir, $python_dist_dir);

# Server vars:
$repo_server = '192.168.202.250';
#$_ = `ps ax|egrep "$computer_daemon_name|$controller_daemon_name"|sed -e "s/^.*nova/nova/"|head -n 1|awk '{print $1}'`;
$_ = `ps ax|egrep "$computer_daemon_name|$controller_daemon_name"|tail -1`;
print "$_\n";
$nova_daemon = $_;

# RunCommand vars:
$nova103_step1_str = "Step 1/5 : Backup nova v1.0.1 packages...";
$nova103_step2_str = "Step 2/5 : Unpack nova v1.0.3 packages...";
$nova103_step3_str = "Step 3/5 : remove nova old egg...";
$nova103_step4_str = "Step 4/5 : Installing nova 1.0.3 packages...";
$nova103_step5_str = "Step 5/5 : Restart nova service(s)...";
#@nova103_allsteps_str = ($nova103_step1_str, $nova103_step2_str, $nova103_step3_str, 
#                         $nova103_step4_str, $nova103_step5_str);

$qemu23_step1_str = "Step 1/6 : Prepare qemu repo....";
$qemu23_step2_str = "Step 2/6 : qemu-system-x86 upgrading....";
$qemu23_step3_str = "Step 3/6 : qemu-system-common upgrading....";
$qemu23_step4_str = "Step 4/6 : qemu-utils upgrading....";
$qemu23_step5_str = "Step 5/6 : recover to original repo....";
$qemu23_step6_str = "Step 6/6 : reboot....";

# File Handle
#open FH1, ">>$log_file" or die "$datetimes\tcan't open file: $!\n";

$backup_nova_cmd = "cd $nova_dir; tar zcvf $backup_dir/nova-backup-$datetime.tar.gz $nova_dir $nova_egg_dir";
$unpack_patch_cmd = "cd $base_dir && tar zxvf $patch_pkg";
$remove_egg_cmd = "cd $python_dist_dir; rm -rf $nova_egg_dir";
$pip_cmd = "cd $patch_dir && pip install -r requirements.txt; python setup.py install";
#@nova103_allsteps_cmd = ($backup_nova_cmd, $unpack_patch_cmd, $remove_egg_cmd, $pip_cmd);

$renew_sourceslist_cmd = "cp $base_dir/sources.list.nova /etc/apt/sources.list; apt-get update";
$qemux86_upgrade_cmd = "aptitude -y safe-upgrade qemu-system-x86";
$qemucomm_upgrade_cmd = "aptitude -y safe-upgrade qemu-system-common";
$qemuutils_upgrade_cmd = "aptitude -y safe-upgrade qemu-utils";
$recover_sourceslist_cmd = "cp $base_dir/sources.list.org /etc/apt/sources.list; apt-get update";
$reboot = "reboot";


# main()
print "\n\nChecking directory & role....\n";
foreach $_ (@check_dir) {
    if (!(-e $_)) {
        die "the directory : $_ is not exists!\n";
    }
    if ($nova_daemon =~ /$computer_daemon_name/) {
        $role = 'computer';
    } elsif ($nova_daemon =~ /$controller_daemon_name/) {
        $role = 'controller';
    } else {
        die("Error: The role is undefined!\n");
    }
}

($role eq 'computer') ? ($restart_service_cmd = "service nova-compute restart") : 
                        ($restart_service_cmd = "service nova-api restart; \
                                                 service nova-scheduler restart; \
                                                 service nova-conductor restart");

print "Begin upgrade nova v1.0.3......\nRole : $role\n";
print "Checking ok!! Running nova v1.0.3 upgrade procedures...\n";
sleep(6);

# run commands
print "\n$nova103_step1_str\n";
print "command: $backup_nova_cmd\n";
die ("Error: $?\n") if (!(system($backup_nova_cmd) == 0));
sleep(4);

print "\n$nova103_step2_str\n";
print "command: $unpack_patch_cmd\n";
die ("Error: $?\n") if (!(system($unpack_patch_cmd) == 0));
sleep(4);

print "\n$nova103_step3_str\n";
print "command: $remove_egg_cmd\n";
die ("Error: $?\n") if (!(system($remove_egg_cmd) == 0));
sleep(4);

print "\n$nova103_step4_str\n";
print "command: $pip_cmd\n";
die ("Error: $?\n") if (!(system($pip_cmd) == 0));
sleep(4);

print "\n$nova103_step5_str\n";
print "command: $restart_service_cmd\n";
die ("Error: $?\n") if (!(system($restart_service_cmd) == 0));
sleep(4);

$nova_result = `cat /usr/local/lib/python2.7/dist-packages/nova/virt/vmwareapi/vm_util.py|head -n 171|tail -1`;
print "checking if vm_util.py in line 171 is : $nova_result\n";
die ("Error: patch failed!  $?\n") until ($nova_result =~ /config_spec.name = instance.hostname/);

print "\n\n ===========================================\n\n";
print "The patch works! ^_^  upgrade nova v1.0.3 successful!!\n\n\n\n";

#-------------------------------------------------------------------------------------
if ($role eq 'computer') {
    print "Continue to upgrade QEMU from v2.2 to v2.3.....\n";

    sleep(4);
    print "\n$qemu23_step1_str\n";
    print "Command: $renew_sourceslist_cmd\n";
    die ("Error: $?\n") if (!(system($renew_sourceslist_cmd) == 0));

    sleep(4);
    print "\n$qemu23_step2_str\n";
    print "Command: $qemux86_upgrade_cmd\n";
    die ("Error: $?\n") if (!(system($qemux86_upgrade_cmd) == 0));

    sleep(4);
    print "\n$qemu23_step3_str\n";
    print "Command: $qemucomm_upgrade_cmd\n";
    die ("Error: $?\n") if (!(system($qemucomm_upgrade_cmd) == 0));

    sleep(4);
    print "\n$qemu23_step4_str\n";
    print "Command: $qemuutils_upgrade_cmd\n";
    die ("Error: $?\n") if (!(system($qemuutils_upgrade_cmd) == 0));

    sleep(4);
    print "\n$qemu23_step5_str\n";
    print "Command: $recover_sourceslist_cmd\n";
    die ("Error: $?\n") if (!(system($recover_sourceslist_cmd) == 0));

#    sleep(4);
#    print "\n$qemu23_step6_str\n";
#    print "Command: $reboot\n";
#    die ("Error: $?\n") if (!(system($reboot) == 0));
} 

$qemu_version = `dpkg -l|grep qemu`;
print "$qemu_version\n";
exit 0;
