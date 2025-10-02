{ pkgs, ... }:
{
  users.ldap = {
    enable = true;
    base = "dc=BRIDGE,dc=ENTERPRISE";
    server = "ldap://192.168.42.195/";
    useTLS = false;
    extraConfig = ''
      ldap_version 3
      pam_password md5
    '';
  };
}
