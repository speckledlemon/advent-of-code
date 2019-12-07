from algorithm import reversed
from sequtils import map
from strutils import split, parseBiggestInt
# from sugar import `=>`
import ./aoc_utils

type
  Opcode = enum
    add, multiply, input, output, halt
  Mode = enum
    position, immediate

proc modeCharToMode(mc: char): Mode =
  # Why bother?
  # case parseBiggestInt($mc):
  #   of 0: Mode.position
  #   of 1: Mode.immediate
  case mc:
    of '0': Mode.position
    of '1': Mode.immediate
    else: raise

proc parseInstruction(instruction: string): (seq[Mode], Opcode) =
  let
    h = high(instruction)
    modeStr = instruction[low(instruction)..(h - 2)]
    opcodeStr = instruction[(h - 1)..h]
    opcode = case parseBiggestInt(opcodeStr):
               of 1: Opcode.add
               of 2: Opcode.multiply
               of 3: Opcode.input
               of 4: Opcode.output
               of 99: Opcode.halt
               else: raise
  var
    splitModes = reversed(modeStr)
  while splitModes.len < 3:
    splitModes.add('0')
  let modes = map(splitModes, modeCharToMode)
  # echo low(instruction), " ", h - 2, " ", h - 1, " ", h
  # echo modeStr, " ", opcodeStr, " ", opcode, " ", modes
  result = (modes, opcode)

proc getArg[T: SomeInteger](tape: seq[T], offset: T, mode: Mode): T =
  case mode:
    of Mode.position: tape[tape[offset]]
    of Mode.immediate: tape[offset]

proc processProgram[T: SomeSignedInt](input: T, state: seq[T]): seq[T] =
  # make a mutable copy of the input
  result = newSeq[T]()
  for i in low(state)..high(state):
    result.add(state[i])
  ##########
  var startIdx: T = 0
  while (startIdx + 4) <= T(high(result)):
    let (modes, opcode) = parseInstruction($result[startIdx])
    case opcode:
      of Opcode.add:
        let a1 = getArg(result, startIdx + 1, modes[0])
        let a2 = getArg(result, startIdx + 2, modes[1])
        assert modes[2] == Mode.position
        result[result[startIdx + 3]] = a1 + a2
        startIdx += 4
      of Opcode.multiply:
        let a1 = getArg(result, startIdx + 1, modes[0])
        let a2 = getArg(result, startIdx + 2, modes[1])
        assert modes[2] == Mode.position
        result[result[startIdx + 3]] = a1 * a2
        startIdx += 4
      of Opcode.input:
        assert modes[0] == Mode.position
        result[result[startIdx + 1]] = input
        startIdx += 2
      of Opcode.output:
        assert modes[0] == Mode.position
        echo "output: ", result[result[startIdx + 1]]
        startIdx += 2
      of Opcode.halt:
        assert modes[0] == Mode.position
        startIdx += 1

when isMainModule:
  # var unprocessedProgram = readAllLines("day5_input.txt")[0].split(',').map(i => parseBiggestInt(i))
  doAssert parseInstruction("1002") == (@[Mode.position, Mode.immediate, Mode.position], Opcode.multiply)
  doAssert processProgram(27, @[1002, 4, 3, 4, 33]) == @[1002, 4, 3, 4, 99]
  # echo processProgram(69, @[3, 0, 4, 0, 99])
