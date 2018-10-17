import macros, deques
from strutils import toLowerAscii, strip, split

proc `[]`(s: NimNode, x: Slice[int]): seq[NimNode] =
  ## slice operation for NimNodes.
  var a = x.a
  var L = x.b - a + 1
  newSeq(result, L)
  for i in 0 ..< L: result[i] = s[i + a]

proc `[]`(s: NimNode, x: HSlice[int, BackwardsIndex]): seq[NimNode] =
  s[x.a .. s.len - x.b.int]


proc high(s: NimNode):int =
  ## high operation for NimNodes
  s.len-1

type ParsedWidget = ref object
  ## Object that holds all the required information about a widget as learned from parsing the input code
  pureCode: NimNode
  name: string
  packArgs: seq[NimNode]
  initParameters: seq[NimNode]
  eventBindings: seq[NimNode]
  children: seq[ParsedWidget]
  parent: ParsedWidget
  generatedSym: NimNode

proc parseNode(node: NimNode): ParsedWidget
proc parseChildren(p: ParsedWidget, stmtlist:NimNode): seq[ParsedWidget] =
  result = @[]
  for child in stmtList:
    var node = parseNode(child)
    node.parent = p
    result.add node

proc parseNode(node: NimNode): ParsedWidget =
  new result
  var
    toParse = initDeque[tuple[pointed: bool, node: NimNode]]()
    cnode = node
    pointed = false
  if cnode.kind == nnkIdent:
    result.name = $cnode
    cnode = nil
  template checkName() =
    if cnode[0].kind == nnkIdent:
      result.name = $cnode[0]
    else:
      toParse.addFirst((pointed: pointed, node: cnode[0]))
  while cnode != nil:
    if cnode.len != 0 and cnode[cnode.high].kind == nnkStmtList:
      toParse.addFirst((pointed: false, node: cnode[cnode.high]))
      cnode.del cnode.high
    case cnode.kind:
    of nnkInfix:
      if $cnode[0] != "->":
        error("Unrecognized format near: \"" & $cnode[0] & "\"", cnode[0])
      toParse.addFirst((pointed: true, node: cnode[2]))
      toParse.addFirst((pointed: false, node: cnode[1]))
    of nnkCurlyExpr:
      result.pureCode = cnode[1]
      checkName()
    of nnkCurly:
      result.pureCode = cnode[0]
    of nnkBracketExpr:
      result.packArgs = cnode[1 .. cnode.high]
      checkName()
    of nnkBracket:
      result.packArgs = cnode[0 .. ^1]
    of nnkPar:
      if pointed:
        result.eventBindings = cnode[0 .. ^1]
      else:
        result.initParameters = cnode[0 .. ^1]
    of nnkCall:
      result.initParameters = cnode[1 .. cnode.high]
      checkName()
    of nnkCommand:
      if cnode[cnode.high].kind == nnkIdent:
        result.name = $cnode[cnode.high]
        for i in countdown(cnode.high-1, 0):
          toParse.addFirst((pointed: pointed, node: cnode[i]))
      else:
        for i in countdown(cnode.high, 0):
          toParse.addFirst((pointed: pointed, node: cnode[i]))
    of nnkStmtList:
      result.children = result.parseChildren cnode
    else:
      warning("Found unknown node, this could be an error")
      for child in countdown(cnode.high, 0):
        toParse.addFirst((pointed: pointed, node: cnode[child]))
    if toParse.len != 0:
      var step = toParse.peekFirst()
      cnode = step.node
      pointed = step.pointed
      discard toParse.popFirst()
    else:
      cnode = nil

proc createWidget(widget: ParsedWidget, parent: NimNode = nil): NimNode =
  result = newStmtList()
  var call = newCall(widget.name.toLowerAscii & "_new")
  for param in widget.initParameters:
    call.add param
  widget.generatedSym = genSym(nskVar)
  result.add nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      widget.generatedSym,
      newEmptyNode(),
      call
    )
  )
  proc replacePlaceholder(n: NimNode) =
    for i in 0 .. n.high:
      let child = n[i]
      if child.kind == nnkPrefix and child[0].kind == nnkIdent and child[1].kind == nnkIdent and
        child[0].eqIdent("@") and (child[1].eqIdent("result") or child[1].eqIdent("r")):
          n[i] = widget.generatedSym
          return
      child.replacePlaceholder()

  for child in widget.children:
    for node in createWidget(child, widget.generatedSym):
      result.add node

  if widget.pureCode != nil:
    var l =
      if widget.pureCode.kind == nnkStrLit:
        widget.pureCode.strVal.split(";")
      else:
        widget.pureCode.repr.split("\n")
    widget.pureCode = newStmtList()
    for line in l:
      echo line.strip()
      widget.pureCode.add line.strip().parseStmt
    replacePlaceholder(widget.pureCode)
    result.add(widget.pureCode)

  if parent != nil:
    if widget.packArgs.len == 0:
      result.add newCall("add", parent, widget.generatedSym)
    else:
      var packCall = newCall("pack_start", parent, widget.generatedSym)
      for packArg in widget.packArgs:
        packCall.add packArg
      result.add packCall

  for binding in widget.eventBindings:
    result.add nnkDiscardStmt.newTree(
      newCall(
        "signal_connect",
        widget.generatedSym,
        binding[0],
        newCall(
          newIdentNode("SIGNAL_FUNC"),
          binding[1]
        ),
        newNilLit()
      )
    )

macro genui*(widgetCode: untyped): untyped =
  ## Macro to create Gtk2 code from the genui syntax (see documentation)
  let parsed = nil.parseChildren(widgetCode)
  result = newStmtList()
  for widget in parsed:
    result.add createWidget(widget)
  when defined(debug):
    hint(lineinfo(widgetCode) & " GenUI macro generated this Gtk code:" & result.repr)

macro addElements*(parent:untyped, widgetCode: untyped): untyped=
  ## Macro to create Gtk2 code from the genui syntax (see documentation) and create add calls for the resulting widgets for the given parent
  let parsed = nil.parseChildren(widgetCode)
  result = newStmtList()
  for widget in parsed:
    result.add createWidget(widget, parent)
  when defined(debug):
    hint(lineinfo(widgetCode) & " GenUI macro generated this Gtk code:" & result.repr)

