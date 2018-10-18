type Stack*[T] = seq[T]

proc newStack*[T](): Stack[T] =
  newSeq[T]()

proc push*[T](stack: var Stack[T], elem: T) =
  stack.add(elem)

proc pop*[T](stack: var Stack[T]): T =
  result = stack[stack.high]
  stack.setLen(stack.high)

when isMainModule:
  import macros

  macro something(): untyped =
    result = newStmtList()
    var stack = newStack[int]()

    stack.push(5)
    stack.push(100)
    echo stack.len
    echo stack.pop()
    echo stack.len
    echo stack.pop()
    echo stack.len

  something()
