# Metasploitable2 Exploitation Report

**Name:**Owusu  Nana Yaw
**Index Number:** 4195424
**Date:** September 21, 2026
**Target IP:** 192.168.1.3
**Attacker OS / Tools:** Kali Linux 2026.x, Metasploit Framework 6.4.135-dev, nmap 7.99

---

## Reconnaissance Summary

Ran `nmap -sV -sC 192.168.1.3 -oN scan_results.txt` to enumerate open ports and service versions before attempting any exploits. Key findings:

- Port 21 (FTP) — vsftpd 2.3.4, anonymous login allowed
- Port 22 (SSH) — OpenSSH 4.7p1 Debian 8ubuntu1
- Port 23 (Telnet) — Linux telnetd
- Port 25 (SMTP) — Postfix smtpd
- Port 139 (Samba/SMB)
- Port 3632 (distccd)
- Port 6667 (UnrealIRCd)

See evidence/recon.png for full scan output.

---
## Exploit 1: vsftpd 2.3.4 Backdoor

- **Service / Port:** FTP / 21
- **Vulnerability:** vsftpd 2.3.4 backdoor (CVE-2011-2523)
- **Tool Used:** Metasploit — exploit/unix/ftp/vsftpd_234_backdoor
- **Why This Tool:** Nmap's version scan (-sV) identified vsftpd 2.3.4 running on port 21, a version with a publicly known, deliberately inserted backdoor triggered by a specific login string. Metasploit has a dedicated module that automates this exact trigger and payload delivery, making it the correct tool rather than a generic brute-force or manual approach.
- **Steps:**
  1. Ran `nmap -sV -sC 192.168.1.3` and identified vsftpd 2.3.4 on port 21
  2. Opened msfconsole, searched for `vsftpd`, selected `exploit/unix/ftp/vsftpd_234_backdoor`
  3. Set RHOSTS to 192.168.1.3 and LHOST to 192.168.1.4 (Kali IP)
  4. Ran the exploit; a Meterpreter session opened automatically
  5. Verified access via `sysinfo`, `getuid`, and a spawned shell (`id`, `uname -a`)
- **Evidence:** evidence/exploit1.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, Command & Control
  - Reconnaissance: the nmap scan identified the vulnerable vsftpd version before any attack was attempted.
  - Weaponization: selecting and configuring the Metasploit module with the correct RHOSTS/LHOST paired the known vulnerability with a working payload.
  - Delivery: running the module sent the crafted backdoor-triggering FTP login string to the target.
  - Exploitation: the backdoor condition fired, spawning a listener on the target.
  - Installation: the Meterpreter payload was staged and executed on the target, establishing a foothold.
  - Command & Control: the active Meterpreter session over the reverse TCP handler is the C2 channel.
- **Outcome / Impact:** Obtained a Meterpreter session and root-level shell access on the target, confirmed via `getuid` and `id` (uid=0/root).

---

## Exploit 2: Telnet Weak/Default Credentials

- **Service / Port:** Telnet / 23
- **Vulnerability:** Weak/default credentials (no account lockout, well-known default account msfadmin:msfadmin)
- **Tool Used:** Manual login via `telnet` client — no Metasploit module required
- **Why This Tool:** Nmap identified Telnet open with a login banner. Since Telnet transmits credentials in plaintext and Metasploitable2 ships with a documented default account, a direct manual login is the correct and most efficient approach — not every exploit needs Metasploit, and this shows understanding of credential-based attacks rather than blind tool reliance.
- **Steps:**
  1. Ran `nmap -sV -sC 192.168.1.3` and identified Telnet open on port 23
  2. Ran `telnet 192.168.1.3` from Kali
  3. Logged in using default credentials `msfadmin:msfadmin`
  4. Verified access via `id` and `uname -a`
- **Evidence:** evidence/exploit2.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Exploitation, Actions on Objectives
  - Reconnaissance: nmap identified the open Telnet service and its banner.
  - Delivery: sending the login credentials over the Telnet session.
  - Exploitation: successful authentication using default/weak credentials (no vulnerability was "triggered" — the weakness is the credential policy itself).
  - Actions on Objectives: running `id`/`uname -a` to confirm access and gather system info; no separate Installation/C2 stage applies since Telnet is itself the direct interactive channel, not a payload requiring separate staging.
- **Outcome / Impact:** Obtained an interactive shell as non-root user `msfadmin` via plaintext, default-credential authentication.

---

## Exploit 3: Samba usermap_script Command Execution

