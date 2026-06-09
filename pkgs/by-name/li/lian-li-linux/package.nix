{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  clang,
  libclang,
  cmake,
  nasm,
  makeWrapper,
  coreutils,
  hidapi,
  libusb1,
  ffmpeg,
  fontconfig,
  mesa,
  libGL,
  vulkan-loader,
  libxkbcommon,
  wayland,
  libx11,
  libinput,
  libdrm,
  libjpeg_turbo,
  linuxPackages,
  evdi ? linuxPackages.evdi,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lian-li-linux";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "sgtaziz";
    repo = "lian-li-linux";
    tag = "v${finalAttrs.version}";
    hash = "sha256-oBln47TgVZDtcOgDt+Y12b+Z6NNQJN/C4iIDwfcqdis=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-RHj+jmyJ846kidHSTCtFibGzKZNlqUecuekAoZL6P7A=";

  nativeBuildInputs = [
    pkg-config
    clang
    libclang
    cmake
    nasm
    makeWrapper
  ];

  buildInputs = [
    hidapi
    libusb1
    ffmpeg
    fontconfig
    mesa
    libGL
    vulkan-loader
    libxkbcommon
    wayland
    libx11
    libinput
    libdrm
    libjpeg_turbo
    evdi
  ];

  env = {
    CARGO_PROFILE_RELEASE_STRIP = "symbols";
    SLINT_NO_QT = "1";
    LIBCLANG_PATH = "${lib.getLib libclang}/lib";
  };

  postPatch = ''
    substituteInPlace packaging/udev/99-lianli.rules \
      --replace-fail "/bin/chmod" "${lib.getExe' coreutils "chmod"}"
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/lianli-daemon -t $out/bin

    install -Dm755 target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/lianli-gui -t $out/bin

    install -Dm644 packaging/udev/99-lianli.rules -t $out/lib/udev/rules.d

    install -Dm644 packaging/systemd/lianli-daemon.service -t $out/lib/systemd/user

    install -Dm644 packaging/modules-load.d/lianli-evdi.conf -t $out/lib/modules-load.d

    install -Dm644 packaging/desktop/com.sgtaziz.lianlilinux.desktop -t $out/share/applications

    install -Dm644 assets/icons/32x32.png \
      $out/share/icons/hicolor/32x32/apps/com.sgtaziz.lianlilinux.png

    install -Dm644 assets/icons/128x128.png \
      $out/share/icons/hicolor/128x128/apps/com.sgtaziz.lianlilinux.png

    install -Dm644 assets/icons/128x128@2x.png \
      $out/share/icons/hicolor/256x256/apps/com.sgtaziz.lianlilinux.png

    install -Dm644 assets/icons/icon.svg \
      $out/share/icons/hicolor/scalable/apps/com.sgtaziz.lianlilinux.svg

    install -Dm644 LICENSE -t $out/share/licenses/lianli-linux

    runHook postInstall
  '';

  postInstall = ''
    mkdir -p $out/lib

    ln -sf ${evdi}/lib/libevdi.so $out/lib/libevdi.so.1

    wrapProgram $out/bin/lianli-daemon \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
      hidapi
      libusb1
      ffmpeg
      evdi
    ]}:$out/lib"

    wrapProgram $out/bin/lianli-gui \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
      wayland
      libxkbcommon
      libx11
      libinput
      libdrm
      mesa
      libGL
      vulkan-loader
      fontconfig
    ]}"
  '';

  postFixup = ''
    substituteInPlace $out/lib/systemd/user/lianli-daemon.service \
      --replace-fail "/usr/bin/lianli-daemon" "$out/bin/lianli-daemon"
  '';

  meta = {
    description = "Open-source Linux replacement for L-Connect 3";
    maintainers = with lib.maintainers; [
      antoineok
    ];
    homepage = "https://github.com/sgtaziz/lian-li-linux";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "lianli-gui";
  };
})
