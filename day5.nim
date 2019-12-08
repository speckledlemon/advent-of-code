from algorithm import reversed
from sequtils import map
from strutils import split, parseInt
from sugar import `=>`
import timeit

type
  Opcode = enum
    add = 1
    multiply = 2
    input = 3
    output = 4
    jumpIfTrue = 5
    jumpIfFalse = 6
    lessThan = 7
    equals = 8
    halt = 99
  Mode = enum
    position = 0
    immediate = 1

proc len(oc: Opcode): int =
  case oc:
    of add: 4
    of multiply: 4
    of input: 2
    of output: 2
    of jumpIfTrue: 3
    of jumpIfFalse: 3
    of lessThan: 4
    of equals: 4
    of halt: 1

proc parseInstruction(instruction: string): (seq[Mode], Opcode) =
  assert instruction.len >= 1
  let
    maxNumArguments = 3
    h = high(instruction)
    opcodeStr = if instruction.len == 2: instruction[(h - 1)..h]
                else: $instruction[h]
    opcode = Opcode(parseInt(opcodeStr))
    # The given string can be anywhere between 1-5 digits long.
    modeStr = if instruction.len > 1: instruction[low(instruction)..(h - 2)]
              else: ""
  var splitModes = reversed(modeStr)
  while splitModes.len < maxNumArguments:
    splitModes.add('0')
  result = (splitModes.map(c => Mode(parseInt($c))), opcode)

proc getArg[T: SomeInteger](tape: seq[T], offset: T, mode: Mode): T =
  case mode:
    of Mode.position: tape[tape[offset]]
    of Mode.immediate: tape[offset]

proc processProgram[T: SomeInteger](input: T, state: seq[T]): (T, seq[T]) {.discardable.} =
  # make a mutable copy of the input
  var tape = newSeq[T]()
  for i in low(state)..high(state):
    tape.add(state[i])
  ##########
  var
    startIdx: T = 0
    output: T
    modes: seq[Mode]
    opcode: Opcode
  while true:
    try:
      (modes, opcode) = parseInstruction($tape[startIdx])
    except RangeError:
      return (output, tape)
    except IndexError:
      return (output, tape)
    case opcode:
      of Opcode.add:
        assert modes[2] == Mode.position
        tape[tape[startIdx + 3]] = getArg(tape, startIdx + 1, modes[0]) +
            getArg(tape, startIdx + 2, modes[1])
        startIdx += opcode.len
      of Opcode.multiply:
        assert modes[2] == Mode.position
        tape[tape[startIdx + 3]] = getArg(tape, startIdx + 1, modes[0]) *
            getArg(tape, startIdx + 2, modes[1])
        startIdx += opcode.len
      of Opcode.input:
        assert modes[0] == Mode.position
        tape[tape[startIdx + 1]] = input
        startIdx += opcode.len
      of Opcode.output:
        output = getArg(tape, startIdx + 1, modes[0])
        if output != 0:
          return (output, tape)
        startIdx += opcode.len
      of Opcode.jumpIfTrue:
        if getArg(tape, startIdx + 1, modes[0]) != 0:
          startIdx = getArg(tape, startIdx + 2, modes[1])
        else:
          startIdx += opcode.len
      of Opcode.jumpIfFalse:
        if getArg(tape, startIdx + 1, modes[0]) == 0:
          startIdx = getArg(tape, startIdx + 2, modes[1])
        else:
          startIdx += opcode.len
      of Opcode.lessThan:
        assert modes[2] == Mode.position
        if getArg(tape, startIdx + 1, modes[0]) < getArg(tape, startIdx + 2,
            modes[1]):
          tape[tape[startIdx + 3]] = 1
        else:
          tape[tape[startIdx + 3]] = 0
        startIdx += opcode.len
      of Opcode.equals:
        assert modes[2] == Mode.position
        if getArg(tape, startIdx + 1, modes[0]) == getArg(tape, startIdx + 2,
            modes[1]):
          tape[tape[startIdx + 3]] = 1
        else:
          tape[tape[startIdx + 3]] = 0
        startIdx += opcode.len
      of Opcode.halt:
        startIdx += opcode.len

when isMainModule:
  let
    f = open("day5_input.txt")
    unprocessedProgram = readLine(f).split(',').map(i => parseInt(i))
  close(f)
  doAssert parseInstruction("1002") == (@[Mode.position, Mode.immediate,
      Mode.position], Opcode.multiply)
  doAssert parseInstruction("3") == (@[Mode.position, Mode.position,
      Mode.position], Opcode.input)
  doAssert processProgram(27, @[1002, 4, 3, 4, 33]) == (0, @[1002, 4, 3, 4, 99])
  doAssert processProgram(28, @[1101, 100, -1, 4, 0]) == (0, @[1101, 100, -1, 4, 99])
  let (p1output, _) = processProgram(1, unprocessedProgram)
  echo "part 1: ", p1output

  doAssert processProgram(8, @[3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8]) == (1, @[3,
      9, 8, 9, 10, 9, 4, 9, 99, 1, 8])
  doAssert processProgram(7, @[3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8]) == (0, @[3,
      9, 8, 9, 10, 9, 4, 9, 99, 0, 8])
  doAssert processProgram(8, @[3, 3, 1108, -1, 8, 3, 4, 3, 99]) == (1, @[3, 3,
      1108, 1, 8, 3, 4, 3, 99])
  doAssert processProgram(7, @[3, 3, 1108, -1, 8, 3, 4, 3, 99]) == (0, @[3, 3,
      1108, 0, 8, 3, 4, 3, 99])

  doAssert processProgram(7, @[3, 3, 1107, -1, 8, 3, 4, 3, 99]) == (1, @[3, 3,
      1107, 1, 8, 3, 4, 3, 99])
  doAssert processProgram(8, @[3, 3, 1107, -1, 8, 3, 4, 3, 99]) == (0, @[3, 3,
      1107, 0, 8, 3, 4, 3, 99])
  doAssert processProgram(0, @[3, 12, 6, 12, 15, 1, 13, 14, 13, 4, 13, 99, -1,
      0, 1, 9])[0] == 0
  doAssert processProgram(2, @[3, 12, 6, 12, 15, 1, 13, 14, 13, 4, 13, 99, -1,
      0, 1, 9])[0] == 1
  doAssert processProgram(0, @[3, 3, 1105, -1, 9, 1101, 0, 0, 12, 4, 12, 99,
      1])[0] == 0
  doAssert processProgram(2, @[3, 3, 1105, -1, 9, 1101, 0, 0, 12, 4, 12, 99,
      1])[0] == 1

  doAssert processProgram(7, @[3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21,
      20, 1006, 20, 31, 1106, 0, 36, 98, 0, 0, 1002, 21, 125, 20, 4, 20, 1105,
      1, 46, 104, 999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98,
      99])[0] == 999
  doAssert processProgram(8, @[3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21,
      20, 1006, 20, 31, 1106, 0, 36, 98, 0, 0, 1002, 21, 125, 20, 4, 20, 1105,
      1, 46, 104, 999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98,
      99])[0] == 1000
  doAssert processProgram(9, @[3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21,
      20, 1006, 20, 31, 1106, 0, 36, 98, 0, 0, 1002, 21, 125, 20, 4, 20, 1105,
      1, 46, 104, 999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98,
      99])[0] == 1001

  let (p2output, _) = processProgram(5, unprocessedProgram)
  echo "part 2: ", p2output

  echo timeGo(processProgram(1, unprocessedProgram))
  echo timeGo(processProgram(5, unprocessedProgram))