- **Service / Port:** Samba (SMB) / 139
- **Vulnerability:** Samba "username map script" Command Execution (CVE-2007-2447)
- **Tool Used:** Metasploit — exploit/multi/samba/usermap_script
- **Why This Tool:** Nmap/searchsploit identified Samba running with the vulnerable "username map script" configuration, which allows shell metacharacters injected into the username field to be executed by the server. Metasploit's dedicated module automates crafting and sending this malicious username, which would be tedious and error-prone to replicate manually.
- **Steps:**
  1. Identified Samba open on port 139 via nmap
  2. Ran `search usermap_script` in msfconsole, selected `exploit/multi/samba/usermap_script`
  3. Set RHOSTS to 192.168.1.3 (LHOST already configured from a prior exploit)
  4. Ran the exploit; a command shell session opened automatically
  5. Verified access via `id` and `uname -a`
- **Evidence:** evidence/exploit3.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, Command & Control
  - Reconnaissance: nmap identified Samba running on port 139.
  - Weaponization: selecting the usermap_script module and configuring RHOSTS/payload to target the specific misconfiguration.
  - Delivery: sending the crafted malicious username to the Samba service.
  - Exploitation: the username map script misconfiguration executed the injected shell command.
  - Installation: the reverse netcat shell was spawned on the target, establishing a foothold.
  - Command & Control: the active reverse shell over the TCP handler is the C2 channel.
- **Outcome / Impact:** Obtained a root-level command shell on the target via a Samba misconfiguration, confirmed via `id`/`uname -a` (uid=0/root).

---

## Exploit 4: UnrealIRCd 3.2.8.1 Backdoor

- **Service / Port:** IRC / 6667
- **Vulnerability:** UnrealIRCd 3.2.8.1 backdoor (trojanized source download, CVE-2010-2075)
- **Tool Used:** Metasploit — exploit/unix/irc/unreal_ircd_3281_backdoor
- **Why This Tool:** Nmap identified an IRC service on port 6667. UnrealIRCd's source archives from this period were compromised, adding a backdoor triggered by a specific string sent over the IRC protocol. Metasploit automates registering as an IRC user and sending this exact backdoor trigger, which would be very difficult to replicate reliably by hand.
- **Steps:**
  1. Identified IRC service on port 6667 via nmap
  2. Ran `search unreal` in msfconsole, selected `exploit/unix/irc/unreal_ircd_3281_backdoor`
  3. Set RHOSTS to 192.168.1.3 and LHOST to 192.168.1.4
  4. Ran the exploit; Metasploit registered a fake IRC user, detected the backdoor, and sent the trigger command
  5. A Meterpreter session opened automatically; verified access via `sysinfo`, `getuid`, and shell (`id`, `uname -a`)
- **Evidence:** evidence/exploit4.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, Command & Control
  - Reconnaissance: nmap identified the exposed IRC service on port 6667.
  - Weaponization: selecting the module and configuring RHOSTS/LHOST paired the known backdoor with a working reverse payload.
  - Delivery: registering an IRC user and sending the backdoor trigger string to the service.
  - Exploitation: the trojanized UnrealIRCd code executed the injected command upon receiving the trigger.
  - Installation: the Meterpreter payload was staged and executed, establishing a foothold.
  - Command & Control: the active Meterpreter session over the reverse TCP handler is the C2 channel.
- **Outcome / Impact:** Obtained a root-level Meterpreter session and shell on the target via a trojanized service backdoor, confirmed via `getuid`/`id` (uid=0/root).

---

## Exploit 5: DistCC Daemon Command Execution

- **Service / Port:** distccd / 3632
- **Vulnerability:** DistCC Daemon Command Execution (CVE-2004-2687) — distccd accepts and executes arbitrary compilation jobs from any client with no authentication
- **Tool Used:** Metasploit — exploit/unix/misc/distcc_exec, with payload cmd/unix/reverse_perl
- **Why This Tool:** Nmap identified distccd exposed on port 3632. distccd trusts any connecting client to submit compilation commands, so Metasploit's module abuses this by submitting a malicious "compile" job that instead spawns a reverse shell. The default reverse_bash payload failed on this target (bad file descriptor / no /dev/tcp support in the target's shell), so reverse_perl was used instead, since Perl is more reliably available and doesn't depend on bash's /dev/tcp feature.
- **Steps:**
  1. Identified distccd open on port 3632 via nmap
  2. Ran `search distcc` in msfconsole, selected `exploit/unix/misc/distcc_exec`
  3. Set RHOSTS to 192.168.1.3; initial run with default reverse_bash payload failed
  4. Switched payload to `cmd/unix/reverse_perl`, set LHOST to 192.168.1.4
  5. Ran the exploit; a command shell session opened successfully
  6. Verified access via `id` and `uname -a`
