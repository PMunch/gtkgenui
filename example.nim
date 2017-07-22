import gtk2, gtkgenui

init(nil, nil)

proc bPressed(widget, data: pointer): bool {.cdecl.} =
  echo cast[int](widget)
  echo cast[int](data)
  echo "hello"

proc eDestroy(widget, data: pointer): bool {.cdecl.} =
  main_quit()

genui:
  Window(0) -> ("destroy": eDestroy) {@r.show_all()}:
    VBox(homogeneous = false, spacing = 10):
      Button("Hello")[false, true, 10]{var t = @r} -> ("clicked": bPressed)
      Button("World")[expand = false, fill = true, padding = 10]

main()
