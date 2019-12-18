from strutils import splitLines, strip, join
from sequtils import map
from sugar import `=>`

type
  Direction = enum
    left = '<'
    right = '>'
    up = '^'
    down = 'v'
  Point = enum
    white = '#'
    black = '.'
    robotLeft = '<'
    robotRight = '>'
    robotUp = '^'
    robotDown = 'v'
  Grid = seq[seq[Point]]
  Loc = tuple[x: uint, y: uint]
  State = object
    grid: Grid
    robotLoc: Loc
    robotDir: Direction


## Convert a string representation of the hull state to our internal
## representation.
proc toState(str: string): State =
  result = State()
  var
    point: Point
    ir: uint
    ic: uint
    gridLine: seq[Point]
  for line in str.strip().splitLines():
    gridLine = newSeq[Point]()
    ic = 0
    for c in line:
      point = Point(c)
      case point:
        of Point.white:
          # don't need to do anything special
          discard ""
        of Point.black:
          # don't need to do anything special
          discard ""
        of Point.robotLeft:
          result.robotDir = Direction.left
          result.robotLoc = (x: ic, y: ir)
        of Point.robotRight:
          result.robotDir = Direction.right
          result.robotLoc = (x: ic, y: ir)
        of Point.robotUp:
          result.robotDir = Direction.up
          result.robotLoc = (x: ic, y: ir)
        of Point.robotDown:
          result.robotDir = Direction.down
          result.robotLoc = (x: ic, y: ir)
      gridLine.add(point)
      ic += 1
    result.grid.add(gridLine)
    ir += 1    

## Print the current state of the robot on the hull w/ panel colors in the
## same format as the problem examples, doing the opposite of `toState`.
proc `$`(state: State): string =
  var allLines: seq[string]
  for line in state.grid:
    allLines.add(line.map(p => $char(p)).join())
  allLines.join("\n")

when isMainModule:
  let
    state0 = """
.....
.....
..^..
.....
.....
""".strip()
    state1 = """
.....
.....
.<#..
.....
.....
""".strip()
    state2 = """
.....
.....
..#..
.v...
.....
""".strip()
    state3 = """
.....
.....
..^..
.##..
.....
""".strip()
    state4 = """
.....
..<#.
...#.
.##..
.....
""".strip()
  doAssert $state0.toState() == state0
