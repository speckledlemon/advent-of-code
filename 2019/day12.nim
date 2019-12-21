import re
import sequtils
import strutils
import sugar
import ./aoc_utils
import unittest
# `nimble install itertools`
import itertools

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

proc applyGravity(bodies: seq[CelestialBody]): seq[CelestialBody] =
  result = deepCopy(bodies)
  # ABCD -> AB, AC, AD, BC, BD, CD
  for p in combinations(toSeq(low(result)..high(result)), 2):
    if result[p[0]].x > result[p[1]].x:
      result[p[0]].vx -= 1
      result[p[1]].vx += 1
    elif result[p[0]].x < result[p[1]].x:
      result[p[0]].vx += 1
      result[p[1]].vx -= 1
    if result[p[0]].y > result[p[1]].y:
      result[p[0]].vy -= 1
      result[p[1]].vy += 1
    elif result[p[0]].y < result[p[1]].y:
      result[p[0]].vy += 1
      result[p[1]].vy -= 1
    if result[p[0]].z > result[p[1]].z:
      result[p[0]].vz -= 1
      result[p[1]].vz += 1
    elif result[p[0]].z < result[p[1]].z:
      result[p[0]].vz += 1
      result[p[1]].vz -= 1

proc applyVelocity(bodies: seq[CelestialBody]): seq[CelestialBody] =
  result = deepCopy(bodies)
  # `b` is an immutable copy?
  # for b in result:
  #   b.x += b.vx
  #   b.y += b.vy
  #   b.z += b.vz
  for i in low(result)..high(result):
    result[i].x += result[i].vx
    result[i].y += result[i].vy
    result[i].z += result[i].vz

proc step(bodies: seq[CelestialBody]): seq[CelestialBody] =
  bodies.applyGravity().applyVelocity()
proc step(bodies: seq[CelestialBody], numSteps: Positive): seq[CelestialBody] =
  result = deepCopy(bodies)
  for i in 1..numSteps:
    result = result.step()

proc calculateEnergy(bodies: seq[CelestialBody]): int =
  var
    pe: int
    ke: int
  for b in bodies:
    pe = b.x.abs + b.y.abs + b.z.abs
    ke = b.vx.abs + b.vy.abs + b.vz.abs
    result += pe * ke

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
    let start = @[
        (x: -1, y: 0, z: 2, vx: 0, vy: 0, vz: 0),
        (x: 2, y: -10, z: -7, vx: 0, vy: 0, vz: 0),
        (x: 4, y: -8, z: 8, vx: 0, vy: 0, vz: 0),
        (x: 3, y: 5, z: -1, vx: 0, vy: 0, vz: 0)
      ]
    check: start.applyGravity() == @[
        (x: -1, y: 0, z: 2, vx: 3, vy: -1, vz: -1),
        (x: 2, y: -10, z: -7, vx: 1, vy: 3, vz: 3),
        (x: 4, y: -8, z: 8, vx: -3, vy: 1, vz: -3),
        (x: 3, y: 5, z: -1, vx: -1, vy: -3, vz: 1)
    ]
  test "applyVelocity":
    let start = @[
        (x: -1, y: 0, z: 2, vx: 3, vy: -1, vz: -1),
        (x: 2, y: -10, z: -7, vx: 1, vy: 3, vz: 3),
        (x: 4, y: -8, z: 8, vx: -3, vy: 1, vz: -3),
        (x: 3, y: 5, z: -1, vx: -1, vy: -3, vz: 1)
    ]
    check: start.applyVelocity() == @[
        (x: 2, y: -1, z: 1, vx: 3, vy: -1, vz: -1),
        (x: 3, y: -7, z: -4, vx: 1, vy: 3, vz: 3),
        (x: 1, y: -7, z: 5, vx: -3, vy: 1, vz: -3),
        (x: 2, y: 2, z: 0, vx: -1, vy: -3, vz: 1)      
    ]
  test "step":
    let
      start = @[
        (x: -1, y: 0, z: 2, vx: 0, vy: 0, vz: 0),
        (x: 2, y: -10, z: -7, vx: 0, vy: 0, vz: 0),
        (x: 4, y: -8, z: 8, vx: 0, vy: 0, vz: 0),
        (x: 3, y: 5, z: -1, vx: 0, vy: 0, vz: 0)
      ]
      after10 = @[
        (x: 2, y: 1, z: -3, vx: -3, vy: -2, vz: 1),
        (x: 1, y: -8, z: 0, vx: -1, vy: 1, vz: 3),
        (x: 3, y: -6, z: 1, vx: 3, vy: 2, vz: -3),
        (x: 2, y: 0, z: 4, vx: 1, vy: -1, vz: -1)
      ]
    check: start.step(10) == after10
  test "calculateEnergy":
    let after10 = @[
        (x: 2, y: 1, z: -3, vx: -3, vy: -2, vz: 1),
        (x: 1, y: -8, z: 0, vx: -1, vy: 1, vz: 3),
        (x: 3, y: -6, z: 1, vx: 3, vy: 2, vz: -3),
        (x: 2, y: 0, z: 4, vx: 1, vy: -1, vz: -1)
      ]
    check: after10.calculateEnergy() == 179

when isMainModule:
  let bodies = readAllLines("day12_input.txt").map(l => l.parseLine())
  echo "part 1: ", bodies.step(1000).calculateEnergy()
