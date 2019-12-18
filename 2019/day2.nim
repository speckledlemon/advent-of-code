from sequtils import map
from strutils import split, parseBiggestUInt
from sugar import `=>`
import ./aoc_utils
import unittest

proc processProgram[T: SomeInteger](state: seq[T]): seq[T] =
  # make a mutable copy of the input
  result = newSeq[T]()
  for i in low(state)..high(state):
    result.add(state[i])
  var startIdx: T = 0
  while (startIdx + 4) <= T(high(result)):
    let opcode = result[startIdx]
    if opcode == 1:
      result[result[startIdx + 3]] = result[result[startIdx + 1]] + result[result[startIdx + 2]]
      startIdx += 4
    elif opcode == 2:
      result[result[startIdx + 3]] = result[result[startIdx + 1]] * result[result[startIdx + 2]]
      startIdx += 4
    elif opcode == 99:
      startIdx += 1
    else:
      raise

suite "day2":
  test "processProgram":
    check(processProgram(@[1, 0, 0, 0, 99]) == @[2, 0, 0, 0, 99])
    check(processProgram(@[2, 3, 0, 3, 99]) == @[2, 3, 0, 6, 99])
    check(processProgram(@[2, 4, 4, 5, 99, 0]) == @[2, 4, 4, 5, 99, 9801])
    check(processProgram(@[1, 1, 1, 4, 99, 5, 6, 0, 99]) == @[30, 1, 1, 4, 2, 5, 6, 0, 99])
    check(processProgram(@[1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50]) == @[3500, 9, 10, 70, 2, 3, 11, 0, 99, 30, 40, 50])

when isMainModule:
  var unprocessedProgram = readAllLines("day2_input.txt")[0].split(',').map(i => parseBiggestUInt(i))
  unprocessedProgram[1] = 12
  unprocessedProgram[2] = 2
  var output = processProgram(unprocessedProgram)[0]
  echo "part 1: ", output

  for noun in 0..100:
    for verb in 0..100:
      unprocessedProgram[1] = BiggestUInt(noun)
      unprocessedProgram[2] = BiggestUInt(verb)
      output = processProgram(unprocessedProgram)[0]
      if output == 19690720:
        echo "part 2: ", 100 * noun + verb