- **Evidence:** evidence/exploit5.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, Command & Control
  - Reconnaissance: nmap identified the exposed, unauthenticated distccd service.
  - Weaponization: selecting the module and choosing a working payload (reverse_perl after reverse_bash failed) paired the vulnerability with a functioning delivery mechanism.
  - Delivery: submitting the malicious compile job to distccd.
  - Exploitation: distccd executed the injected command with no authentication check.
  - Installation: the Perl-based reverse shell was spawned on the target.
  - Command & Control: the active reverse shell over the TCP handler is the C2 channel.
- **Outcome / Impact:** Obtained a command shell as the `daemon` user (non-root) on the target via an unauthenticated distccd command execution flaw, confirmed via `id`/`uname -a` — notably lower-privileged than exploits 1, 3, and 4, since distccd runs with reduced privileges by design.

---

## Exploit 6: Java RMI Server Insecure Default Configuration

- **Service / Port:** Java RMI / 1099
- **Vulnerability:** Java RMI Server Insecure Default Configuration Code Execution — the RMI registry accepts remote class loading, allowing an attacker to serve a malicious payload that gets loaded and executed
- **Tool Used:** Metasploit — exploit/multi/misc/java_rmi_server
- **Why This Tool:** Nmap identified an RMI registry exposed on port 1099. By default, the Java RMI distributed garbage collector interface permits unauthenticated remote clients to load remote classes, which Metasploit exploits by hosting a malicious payload JAR over HTTP and instructing the RMI service to fetch and execute it — the module automates the RMI handshake, payload hosting, and class-loading trigger that would be tedious to script manually.
- **Steps:**
  1. Identified Java RMI open on port 1099 via nmap
  2. Ran `search java_rmi_server` in msfconsole, selected `exploit/multi/misc/java_rmi_server`
  3. Set RHOSTS to 192.168.1.3 and LHOST to 192.168.1.4
  4. Ran the exploit; Metasploit hosted the payload over HTTP, sent the RMI header/call, and the target fetched and executed the payload JAR
  5. A Meterpreter session opened automatically; verified access via `sysinfo`, `getuid`, and shell (`id`, `uname -a`)
- **Evidence:** evidence/exploit6.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, Command & Control
  - Reconnaissance: nmap identified the exposed RMI registry on port 1099.
  - Weaponization: configuring the module to host a malicious Java payload JAR paired the insecure default config with a working exploit.
  - Delivery: sending the RMI header/call and serving the payload JAR over HTTP for the target to fetch.
  - Exploitation: the RMI service's insecure default configuration allowed the fetched class to be loaded and executed.
  - Installation: the Meterpreter payload was staged and executed, establishing a foothold.
  - Command & Control: the active Meterpreter session over the reverse TCP handler is the C2 channel.
- **Outcome / Impact:** Obtained a root-level Meterpreter session and shell on the target via an insecure Java RMI default configuration, confirmed via `getuid`/`id` (uid=0/root).

---

## Exploit 7: MySQL Weak/No Root Password

- **Service / Port:** MySQL / 3306
- **Vulnerability:** Weak/no authentication — MySQL root account has no password set
- **Tool Used:** Manual login via `mysql` client (`--skip-ssl` flag required, as the modern client attempts a TLS handshake this old 5.0.51a server does not support)
- **Why This Tool:** Nmap identified MySQL open on port 3306. An initial attempt using Metasploit's `auxiliary/scanner/mysql/mysql_login` failed due to a protocol incompatibility (invalid scramble length) between the module and this old MySQL version, so a direct manual connection with the native `mysql` client was used instead — demonstrating that when a tool doesn't fit the target's exact version quirks, falling back to native protocol tools is the correct troubleshooting step, not blindly retrying the same tool.
- **Steps:**
  1. Identified MySQL open on port 3306 via nmap
  2. Attempted `auxiliary/scanner/mysql/mysql_login` in Metasploit with root/root and root/blank — both failed due to a scramble-length protocol error
  3. Connected directly with `mysql -h 192.168.1.3 -u root --skip-ssl`, using a blank password
  4. Verified access via `SELECT user();` and `SHOW DATABASES;`
