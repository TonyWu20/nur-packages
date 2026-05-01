{ stdenv
, openssl
, lib
, autoPatchelfHook
, glibc
, glib
, gmp
, gdk-pixbuf
, mpi
, autoAddDriverRunpath
, libxml2
, ncurses5
, expat
, libkrb5
, libxkbcommon
, python312
, python311
, python310
, libibmad
, libibumad
, mesa
, wayland
, libxcb
, xorg
, pulseaudio
, krb5
, gtk2
, fontconfig
, freetype
, numactl
, nss
, unixODBC
, alsa-lib
, libglvnd
, libtiff
, qt6Packages
, rdma-core
, ucx
, gst_all_1
, curlMinimal
, qt6
, libxcrypt-legacy
, ncurses6
, patchelf
, gcc-unwrapped
}:
stdenv.mkDerivation rec {
  name = "nvidia-hpc-sdk-${version}";
  version = "25.7";
  platform = "Linux_x86_64";
  # For localy downloaded offline installers
  #src = /home/tony/Downloads/nvhpc_2025_257_Linux_x86_64_cuda_12.9.tar.gz;
  src = (fetchTarball {
    url = "https://developer.download.nvidia.com/hpc-sdk/25.7/nvhpc_2025_257_Linux_x86_64_cuda_12.9.tar.gz";
    sha256 = "0dil5mp28igirjq2zqzbww5jsmsppq1dfpfqch5zmksk7ci1fxn5";
  });

  nativeBuildInputs = [ autoPatchelfHook autoAddDriverRunpath ];

  buildInputs = [
    mpi
    stdenv.cc.cc.lib
    glibc
    glib
    gmp
    python312
    python311
    python310
    libxml2
    ncurses5
    xorg.libX11
    xorg.libXtst
    xorg.libXrender
    xorg.libXt
    xorg.libXtst
    xorg.libXi
    xorg.libXext
    xorg.libXdamage
    xorg.libxcb
    xorg.xcbutilimage
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    xorg.xcbutilkeysyms
    expat
    pulseaudio
    libxkbcommon
    libkrb5
    krb5
    gtk2
    fontconfig
    freetype
    numactl
    nss
    unixODBC
    alsa-lib
    libglvnd
    (lib.getLib libtiff)
    libtiff
    qt6Packages.qtwayland
    rdma-core
    (ucx.override { enableCuda = false; })
    xorg.libxshmfence
    xorg.libxkbfile
    openssl
    libibmad
    libibumad
    wayland
    mesa
    libxcb
    (map lib.getLib ([
      curlMinimal
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
    ]))
    libxcrypt-legacy
    ncurses6
  ] ++ (with qt6;[
    qtmultimedia
    qttools
    qtpositioning
    qtscxml
    qtsvg
    qtwebchannel
    qtwebengine
  ]);
  # propagatedBuildInputs = [ glibc glib fftw fftwQuad fftwFloat fftwLongDouble fftwMpi openssl ];
  dontConfigure = true;
  dontBuild = true;
  phases = [ "unpackPhase" "patchPhase" "installPhase" "fixupPhase" ];

  autoPatchelfIgnoreMissingDeps = [
    "libpython3.8.so.1.0"
    "libpython3.9.so.1.0"
    "libcuda.so.1"
    "libnvidia-ml.so.1"
    "libcom_err.so.2"
    "libxpmem.so.0"
    "libgdrapi.so.2"
    "libtiff.so.5"
  ];

  patchPhase = ''
    patchShebangs  --build ./install
    patchShebangs --build install_components/install*
  '';

  runtimeDependencies = [
    "${lib.getLib gcc-unwrapped.lib}"
    "${lib.getLib gcc-unwrapped.libgcc}"
    "${lib.getLib glib}"
    (placeholder "lib")
    (placeholder "out")
    "${placeholder "out"}/cuda/nvvm"
    "${lib.getLib stdenv.cc.cc}/lib64"
    "${placeholder "out"}/cuda/lib64"
    "${placeholder "out"}/math_libs/lib64"
    "${placeholder "out"}/cuda/12.9/nvvm/lib64"
  ];

  installPhase = ''
        mkdir -p $out
        echo $(pwd)
        echo "Installing nvhpc_sdk to $out"
        export NVHPC_SILENT=true
        export NVHPC_INSTALL_DIR=$out
        ./install
        installDir=$out/${platform}/${version}
        if [ ! -d "$installDir" ]; then
    	  echo "ERROR: nvidia hpc-sdk installation not found at $installDir"
    	  exit 1
        fi
  '';
  preFixup = ''
    ${lib.getExe' patchelf "patchelf"} $out/lib64/libnvrtc.so --add-needed libnvrtc-builtins.so
  '';

  postInstall = ''
    find $out -name '*python3.8*' -delete
    find $out -name '*python3.9*' -delete
  '';

  fixupPhase = ''
    # Patch ELF binaries
    autoPatchelf $out
    # find $out -type f \( -executable -o -name "*.so*" \) -print0 | while IFS= read -r -d $'\0' file; do
    #   if isELF "$file"; then
    #     echo "Patching $file"
    #   fi
    # done
    patchShebangs --host $out/${platform}/${version}/compilers/bin/makelocalrc
  '';

  meta = with lib;{
    description = "nvidia hpc-sdk";
    homepage = "https://developer.nvidia.com/hpc-sdk";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ maintainers.tonywu20 ];
  };
}
