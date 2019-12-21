import re
import sequtils
import strutils
import sugar
import ./aoc_utils
import unittest
# `nimble install itertools`
import itertools
# `nimble install timeit`
import timeit

type
  CelestialBody = array[6, int]

proc parseLine(line: string): CelestialBody =
  var
    x: int
    y: int
    z: int
  if line =~ re"<x=(-?\d+), y=(-?\d+), z=(-?\d+)>":
    x = matches[0].parseInt()
    y = matches[1].parseInt()
    z = matches[2].parseInt()
  [x, y, z, 0, 0, 0]

proc applyGravity(bodies: var seq[CelestialBody]) =
  # ABCD -> AB, AC, AD, BC, BD, CD
  for p in combinations(toSeq(low(bodies)..high(bodies)), 2):
    for dim in 0..2:
      if bodies[p[0]][dim] > bodies[p[1]][dim]:
        bodies[p[0]][dim + 3] -= 1
        bodies[p[1]][dim + 3] += 1
      elif bodies[p[0]][dim] < bodies[p[1]][dim]:
        bodies[p[0]][dim + 3] += 1
        bodies[p[1]][dim + 3] -= 1

proc applyVelocity(bodies: var seq[CelestialBody]) =
  for b in bodies.mitems:
    b[0] += b[3]
    b[1] += b[4]
    b[2] += b[5]

proc step(bodies: var seq[CelestialBody]) =
  bodies.applyGravity()
  bodies.applyVelocity()
proc step(bodies: var seq[CelestialBody], numSteps: Positive) =
  for i in 1..numSteps:
    bodies.step()

proc calculateEnergy(bodies: seq[CelestialBody]): int =
  var
    pe: int
    ke: int
  for b in bodies:
    pe = b[0].abs + b[1].abs + b[2].abs
    ke = b[3].abs + b[4].abs + b[5].abs
    result += pe * ke

proc allVelocitiesAreZero(bodies: seq[CelestialBody]): bool =
  result = true
  for b in bodies:
    if b[3] != 0:
      return false
    elif b[4] != 0:
      return false
    elif b[5] != 0:
      return false

proc timeToSeenState(bodies: seq[CelestialBody]): int {.discardable.} =
  var
    currentState = deepCopy(bodies)
  result = 1
  while true:
    currentState.step()
    if currentState.allVelocitiesAreZero():
      result *= 2
      break
    result += 1

suite "day12":
  test "parseLine":
    let
      exlines = """
<x=-1, y=0, z=2>
<x=2, y=-10, z=-7>
<x=4, y=-8, z=8>
<x=3, y=5, z=-1>
""".strip().split("\n")
      res = @[
        [-1, 0, 2, 0, 0, 0],
        [2, -10, -7, 0, 0, 0],
        [4, -8, 8, 0, 0, 0],
        [3, 5, -1, 0, 0, 0]
      ]
    check: exlines.map(l => l.parseLine()) == res
  test "applyGravity":
    var start = @[
        [-1, 0, 2, 0, 0, 0],
        [2, -10, -7, 0, 0, 0],
        [4, -8, 8, 0, 0, 0],
        [3, 5, -1, 0, 0, 0]
      ]
    start.applyGravity()
    check: start == @[
        [-1, 0, 2, 3, -1, -1],
        [2, -10, -7, 1, 3, 3],
        [4, -8, 8, -3, 1, -3],
        [3, 5, -1, -1, -3, 1]
    ]
  test "applyVelocity":
    var start = @[
        [-1, 0, 2, 3, -1, -1],
        [2, -10, -7, 1, 3, 3],
        [4, -8, 8, -3, 1, -3],
        [3, 5, -1, -1, -3, 1]
    ]
    start.applyVelocity()
    check: start == @[
        [2, -1, 1, 3, -1, -1],
        [3, -7, -4, 1, 3, 3],
        [1, -7, 5, -3, 1, -3],
        [2, 2, 0, -1, -3, 1]
    ]
  test "step":
    var
      start = @[
        [-1, 0, 2, 0, 0, 0],
        [2, -10, -7, 0, 0, 0],
        [4, -8, 8, 0, 0, 0],
        [3, 5, -1, 0, 0, 0]
      ]
    let
      after10 = @[
        [2, 1, -3, -3, -2, 1],
        [1, -8, 0, -1, 1, 3],
        [3, -6, 1, 3, 2, -3],
        [2, 0, 4, 1, -1, -1]
      ]
    start.step(10)
    check: start == after10
  test "calculateEnergy":
    let after10 = @[
        [2, 1, -3, -3, -2, 1],
        [1, -8, 0, -1, 1, 3],
        [3, -6, 1, 3, 2, -3],
        [2, 0, 4, 1, -1, -1]
      ]
    check: after10.calculateEnergy() == 179
  test "timeToSeenState":
    let
      ex1 = """
<x=-1, y=0, z=2>
<x=2, y=-10, z=-7>
<x=4, y=-8, z=8>
<x=3, y=5, z=-1>
""".strip().split("\n").map(l => l.parseLine())
      ex2 = """
<x=-8, y=-10, z=0>
<x=5, y=5, z=10>
<x=2, y=-7, z=3>
<x=9, y=-8, z=-3>
""".strip().split("\n").map(l => l.parseLine())
    check: ex1.timeToSeenState() == 2772
    echo timeGo(ex1.timeToSeenState())
    # check: ex2.timeToSeenState() == 4686774924

when isMainModule:
  var bodies = readAllLines("day12_input.txt").map(l => l.parseLine())
  bodies.step(1000)
  echo "part 1: ", bodies.calculateEnergy()
  # echo "part 2: ", bodies.timeToSeenState()
