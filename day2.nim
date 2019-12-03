from sequtils import map
from strutils import split, parseUInt
import strutils
from sugar import `=>`
import ./aoc_utils

proc processProgram(state: seq[uint]): seq[uint] =
  # make a mutable copy of the input
  result = newSeq[uint]()
  for i in low(state)..high(state):
    result.add(state[i])
  # indices for selecting the tape window
  var
    startIdx: uint = 0
  while (startIdx + 4) <= uint(high(result)):
    let
      opcode = result[startIdx]
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


when isMainModule:
  doAssert processProgram(@[1, 0, 0, 0, 99].map(v => uint(v))) == @[2, 0, 0, 0, 99].map(v => uint(v))
  doAssert processProgram(@[2, 3, 0, 3, 99].map(v => uint(v))) == @[2, 3, 0, 6, 99].map(v => uint(v))
  doAssert processProgram(@[2, 4, 4, 5, 99, 0].map(v => uint(v))) == @[2, 4, 4, 5, 99, 9801].map(v => uint(v))
  doAssert processProgram(@[1, 1, 1, 4, 99, 5, 6, 0, 99].map(v => uint(v))) == @[30, 1, 1, 4, 2, 5, 6, 0, 99].map(v => uint(v))
  doAssert processProgram(@[1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50].map(v => uint(v))) == @[3500, 9, 10, 70, 2, 3, 11, 0, 99, 30, 40, 50].map(v => uint(v))
  var unprocessedProgram = readAllLines("day2_input.txt")[0].split(',').map(i => parseUInt(i))
  unprocessedProgram[1] = 12
  unprocessedProgram[2] = 2
  echo unprocessedProgram
  var output = processProgram(unprocessedProgram)[0]
  echo "part 1: ", output

  for noun in 0..100:
    for verb in 0..100:
      unprocessedProgram[1] = uint(noun)
      unprocessedProgram[2] = uint(verb)
      output = processProgram(unprocessedProgram)[0]
      if output == 19690720:
        echo "part 2: ", 100 * noun + verb
        break
