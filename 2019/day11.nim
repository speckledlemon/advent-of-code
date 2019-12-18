from strutils import splitLines, strip, join
import sets

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
    panelsPainted: HashSet[Loc]

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
          gridLine.add(point)
        of Point.black:
          # don't need to do anything special
          gridLine.add(point)
        # The string representation is lossy: we don't know what the color of
        # the tile under the robot is, so assume it is black.
        of Point.robotLeft:
          result.robotDir = Direction.left
          result.robotLoc = (x: ic, y: ir)
          gridLine.add(Point.black)
        of Point.robotRight:
          result.robotDir = Direction.right
          result.robotLoc = (x: ic, y: ir)
          gridLine.add(Point.black)
        of Point.robotUp:
          result.robotDir = Direction.up
          result.robotLoc = (x: ic, y: ir)
          gridLine.add(Point.black)
        of Point.robotDown:
          result.robotDir = Direction.down
          result.robotLoc = (x: ic, y: ir)
          gridLine.add(Point.black)
      ic += 1
    result.grid.add(gridLine)
    ir += 1    

## Print the current state of the robot on the hull w/ panel colors in the
## same format as the problem examples, doing the opposite of `toState`.
proc `$`(state: State): string =
  var
    allLines: seq[string]
    line: seq[char]
    ir: uint
    ic: uint
    loc: Loc
  for gridLine in state.grid:
    line = newSeq[char]()
    ic = 0
    for point in gridLine:
      loc = (x: ic, y: ir)
      if loc == state.robotLoc:
        line.add($char(state.robotDir))
      else:
        line.add($char(point))
      ic += 1
    ir += 1
    allLines.add(line.join())
  allLines.join("\n")

const inputToColor = [Point.black, Point.white]

template goDown(): untyped = (Direction.down, (x: robotLoc.x, y: robotLoc.y + 1))
template goUp(): untyped = (Direction.up, (x: robotLoc.x, y: robotLoc.y - 1))
template goLeft(): untyped = (Direction.left, (x: robotLoc.x - 1, y: robotLoc.y))
template goRight(): untyped = (Direction.right, (x: robotLoc.x + 1, y: robotLoc.y))

proc rotateRobot(robotDir: Direction, robotLoc: Loc, input: range[0..1]): (Direction, Loc) =
  # reminder that the coordinate system origin is in the upper left and goes
  # to the bottom right of the grid
  case input:
    # rotate left 90 degrees
    of 0:
      case robotDir:
        of Direction.left: goDown()
        of Direction.right: goUp()
        of Direction.up: goLeft()
        of Direction.down: goRight()
    # rotate right 90 degrees
    of 1:
      case robotDir:
        of Direction.left: goUp()
        of Direction.right: goDown()
        of Direction.up: goRight()
        of Direction.down: goLeft()

proc evolveState(state: State, inputs: seq[int]): State =
  assert inputs.len > 0 and inputs.len <= 2
  result = deepCopy(state)
  # the robot input logic here isn't quite right since the sentinel is never
  # checked for; it just assumes that we always get both inputs at the same
  # time
  let
    paintInput = inputToColor[inputs[0]]
    robotInputSentinel = -1
  var robotInput = robotInputSentinel
  if inputs.len == 2:
    robotInput = inputs[1]
  result.grid[result.robotLoc.y][result.robotLoc.x] = paintInput
  result.panelsPainted.incl(result.robotLoc)
  (result.robotDir, result.robotLoc) = rotateRobot(result.robotDir, result.robotLoc, robotInput)
  # Don't do this; it overwrites the hull color at that grid point
  # result.grid[result.robotLoc.y][result.robotLoc.x] = Point(result.robotDir)

when isMainModule:
  let
    stateStr0 = """
.....
.....
..^..
.....
.....
""".strip()
    state0 = stateStr0.toState()
    stateStr1 = """
.....
.....
.<#..
.....
.....
""".strip()
    state1 = stateStr1.toState()
    stateStr2 = """
.....
.....
..#..
.v...
.....
""".strip()
    state2 = stateStr2.toState()
    stateStr3 = """
.....
.....
..^..
.##..
.....
""".strip()
    state3 = stateStr3.toState()
    stateStr4 = """
.....
..<#.
...#.
.##..
.....
""".strip()
    state4 = stateStr4.toState()
  doAssert $state0 == stateStr0
  var evolvedState = state0.evolveState(@[1, 0])
  # We need to compare against the string representation of the internal
  # state, because TODO
  doAssert $evolvedState == $state1
  evolvedState = evolvedState.evolveState(@[0, 0])
  doAssert $evolvedState == $state2
  evolvedState = evolvedState.evolveState(@[1, 0])
  evolvedState = evolvedState.evolveState(@[1, 0])
  doAssert $evolvedState == $state3
  evolvedState = evolvedState.evolveState(@[0, 1])
  evolvedState = evolvedState.evolveState(@[1, 0])
  evolvedState = evolvedState.evolveState(@[1, 0])
  doAssert $evolvedState == $state4

  let
    f = open("day11_input.txt")
    emptyInput = newSeq[int]()
    # unprocessedProgram = readLine(f).stringtoProgram()
  close(f)
  # echo IntcodeComputer(program: unprocessedProgram).processProgram(emptyInput)
