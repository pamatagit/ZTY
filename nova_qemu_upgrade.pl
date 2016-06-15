#!/usr/bin/perl
# ---------------------------
# upgrade nova from v1.0.1 to v1.0.3
# upgrade qemu from v2.2 to v2.3
#
# Edit by Tony Cheng
# Update : 20160615
# Version : v0.1
# Node : compute node
# Usage : nova_qemu_upgrade.pl
# ----------------------------

until ($#ARGV < 0) {
   print "\nUsage: nova_qemu_upgrade.pl\n\n";
   exit 1;
}

# Env vars:
chomp($datetime = `/bin/date +'%F'`);

#$base_dir = '/root/tony/';
$base_dir = '/root/tony/qemu_nova-patch';
$backup_dir = $base_dir;
$patch_dir = $base_dir.'/nova/';
$patch_pkg = 'nova-v1.0.3.tar.gz';
$python_dist_dir = '/usr/local/lib/python2.7/dist-packages';
$nova_dir = $python_dist_dir.'/nova';
$nova_egg_dir = $python_dist_dir.'/nova*egg-info';
$computer_daemon_name = 'chrame';
$controller_daemon_name = 'chrome';

@check_dir = ($base_dir,$backup_dir,$patch_dir,
                $python_dist_dir,$nova_dir);

# Server vars:
$repo_server = '192.168.202.250';
$_ = `ps ax|grep chrome|head -n 1`;
@nova_daemon = split(/\s+/, $_);

# RunCommand vars:
$nova103_step1_str = "\n\nStep 1/5 : Backup nova v1.0.1 packages...\n";
$nova103_step2_str = "\n\nStep 2/5 : Unpack nova v1.0.3 packages...\n";
$nova103_step3_str = "\n\nStep 3/5 : remove nova old egg...\n";
$nova103_step4_str = "\n\nStep 4/5 : Installing nova 1.0.3 packages...\n";
$nova103_step5_str = "\n\nStep 5/5 : restart nova service(s)...\n";
@nova103_allsteps_str = ($nova103_step1_str, $nova103_step2_str, $nova103_step3_str, 
                         $nova103_step4_str, $nova103_step5_str);

$backup_nova_cmd = "cd $nova_dir; tar zcvf $backup_dir/nova-backup-$datetime.tar.gz $nova_dir $nova_egg_dir";
$unpack_patch_cmd = "cd $base_dir && tar zxvf $patch_pkg";
$remove_egg_cmd = "cd $python_dist_dir; rm -rf $nova_egg_dir";
$pip_cmd = "cd $patch_dir && pip install -r requirements.txt; python setup.py install";
($role eq 'computer') ? ($restart_service_cmd = "service nova-compute restart") : 
                           ($restart_service_cmd = "service nova-api restart; \
                                                    service nova-scheduler restart; \
                                                    service nova-conductor restart");
@nova103_allsteps_cmd = ($backup_nova_cmd, $unpack_patch_cmd, $remove_egg_cmd, $pip_cmd);


# main()
print "\n\nChecking directory & role....\n";
foreach $_ (@check_dir) {
    if (!(-e $_)) {
        die "the directory : $_ is not exists!\n";
    }
    if ($nova_daemon[5] =~ /$computer_daemon_name/) {
        $role = 'computer';
    } elsif ($nova_daemon[5] =~ /$controller_daemon_name/) {
        $role = 'controller';
    } else {
        die("Error: The role is undefined!\n");
    }
}

print "Role : $role\n";
print "\n\nChecking ok!! Running nova v1.0.3 upgrade procedures...\n";
#sleep(4);
#&run_nova103(@nova103_allsteps_str, @nova103_allsteps_cmd);
&run_nova103;

# functions()
sub run_nova103 {
    foreach ($each_str, $each_cmd) (@nova103_allsteps_str, @nova_allsteps_cmd) {
        print "str: $each_str\n";
        print "command: $each_cmd\n";
        #die ("Error: $?\n") if (!(system($each_cmd) == 0));
    }

    exit 0;
}
