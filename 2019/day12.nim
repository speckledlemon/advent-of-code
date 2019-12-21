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
  CelestialBody = tuple
    x: int
    y: int
    z: int
    vx: int
    vy: int
    vz: int

proc parseLine(line: string): CelestialBody =
  var
    x: int
    y: int
    z: int
  if line =~ re"<x=(-?\d+), y=(-?\d+), z=(-?\d+)>":
    x = matches[0].parseInt()
    y = matches[1].parseInt()
    z = matches[2].parseInt()
  (x: x, y: y, z: z, vx: 0, vy: 0, vz: 0)

proc applyGravity(bodies: var seq[CelestialBody]) =
  # ABCD -> AB, AC, AD, BC, BD, CD
  for p in combinations(toSeq(low(bodies)..high(bodies)), 2):
    if bodies[p[0]].x > bodies[p[1]].x:
      bodies[p[0]].vx -= 1
      bodies[p[1]].vx += 1
    elif bodies[p[0]].x < bodies[p[1]].x:
      bodies[p[0]].vx += 1
      bodies[p[1]].vx -= 1
    if bodies[p[0]].y > bodies[p[1]].y:
      bodies[p[0]].vy -= 1
      bodies[p[1]].vy += 1
    elif bodies[p[0]].y < bodies[p[1]].y:
      bodies[p[0]].vy += 1
      bodies[p[1]].vy -= 1
    if bodies[p[0]].z > bodies[p[1]].z:
      bodies[p[0]].vz -= 1
      bodies[p[1]].vz += 1
    elif bodies[p[0]].z < bodies[p[1]].z:
      bodies[p[0]].vz += 1
      bodies[p[1]].vz -= 1

proc applyVelocity(bodies: var seq[CelestialBody]) =
  for b in bodies.mitems:
    b.x += b.vx
    b.y += b.vy
    b.z += b.vz

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
    pe = b.x.abs + b.y.abs + b.z.abs
    ke = b.vx.abs + b.vy.abs + b.vz.abs
    result += pe * ke

proc allVelocitiesAreZero(bodies: seq[CelestialBody]): bool =
  result = true
  for b in bodies:
    if b.vx != 0:
      return false
    elif b.vy != 0:
      return false
    elif b.vz != 0:
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
        (x: -1, y: 0, z: 2, vx: 0, vy: 0, vz: 0),
        (x: 2, y: -10, z: -7, vx: 0, vy: 0, vz: 0),
        (x: 4, y: -8, z: 8, vx: 0, vy: 0, vz: 0),
        (x: 3, y: 5, z: -1, vx: 0, vy: 0, vz: 0)
      ]
    check: exlines.map(l => l.parseLine()) == res
  test "applyGravity":
    var start = @[
        (x: -1, y: 0, z: 2, vx: 0, vy: 0, vz: 0),
        (x: 2, y: -10, z: -7, vx: 0, vy: 0, vz: 0),
        (x: 4, y: -8, z: 8, vx: 0, vy: 0, vz: 0),
        (x: 3, y: 5, z: -1, vx: 0, vy: 0, vz: 0)
      ]
    start.applyGravity()
    check: start == @[
        (x: -1, y: 0, z: 2, vx: 3, vy: -1, vz: -1),
        (x: 2, y: -10, z: -7, vx: 1, vy: 3, vz: 3),
        (x: 4, y: -8, z: 8, vx: -3, vy: 1, vz: -3),
        (x: 3, y: 5, z: -1, vx: -1, vy: -3, vz: 1)
    ]
  test "applyVelocity":
    var start = @[
        (x: -1, y: 0, z: 2, vx: 3, vy: -1, vz: -1),
        (x: 2, y: -10, z: -7, vx: 1, vy: 3, vz: 3),
        (x: 4, y: -8, z: 8, vx: -3, vy: 1, vz: -3),
        (x: 3, y: 5, z: -1, vx: -1, vy: -3, vz: 1)
    ]
    start.applyVelocity()
    check: start == @[
        (x: 2, y: -1, z: 1, vx: 3, vy: -1, vz: -1),
        (x: 3, y: -7, z: -4, vx: 1, vy: 3, vz: 3),
        (x: 1, y: -7, z: 5, vx: -3, vy: 1, vz: -3),
        (x: 2, y: 2, z: 0, vx: -1, vy: -3, vz: 1)      
    ]
  test "step":
    var
      start = @[
        (x: -1, y: 0, z: 2, vx: 0, vy: 0, vz: 0),
        (x: 2, y: -10, z: -7, vx: 0, vy: 0, vz: 0),
        (x: 4, y: -8, z: 8, vx: 0, vy: 0, vz: 0),
        (x: 3, y: 5, z: -1, vx: 0, vy: 0, vz: 0)
      ]
    let
      after10 = @[
        (x: 2, y: 1, z: -3, vx: -3, vy: -2, vz: 1),
        (x: 1, y: -8, z: 0, vx: -1, vy: 1, vz: 3),
        (x: 3, y: -6, z: 1, vx: 3, vy: 2, vz: -3),
        (x: 2, y: 0, z: 4, vx: 1, vy: -1, vz: -1)
      ]
    start.step(10)
    check: start == after10
  test "calculateEnergy":
    let after10 = @[
        (x: 2, y: 1, z: -3, vx: -3, vy: -2, vz: 1),
        (x: 1, y: -8, z: 0, vx: -1, vy: 1, vz: 3),
        (x: 3, y: -6, z: 1, vx: 3, vy: 2, vz: -3),
        (x: 2, y: 0, z: 4, vx: 1, vy: -1, vz: -1)
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
  echo "part 2: ", bodies.timeToSeenState()
