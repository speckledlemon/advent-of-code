from algorithm import reversed
from sequtils import map
from strutils import split, parseInt
from sugar import `=>`
import math

type
  Opcode = enum
    add, multiply, input, output, halt
  Mode = enum
    position, immediate

proc modeCharToMode(mc: char): Mode =
  case mc:
    of '0': Mode.position
    of '1': Mode.immediate
    else: raise

proc parseInstruction(instruction: string): (seq[Mode], Opcode) =
  assert instruction.len >= 1
  let
    maxNumArguments = 3
    h = high(instruction)
    opcodeStr = if instruction.len == 2: instruction[(h - 1)..h]
                else: $instruction[h]
    opcode = case parseInt(opcodeStr):
               of 1: Opcode.add
               of 2: Opcode.multiply
               of 3: Opcode.input
               of 4: Opcode.output
               of 99: Opcode.halt
               else: raise
    # The given string can be anywhere between 1-5 digits long.
    modeStr = if instruction.len > 1: instruction[low(instruction)..(h - 2)]
              else: ""
  var splitModes = reversed(modeStr)
  while splitModes.len < maxNumArguments:
    splitModes.add('0')
  result = (map(splitModes, modeCharToMode), opcode)

proc getArg[T: SomeInteger](tape: seq[T], offset: T, mode: Mode): T =
  case mode:
    of Mode.position: tape[tape[offset]]
    of Mode.immediate: tape[offset]

proc processProgram[T: SomeInteger](input: T, state: seq[T]): (T, seq[T]) =
  # make a mutable copy of the input
  var tape = newSeq[T]()
  for i in low(state)..high(state):
    tape.add(state[i])
  ##########
  let maxInstructionWidth = 4
  var
    startIdx: T = 0
    output: T
  while (startIdx + maxInstructionWidth) <= T(high(tape)):
    let (modes, opcode) = parseInstruction($tape[startIdx])
    case opcode:
      of Opcode.add:
        # Parameters that an instruction writes to will never be in immediate mode.
        assert modes[2] == Mode.position
        tape[tape[startIdx + 3]] = getArg(tape, startIdx + 1, modes[0]) + getArg(tape, startIdx + 2, modes[1])
        startIdx += 4
      of Opcode.multiply:
        # Parameters that an instruction writes to will never be in immediate mode.
        assert modes[2] == Mode.position
        tape[tape[startIdx + 3]] = getArg(tape, startIdx + 1, modes[0]) * getArg(tape, startIdx + 2, modes[1])
        startIdx += 4
      of Opcode.input:
        # Parameters that an instruction writes to will never be in immediate mode.
        assert modes[0] == Mode.position
        tape[tape[startIdx + 1]] = input
        startIdx += 2
      of Opcode.output:
        output = getArg(tape, startIdx + 1, modes[0])
        if output != 0:
          return (output, tape)
        startIdx += 2
      of Opcode.halt:
        # it looks like the modes are 9, 9, 9
        # assert modes[0] == Mode.position
        startIdx += 1
  (output, tape)

when isMainModule:
  let
    f = open("day5_input.txt")
    unprocessedProgram = readLine(f).split(',').map(i => parseInt(i))
  close(f)
  doAssert parseInstruction("1002") == (@[Mode.position, Mode.immediate, Mode.position], Opcode.multiply)
  doAssert parseInstruction("3") == (@[Mode.position, Mode.position, Mode.position], Opcode.input)
  doAssert processProgram(27, @[1002, 4, 3, 4, 33]) == (0, @[1002, 4, 3, 4, 99])
  doAssert processProgram(28, @[1101, 100, -1, 4, 0]) == (0, @[1101, 100, -1, 4, 99])
  let (p1output, p1tape) = processProgram(1, unprocessedProgram)
  echo "part 1: ", p1output
