from algorithm import reversed
from sequtils import map
from strutils import split, parseInt
from sugar import `=>`
import timeit
import unittest

# third-party, `nimble install itertools`
from itertools import distinctPermutations

proc stringToProgram(s: string): seq[int] =
  s.split(',').map(i => parseInt(i))

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
  OutputMode {.pure.} = enum
    ret
    halt

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

type
  IntcodeComputer = object
    program: seq[int]
    instructionPointer: int
    output: int
    halted: bool

template first(): untyped =
  getArg(result.program, result.instructionPointer + 1, modes[0])
template second(): untyped =
  getArg(result.program, result.instructionPointer + 2, modes[1])
template res(): untyped =
  result.program[result.program[result.instructionPointer + opcode.len - 1]]

proc processProgram[T: SomeInteger](computer: IntcodeComputer, inputs: seq[T],
    outputMode: OutputMode = ret): IntcodeComputer =
  result = computer
  result.halted = false
  var
    inputCounter: T
    modes: seq[Mode]
    opcode: Opcode
  while true:
    try:
      (modes, opcode) = parseInstruction($result.program[
          result.instructionPointer])
    except RangeError:
      return result
    except IndexError:
      return result
    case opcode:
      of Opcode.add:
        res() = first() + second()
        result.instructionPointer += opcode.len
      of Opcode.multiply:
        res() = first() * second()
        result.instructionPointer += opcode.len
      of Opcode.input:
        res() = inputs[inputCounter]
        inputCounter += 1
        result.instructionPointer += opcode.len
      of Opcode.output:
        result.output = first()
        result.instructionPointer += opcode.len
        case outputMode
        of OutputMode.ret:
          if result.output != 0:
            return result
        of OutputMode.halt:
          return result
      of Opcode.jumpIfTrue:
        result.instructionPointer = if first() != 0: second()
                                    else: result.instructionPointer + opcode.len
      of Opcode.jumpIfFalse:
        result.instructionPointer = if first() == 0: second()
                                    else: result.instructionPointer + opcode.len
      of Opcode.lessThan:
        res() = T(first() < second())
        result.instructionPointer += opcode.len
      of Opcode.equals:
        res() = T(first() == second())
        result.instructionPointer += opcode.len
      of Opcode.halt:
        result.instructionPointer += opcode.len
        case outputMode:
          of OutputMode.ret:
            continue
          of OutputMode.halt:
            result.halted = true
            break

proc runAmplifierSequence(phases: openArray[int], program: seq[int],
    signal: int = 0): int =
  assert phases.len == 5
  let
    output1 = IntcodeComputer(program: program).processProgram(@[phases[0],
        signal]).output
    output2 = IntcodeComputer(program: program).processProgram(@[phases[1],
        output1]).output
    output3 = IntcodeComputer(program: program).processProgram(@[phases[2],
        output2]).output
    output4 = IntcodeComputer(program: program).processProgram(@[phases[3],
        output3]).output
    output5 = IntcodeComputer(program: program).processProgram(@[phases[4],
        output4]).output
  result = output5

proc runAmplifierSequenceFeedback(phases: openArray[int], program: seq[int],
    signal: int = 0): int =
  assert phases.len == 5
  var
    amp1 = IntcodeComputer(program: program).processProgram(@[phases[0],
        signal], OutputMode.halt)
    amp2 = IntcodeComputer(program: program).processProgram(@[phases[1],
        amp1.output], OutputMode.halt)
    amp3 = IntcodeComputer(program: program).processProgram(@[phases[2],
        amp2.output], OutputMode.halt)
    amp4 = IntcodeComputer(program: program).processProgram(@[phases[3],
        amp3.output], OutputMode.halt)
    amp5 = IntcodeComputer(program: program).processProgram(@[phases[4],
        amp4.output], OutputMode.halt)
  while true:
    if not amp1.halted:
      amp1 = amp1.processProgram(@[amp5.output], OutputMode.halt)
    if not amp2.halted:
      amp2 = amp2.processProgram(@[amp1.output], OutputMode.halt)
    if not amp3.halted:
      amp3 = amp3.processProgram(@[amp2.output], OutputMode.halt)
    if not amp4.halted:
      amp4 = amp4.processProgram(@[amp3.output], OutputMode.halt)
    if not amp5.halted:
      amp5 = amp5.processProgram(@[amp4.output], OutputMode.halt)
    else:
      result = amp5.output
      break

proc runAllPhases(program: seq[int], feedbackMode: bool = false): int {.discardable.} =
  var thrustForPhases: int
  let
    allowedPhases = if not feedbackMode: [0, 1, 2, 3, 4]
                    else: [5, 6, 7, 8, 9]
    ampRunner = if not feedbackMode: runAmplifierSequence
                else: runAmplifierSequenceFeedback
  for p in distinctPermutations(allowedPhases):
    thrustForPhases = ampRunner(p, program)
    if thrustForPhases > result:
      result = thrustForPhases

suite "day7":
  test "part1":
    let
      testProgram1 = stringToProgram("3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0")
      testProgram2 = stringToProgram("3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0")
      testProgram3 = stringToProgram("3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0")
    check: runAmplifierSequence([4, 3, 2, 1, 0], testProgram1) == 43210
    check: runAmplifierSequence([0, 1, 2, 3, 4], testProgram2) == 54321
    check: runAmplifierSequence([1, 0, 4, 3, 2], testProgram3) == 65210
    check: runAllPhases(testProgram1) == 43210
    check: runAllPhases(testProgram2) == 54321
    check: runAllPhases(testProgram3) == 65210

  test "part2":
    let
      part2TestProgram1 = stringToProgram("3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5")
      part2TestProgram2 = stringToProgram("3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10")
    check: runAmplifierSequenceFeedback([9, 8, 7, 6, 5], part2TestProgram1) == 139629729
    check: runAmplifierSequenceFeedback([9, 7, 8, 5, 6], part2TestProgram2) == 18216


when isMainModule:
  let
    f = open("day7_input.txt")
    unprocessedProgram = readLine(f).stringToProgram()
  close(f)
  let p1output = runAllPhases(unprocessedProgram)
  echo "part 1: ", p1output

  let p2output = runAllPhases(unprocessedProgram, true)
  echo "part 2: ", p2output

  echo timeGo(runAllPhases(unprocessedProgram))
  echo timeGo(runAllPhases(unprocessedProgram, true))
