# Tools for building and testing: Rust, and CMake for libopus, built from its sources.
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    rustup
    cmake
  ];
}
