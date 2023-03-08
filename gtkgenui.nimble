# Package

version       = "0.2.1"
author        = "Peter Munch-Ellingsen"
description   = "Genui is a DSL macro for creating graphical user interfaces. This version is for the Gtk toolkit."
license       = "MIT"
srcDir        = "gtkgenui"

# Dependencies

requires      "nim >= 0.19.0"
requires      "gtk2 >= 1.0"

# Skip examples from nimble installation

skipFiles     = @["example.nim"]