- **Evidence:** evidence/exploit7.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Exploitation, Actions on Objectives
  - Reconnaissance: nmap identified the exposed MySQL service and version.
  - Delivery: sending the connection/authentication request to the MySQL service.
  - Exploitation: authenticating as root with no password, exploiting the weak credential policy.
  - Actions on Objectives: querying `SELECT user()`/`SHOW DATABASES` to confirm privilege level and enumerate 7 available databases (information_schema, dvwa, metasploit, mysql, owasp10, tikiwiki, tikiwiki195); no separate Weaponization/Installation/C2 stage applies since this is direct credential-based access, not a payload-based exploit.
- **Outcome / Impact:** Obtained full root-level MySQL access (`root@192.168.1.4`) with no authentication barrier, confirmed via `SELECT user()` and enumeration of 7 databases.

---
## Exploit 8: Apache Tomcat Manager Authenticated Upload Code Execution

- **Service / Port:** Apache Tomcat / 8180
- **Vulnerability:** Weak/default Tomcat Manager credentials (tomcat:tomcat) combined with the Manager application allowing authenticated users to deploy arbitrary WAR files, leading to code execution
- **Tool Used:** Metasploit — exploit/multi/http/tomcat_mgr_upload
- **Why This Tool:** Nmap identified Apache Tomcat on port 8180 with its Manager application exposed. Metasploitable2 ships this Manager app with well-known default credentials (tomcat:tomcat). Metasploit's module automates retrieving a valid session/CSRF token, packaging a malicious WAR file as a payload, deploying it through the Manager app, and triggering execution — replicating this manually would require scripting several authenticated HTTP requests.
- **Steps:**
  1. Identified Tomcat open on port 8180 via nmap
  2. Ran `search tomcat_mgr` in msfconsole, selected `exploit/multi/http/tomcat_mgr_upload`
  3. Set RHOSTS to 192.168.1.3, RPORT to 8180, HttpUsername/HttpPassword to tomcat/tomcat, LHOST already set to 192.168.1.4
  4. Ran the exploit; Metasploit retrieved a session/CSRF token, uploaded and deployed a malicious WAR, executed it, then cleaned up (undeployed)
  5. A Meterpreter session opened automatically; verified access via `sysinfo`, `getuid`, and shell (`id`, `uname -a`)
- **Evidence:** evidence/exploit8.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, Command & Control
  - Reconnaissance: nmap identified the exposed Tomcat Manager application on port 8180.
  - Weaponization: packaging the reverse Meterpreter payload into a deployable WAR file paired with valid default credentials.
  - Delivery: authenticating to the Manager app and uploading the malicious WAR.
  - Exploitation: Tomcat's Manager app deployed and ran the WAR, executing the embedded payload code.
  - Installation: the Meterpreter payload was staged and executed, establishing a foothold.
  - Command & Control: the active Meterpreter session over the reverse TCP handler is the C2 channel.
- **Outcome / Impact:** Obtained a Meterpreter session and shell as the `tomcat55` service account (non-root) on the target via default Tomcat Manager credentials and authenticated WAR upload, confirmed via `getuid`/`id` (uid=110/tomcat55).

---
## Exploit 9: NFS Misconfigured Export (World-Readable Root Filesystem)

- **Service / Port:** NFS / 2049
- **Vulnerability:** Misconfigured NFS export — the root filesystem (`/`) is exported to `*` (any host), with no authentication or host restriction
- **Tool Used:** Manual exploitation via `showmount` and `mount` — no Metasploit module used
- **Why This Tool:** Nmap identified NFS open on port 2049. `showmount -e` revealed the entire filesystem was exported to any client with no access control. Metasploit has no dedicated module for exploiting this kind of Linux NFS misconfiguration directly (the available NFS modules target FreeBSD, macOS, and Windows NFS implementations), so the correct approach is native NFS tooling — mounting the export directly demonstrates the impact without needing a payload-based exploit at all.
- **Steps:**
  1. Identified NFS open on port 2049 via nmap
  2. Ran `showmount -e 192.168.1.3`, confirming `/` exported to `*`
  3. Created a local mount point and ran `sudo mount -t nfs 192.168.1.3:/ /tmp/nfs_mount -o nolock`
  4. Listed the mounted root filesystem (`ls -la`) and read `/etc/passwd` directly from the mount
- **Evidence:** evidence/exploit9.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Exploitation, Actions on Objectives
  - Reconnaissance: nmap identified NFS open, and `showmount -e` enumerated the unrestricted export.
  - Exploitation: mounting the export exploited the lack of any authentication or host-based access control on the share.
  - Actions on Objectives: reading `/etc/passwd` and browsing the full root filesystem directly from the mount point; no Weaponization/Delivery/Installation/C2 applies since this is a direct filesystem-level misconfiguration, not a payload-based exploit against a running process.
