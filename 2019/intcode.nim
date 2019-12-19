from algorithm import reversed
from sequtils import map
from strutils import split, parseInt
from sugar import `=>`
import unittest
from itertools import distinctPermutations

const emptyInput = newSeq[int]()

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
    adjustRelativeBase = 9
    halt = 99
  Mode = enum
    position = 0
    immediate = 1
    relative = 2
  OutputMode {.pure.} = enum
    ret
    halt

## The length of an Opcode accounts for the number of arguments it takes, plus
## one for the opcode itself.
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
    of adjustRelativeBase: 2
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

proc extendProgram[T: SomeInteger](program: seq[T], newLen: int): seq[T] =
  result = program
  while result.len < newLen:
    result.add(0)

proc getPtr[T: SomeInteger](tape: seq[T], offset: T, mode: Mode,
    relativeBase: T = 0): T =
  case mode:
    of Mode.position: tape[offset]
    of Mode.immediate: offset
    of Mode.relative: tape[offset] + relativeBase

proc getArg[T: SomeInteger](tape: seq[T], offset: T, mode: Mode,
    relativeBase: T = 0): T =
  let programPtr = getPtr(tape, offset, mode, relativeBase)
  tape[programPtr]

type
  IntcodeComputer = object
    program: seq[int]
    instructionPointer: int
    relativeBase: int
    output: int
    returned: bool
    halted: bool

template extendProgram(mode: Mode): untyped =
  let
    pos = opcode.len - 1
    actualPtr = getPtr(result.program, result.instructionPointer + pos,
                       mode, result.relativeBase)
  if actualPtr > high(result.program):
    result.program = extendProgram(result.program, 2 * actualPtr)
template first(): untyped =
  extendProgram(modes[0])
  getArg(result.program, result.instructionPointer + 1, modes[0],
         result.relativeBase)
template second(): untyped =
  extendProgram(modes[1])
  getArg(result.program, result.instructionPointer + 2, modes[1],
         result.relativeBase)
template res(): untyped =
  let
    pos = opcode.len - 1
    mode = modes[pos - 1]
  extendProgram(mode)
  let actualPtr = getPtr(result.program, result.instructionPointer + pos,
                         mode, result.relativeBase)
  result.program[actualPtr]

proc processProgram[T: SomeInteger](computer: IntcodeComputer, inputs: seq[T],
                                    outputMode: OutputMode = ret): IntcodeComputer =
  result = computer
  result.halted = false
  var inputCounter: T
  while true:
    result = result.step(inputs, outputMode, inputCounter)
    if result.returned:
      break
    else:
      case outputMode:
        of OutputMode.ret:
          if result.output != 0:
            break
        of OutputMode.halt:
          if result.halted:
            break

proc step[T: SomeInteger](computer: IntcodeComputer, inputs: seq[T],
                          outputMode: OutputMode,
                              inputCounter: var T): IntcodeComputer =
  result = computer
  result.returned = false
  var
    modes: seq[Mode]
    opcode: Opcode
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
      case outputMode:
        of OutputMode.ret:
          if result.output != 0:
            result.returned = true
            return result
        of OutputMode.halt:
          result.returned = true
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
    of Opcode.adjustRelativeBase:
      result.relativeBase += first()
      result.instructionPointer += opcode.len
    of Opcode.halt:
      result.instructionPointer += opcode.len
      case outputMode:
        of OutputMode.ret:
          return result
        of OutputMode.halt:
          result.halted = true

proc runAmplifierSequence(phases: openArray[int], program: seq[int],
    signal: int = 0): int =
  assert phases.len == 5
  let
    output1 = IntcodeComputer(program: program).processProgram(@[phases[0],
        signal], OutputMode.halt).output
    output2 = IntcodeComputer(program: program).processProgram(@[phases[1],
        output1], OutputMode.halt).output
    output3 = IntcodeComputer(program: program).processProgram(@[phases[2],
        output2], OutputMode.halt).output
    output4 = IntcodeComputer(program: program).processProgram(@[phases[3],
        output3], OutputMode.halt).output
    output5 = IntcodeComputer(program: program).processProgram(@[phases[4],
        output4], OutputMode.halt).output
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


proc run(unprocessedProgram: seq[int], input: int): int {.discardable.} =
  var computer = IntcodeComputer(program: unprocessedProgram)
  while true:
    computer = computer.processProgram(@[input], OutputMode.halt)
    if computer.halted or computer.returned:
      break
  result = computer.output

