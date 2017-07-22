# Package

version       = "0.1.0"
author        = "Peter Munch-Ellingsen"
description   = "Genui is a DSL macro for creating graphical user interfaces. This version is for the Gtk toolkit."
license       = "MIT"

# Dependencies

requires      "nim >= 0.17.1"
requires      "gtk2 >= 1.0"

# Skip examples from nimble installation

skipFiles     = @["example.nim"]