- **Outcome / Impact:** Gained unauthenticated read (and likely write) access to the target's entire root filesystem via a misconfigured NFS export, confirmed by reading `/etc/passwd` and listing system directories.

## Exploit 10: SSH Weak/Default Credentials (Legacy Crypto)

- **Service / Port:** SSH / 22
- **Vulnerability:** Weak/default credentials (msfadmin:msfadmin) on an outdated OpenSSH 4.7p1 server that only supports legacy, now-deprecated key exchange, host key, and MAC algorithms
- **Tool Used:** Manual login via the `ssh` client with explicit legacy algorithm flags (`-oHostKeyAlgorithms=+ssh-rsa -oKexAlgorithms=+diffie-hellman-group1-sha1 -oMACs=+hmac-md5`)
- **Why This Tool:** Nmap identified OpenSSH 4.7p1 on port 22. An initial attempt with Hydra failed because modern SSH clients/tools disable legacy key exchange and MAC algorithms by default for security, and this old server only supports those legacy algorithms. Rather than treating this as a dead end, the correct approach was to explicitly re-enable the specific legacy algorithms the server supports, then authenticate directly — demonstrating that exploiting old systems sometimes requires working around modern security defaults in your own tooling, not just the target's flaws.
- **Steps:**
  1. Identified OpenSSH 4.7p1 open on port 22 via nmap
  2. Attempted Hydra brute-force; failed due to "no matching MAC algorithm" (kex error)
  3. Attempted manual `ssh` connection; failed due to unsupported host key type (`ssh-dss`) and MAC/Kex mismatches
  4. Re-ran `ssh` with `-oHostKeyAlgorithms=+ssh-rsa -oKexAlgorithms=+diffie-hellman-group1-sha1 -oMACs=+hmac-md5` to explicitly allow the server's legacy algorithms
  5. Logged in successfully with default credentials `msfadmin:msfadmin`
  6. Verified access via `id` and `uname -a`
- **Evidence:** evidence/exploit10.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Exploitation, Actions on Objectives
  - Reconnaissance: nmap identified the outdated OpenSSH version and open port.
  - Delivery: sending the authentication request (with compatible legacy algorithms) and credentials to the SSH service.
  - Exploitation: successful authentication using default/weak credentials on a server whose outdated crypto support itself reflects poor patching hygiene.
  - Actions on Objectives: running `id`/`uname -a` to confirm access and gather system info; no Weaponization/Installation/C2 applies since this is direct credential-based access via the standard SSH protocol, not a payload-based exploit.
- **Outcome / Impact:** Obtained an interactive shell as non-root user `msfadmin` via default credentials over SSH, after working around legacy cryptographic algorithm restrictions in modern SSH tooling.

## Kill Chain Coverage Summary

| Exploit | Recon | Weaponization | Delivery | Exploitation | Installation | C2 | Actions on Objectives |
|---|---|---|---|---|---|---|---|
| 1. vsftpd 2.3.4 Backdoor | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | |
| 2. Telnet Weak/Default Credentials | ✓ | | ✓ | ✓ | | | ✓ |
| 3. Samba usermap_script | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | |
| 4. UnrealIRCd 3.2.8.1 Backdoor | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | |
| 5. DistCC Daemon Command Execution | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | |
| 6. Java RMI Insecure Default Config | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | |
| 7. MySQL Weak/No Root Password | ✓ | | ✓ | ✓ | | | ✓ |
| 8. Tomcat Manager Authenticated Upload | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | |
| 9. NFS Misconfigured Export | ✓ | | | ✓ | | | ✓ |
| 10. SSH Weak/Default Credentials | ✓ | | ✓ | ✓ | | | ✓ |


## Lessons Learned / Mitigations

1. **vsftpd 2.3.4 Backdoor (Exploit 1):** The fix is simply not running a compromised binary — always verify software downloads against official checksums/signatures and keep FTP services patched to current versions.
2. **Weak/Default Credentials (Exploits 2, 7, 10):** Enforce strong, unique passwords and disable default accounts immediately after installation; disable Telnet entirely in favor of SSH, and disable root remote login on MySQL.
3. **Samba usermap_script / Tomcat Manager (Exploits 3, 8):** Avoid using the vulnerable "username map script" configuration option in Samba, and change default application credentials (Tomcat Manager) immediately after deployment — never leave default admin panels reachable with factory credentials.
4. **NFS Misconfigured Export (Exploit 9):** Restrict NFS exports to specific trusted hosts/subnets using the exports file, and never export the root filesystem `/` — export only the specific directories that need sharing.