suite "intcode_day2":
  test "processProgram":
    check: IntcodeComputer(program: @[1, 0, 0, 0, 99]).processProgram(
        emptyInput, OutputMode.halt).program == @[2, 0, 0, 0, 99]
    check: IntcodeComputer(program: @[2, 3, 0, 3, 99]).processProgram(
        emptyInput, OutputMode.halt).program == @[2, 3, 0, 6, 99]
    check: IntcodeComputer(program: @[2, 4, 4, 5, 99, 0]).processProgram(
        emptyInput, OutputMode.halt).program == @[2, 4, 4, 5, 99, 9801]
    check: IntcodeComputer(program: @[1, 1, 1, 4, 99, 5, 6, 0,
        99]).processProgram(emptyInput, OutputMode.halt).program == @[30, 1, 1,
        4, 2, 5, 6, 0, 99]
    check: IntcodeComputer(program: @[1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40,
        50]).processProgram(emptyInput, OutputMode.halt).program == @[3500, 9,
        10, 70, 2, 3, 11, 0, 99, 30, 40, 50]

suite "intcode_day5":

  test "parseInstruction":
    check: parseInstruction("1002") == (@[Mode.position, Mode.immediate,
                                          Mode.position], Opcode.multiply)
    check: parseInstruction("3") == (@[Mode.position, Mode.position,
                                       Mode.position], Opcode.input)

  test "processProgram1":
    let
      computer1 = IntcodeComputer(program: @[1002, 4, 3, 4, 33]).processProgram(
          @[27], OutputMode.halt)
      computer2 = IntcodeCOmputer(program: @[1101, 100, -1, 4,
          0]).processProgram(@[28], OutputMode.halt)
    check: computer1.output == 0
    check: computer1.program == @[1002, 4, 3, 4, 99]
    check: computer2.output == 0
    check: computer2.program == @[1101, 100, -1, 4, 99]

  test "processProgram2":
    let p1 = @[3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8]
    let c1 = IntcodeComputer(program: p1).processProgram(@[8], OutputMode.halt)
    check: c1.output == 1
    check: c1.program == @[3, 9, 8, 9, 10, 9, 4, 9, 99, 1, 8]
    let c2 = IntcodeComputer(program: p1).processProgram(@[7], OutputMode.halt)
    check: c2.output == 0
    check: c2.program == @[3, 9, 8, 9, 10, 9, 4, 9, 99, 0, 8]
    let p2 = @[3, 3, 1108, -1, 8, 3, 4, 3, 99]
    let c3 = IntcodeComputer(program: p2).processProgram(@[8], OutputMode.halt)
    check: c3.output == 1
    check: c3.program == @[3, 3, 1108, 1, 8, 3, 4, 3, 99]
    let c4 = IntcodeComputer(program: p2).processProgram(@[7], OutputMode.halt)
    check: c4.output == 0
    check: c4.program == @[3, 3, 1108, 0, 8, 3, 4, 3, 99]
    let p3 = @[3, 3, 1107, -1, 8, 3, 4, 3, 99]
    let c5 = IntcodeComputer(program: p3).processProgram(@[7], OutputMode.halt)
    check: c5.output == 1
    check: c5.program == @[3, 3, 1107, 1, 8, 3, 4, 3, 99]
    let c6 = IntcodeComputer(program: p3).processProgram(@[8], OutputMode.halt)
    check: c6.output == 0
    check: c6.program == @[3, 3, 1107, 0, 8, 3, 4, 3, 99]

    let p4 = @[3, 12, 6, 12, 15, 1, 13, 14, 13, 4, 13, 99, -1, 0, 1, 9]
    let c7 = IntcodeComputer(program: p4).processProgram(@[0], OutputMode.halt)
    check: c7.output == 0
    let c8 = IntcodeComputer(program: p4).processProgram(@[2], OutputMode.halt)
    check: c8.output == 1

    let p5 = @[3, 3, 1105, -1, 9, 1101, 0, 0, 12, 4, 12, 99, 1]
    let c9 = IntcodeComputer(program: p5).processProgram(@[0], OutputMode.halt)
    check: c9.output == 0
    let c10 = IntcodeComputer(program: p5).processProgram(@[2], OutputMode.halt)
    check: c10.output == 1

    let p6 = @[3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21, 20, 1006, 20,
        31, 1106, 0, 36, 98, 0, 0, 1002, 21, 125, 20, 4, 20, 1105, 1, 46, 104,
        999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98, 99]
    let c11 = IntcodeComputer(program: p6).processProgram(@[7], OutputMode.halt)
    check: c11.output == 999
    let c12 = IntcodeComputer(program: p6).processProgram(@[8], OutputMode.halt)
    check: c12.output == 1000
    let c13 = IntcodeComputer(program: p6).processProgram(@[9], OutputMode.halt)
    check: c13.output == 1001

  suite "intcode_day7":
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

  suite "intcode_day9":
    test "parseInstruction":
      check: parseInstruction("103") == (@[Mode.immediate, Mode.position,
                                           Mode.position], Opcode.input)
      check: parseInstruction("203") == (@[Mode.relative, Mode.position,
                                           Mode.position], Opcode.input)
      check: parseInstruction("204") == (@[Mode.relative, Mode.position,
                                           Mode.position], Opcode.output)
      check: parseInstruction("109") == (@[Mode.immediate, Mode.position,
                                           Mode.position],
                                           Opcode.adjustRelativeBase)

    test "extendProgram":
      let
        tp1 = @[-1]
        tp2 = @[1, 2, 3, 4]
      check: extendProgram(tp1, 4) == @[-1, 0, 0, 0]
      check: extendProgram(tp2, 2) == @[1, 2, 3, 4]

    test "computer0":
      let program0 = stringToProgram("109,19,204,-34")
      var
        computer0 = IntcodeComputer(program: program0, relativeBase: 2000)
        inputCounter0 = 0
      computer0 = computer0.step(emptyInput, ret, inputCounter0)
      check: computer0.instructionPointer == 2
      check: computer0.relativeBase == 2019
      computer0 = computer0.step(emptyInput, ret, inputCounter0)
      check: computer0.instructionPointer == 4
      check: computer0.relativeBase == 2019
      check: getPtr(program0, 3, Mode.relative, 2019) == 1985

    test "redditQuine":
      # Program taken from
      # https://www.reddit.com/r/adventofcode/comments/eaboz7/quine_for_preday9_intcode_computer/
      let redditQuineInput = stringToProgram("4,44,8,1,35,41,5,41,36,1,9,1,1,5,13,37,1,3,42,42,8,42,38,43,5,43,39,1,37,40,1,5,31,37,99,87,16,0,2,34,44,0,0,0,4,44,8,1,35,41,5,41,36,1,9,1,1,5,13,37,1,3,42,42,8,42,38,43,5,43,39,1,37,40,1,5,31,37,99,87,16,0,2,34,44,0,0,0")
      var
        redditQuineComputer = IntcodeComputer(program: redditQuineInput)
        redditQuineOutput = newSeq[int]()
      while not redditQuineComputer.halted:
        redditQuineComputer = redditQuineComputer.processProgram(emptyInput,
            OutputMode.halt)
        if not redditQuineComputer.halted:
          redditQuineOutput.add(redditQuineComputer.output)
      check: redditQuineInput == redditQuineOutput

    test "program1":
      let program1 = stringToProgram("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99")
      var
        computer1 = IntcodeComputer(program: program1)
        computer1Output = newSeq[int]()
      while not computer1.halted:
        computer1 = computer1.processProgram(emptyInput, OutputMode.halt)
        if not computer1.halted:
          computer1Output.add(computer1.output)
      check: program1 == computer1Output

    test "programs2and3":
      let
        computer2 = IntcodeComputer(program: stringToProgram("1102,34915192,34915192,7,4,7,99,0"))
        computer3 = IntcodeComputer(program: stringToProgram("104,1125899906842624,99"))
      check: computer2.processProgram(emptyInput, OutputMode.halt).output ==
          34915192 * 34915192
      check: computer3.processProgram(emptyInput, OutputMode.halt).output == 1125899906842624

    # TODO link to where this was taken from
    test "program4":
      let
        computer4inputval = 69
        computer4input = @[computer4inputval]
        computer4program = @[109, 1, 203, 2, 204, 2, 99]
        computer4modifiedProgram = @[109, 1, 203, computer4inputval, 204, 2, 99]
      var
        computer4 = IntcodeComputer(program: computer4program)
        inputCounter = 0

      check: parseInstruction($computer4.program[
          computer4.instructionPointer]) == (@[immediate, position, position], adjustRelativeBase)
      computer4 = computer4.step(emptyInput, OutputMode.ret, inputCounter)
      check: computer4.instructionPointer == 2
      check: computer4.relativeBase == 1
      check: computer4.output == 0
      check: computer4.program == computer4program
      check: parseInstruction($computer4.program[
          computer4.instructionPointer]) == (@[relative, position, position], input)
      check: getPtr(computer4.program, computer4.instructionPointer + 1,
          relative, computer4.relativeBase) == 3
      check: getPtr(computer4program, 2 + 1, relative, 1) == 3
      computer4 = computer4.step(computer4input, OutputMode.ret, inputCounter)
      check: computer4.instructionPointer == 4
      check: computer4.relativeBase == 1
      check: computer4.output == 0
      check: computer4.program == computer4modifiedProgram
      check: parseInstruction($computer4.program[
          computer4.instructionPointer]) == (@[relative, position, position], output)
      computer4 = computer4.step(emptyInput, OutputMode.ret, inputCounter)
      check: computer4.instructionPointer == 6
      check: computer4.relativeBase == 1
      check: computer4.output == computer4inputval
