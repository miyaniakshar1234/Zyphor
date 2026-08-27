class Zyphor < Formula
  desc "Next-generation native terminal system observatory written in pure Zig"
  homepage "https://github.com/miyaniakshar1234/Zyphor"
  version "0.1.0"
  license "MIT"

  if OS.mac?
    url "https://github.com/miyaniakshar1234/Zyphor/releases/download/v0.1.0/zyphor-macos-x86_64.tar.gz"
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/miyaniakshar1234/Zyphor/releases/download/v0.1.0/zyphor-linux-aarch64.tar.gz"
    else
      url "https://github.com/miyaniakshar1234/Zyphor/releases/download/v0.1.0/zyphor-linux-x86_64.tar.gz"
    end
  end

  def install
    bin.install "zyphor"
  end

  test do
    system "#{bin}/zyphor", "--version"
  end
end

