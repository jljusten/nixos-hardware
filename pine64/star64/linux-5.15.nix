{ lib, callPackage, linuxPackagesFor, kernelPatches, fetchpatch, ... }:

let
  modDirVersion = "5.15.131";
  linuxPkg = { lib, fetchFromGitHub, buildLinux, ... }@args:
    buildLinux (args // {
      version = "${modDirVersion}-fishwaldo-star64";

      src = fetchFromGitHub {
        owner = "Fishwaldo";
        repo = "Star64_linux";
        rev = "1456c984f15e21e28fb8a9ce96d0ca10e61a71c4"; # Star64_devel branch
        hash = "sha256-I5wzmxiY7PWpahYCqTOAmYEiJvpRPpUV7S21Kn9lLwg=";
      };

      inherit modDirVersion;
      defconfig = "pine64_star64_defconfig";
      kernelPatches = [
         { patch = fetchpatch {
             url = "https://github.com/torvalds/linux/commit/215bebc8c6ac438c382a6a56bd2764a2d4e1da72.diff";
             hash = "sha256-1ZqmVOkgcDBRkHvVRPH8I5G1STIS1R/l/63PzQQ0z0I=";
             includes = ["security/keys/dh.c"];
           };
         }
         { patch = fetchpatch {
             url = "https://github.com/starfive-tech/linux/pull/108/commits/9ae8cb751c4d1fd2146b279a8e67887590e9d07a.diff";
             hash = "sha256-EY0lno+HkY5mradBUPII3qqu0xh+BVQRzveCQcaht0M=";
           };
         }
         { patch = ./irq-desc-to-data.patch; }
      ] ++ kernelPatches;

      structuredExtraConfig = with lib.kernel; {
        # A ton of stuff just does not build. We disable it all.
        # Most of it is not important except drm.
        # https://github.com/starfive-tech/linux/issues/79

        # Removed files, re-added to the makefile by accident in
        # https://github.com/Fishwaldo/Star64_linux/commit/cd96097d17a494974dfc5e9909476145ab4f09f5
        CRYPTO_RMD128 = no;
        CRYPTO_RMD256 = no;
        CRYPTO_RMD320 = no;
        CRYPTO_TGR192 = no;
        CRYPTO_SALSA20 = no;

        CRYPTO_SM4 = no; # modpost: undefined stuff
        CRYPTO_DEV_CCREE = no; # reverse dep of CRYPTO_SM4
        NLS_CODEPAGE_949 = no;
        VIDEO_OV5640 = no; # conflicts with starfive VIN_SENSOR_OV5640

        DRM_PANEL_BOE_TH101MB31UIG002_28A = yes;
        DRM_PANEL_JADARD_JD9365DA_H3 = yes;
        DRM_VERISILICON = yes;

        STARFIVE_INNO_HDMI = yes;
        STARFIVE_DSI = yes;

        DRM_IMG_ROGUE = module;
        DRM_IMG_LEGACY = yes;
        DRM_VERISILICON = no;
      };

      extraMeta.branch = "Star64_devel";
    } // (args.argsOverride or { }));

in lib.recurseIntoAttrs (linuxPackagesFor (callPackage linuxPkg { }))
