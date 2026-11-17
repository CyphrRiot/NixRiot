let
  local = import ./local.nix;
in
{
  imports = [ ./configuration.nix ];

  home-manager.users.${local.nixriotUser} = import ../../home;
}
