using BinDeps

@BinDeps.setup

libopenslide = library_dependency("libopenslide", aliases = ["libopenslide-0"])

#=
@windows_only begin
  using WinRPM
  
  osld_win_url = "https://github.com/openslide/openslide-winbuild/releases/download/v20140125/openslide-win$(WORD_SIZE)-20140125.zip"
  provides(Binaries, {URI(osld_win_url) => libopenslide}, os = :Windows)
  push!(DL_LOAD_PATH, "bin")
end
=#

provides(SimpleBuild, (), libopenslide, os = :Windows)

@BinDeps.install [:libopenslide => :los]
