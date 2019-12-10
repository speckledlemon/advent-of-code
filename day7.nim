from algorithm import reversed
from sequtils import map
from strutils import split, parseInt
from sugar import `=>`

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
    # instructionPointer: int
    output: int
    # paused: bool
    # halted: bool

template first(): untyped = getArg(result.program, startIdx + 1, modes[0])
template second(): untyped = getArg(result.program, startIdx + 2, modes[1])
template res(): untyped = result.program[result.program[startIdx + opcode.len - 1]]

proc processProgram[T: SomeInteger](computer: IntcodeComputer, inputs: seq[T]): IntcodeComputer =
  result = computer
  var
    startIdx: T
    inputCounter: T
    modes: seq[Mode]
    opcode: Opcode
  while true:
    try:
      (modes, opcode) = parseInstruction($result.program[startIdx])
    except RangeError:
      return result
    except IndexError:
      return result
    case opcode:
      of Opcode.add:
        res() = first() + second()
        startIdx += opcode.len
      of Opcode.multiply:
        res() = first() * second()
        startIdx += opcode.len
      of Opcode.input:
        res() = inputs[inputCounter]
        inputCounter += 1
        startIdx += opcode.len
      of Opcode.output:
        result.output = first()
        if result.output != 0:
          return result
        startIdx += opcode.len
      of Opcode.jumpIfTrue:
        startIdx = if first() != 0: second()
                   else: startIdx + opcode.len
      of Opcode.jumpIfFalse:
        startIdx = if first() == 0: second()
                   else: startIdx + opcode.len
      of Opcode.lessThan:
        res() = T(first() < second())
        startIdx += opcode.len
      of Opcode.equals:
        res() = T(first() == second())
        startIdx += opcode.len
      of Opcode.halt:
        startIdx += opcode.len

proc runAmplifierSequence(phases: openArray[int], program: seq[int], signal: int = 0): int =
  assert phases.len == 5
  let
    output1 = IntcodeComputer(program: program).processProgram(@[phases[0], signal]).output
    output2 = IntcodeComputer(program: program).processProgram(@[phases[1], output1]).output
    output3 = IntcodeComputer(program: program).processProgram(@[phases[2], output2]).output
    output4 = IntcodeComputer(program: program).processProgram(@[phases[3], output3]).output
    output5 = IntcodeComputer(program: program).processProgram(@[phases[4], output4]).output
  result = output5

proc runAllPhases(program: seq[int]): int =
  var thrustForPhases: int
  for p in distinctPermutations([0, 1, 2, 3, 4]):
    thrustForPhases = runAmplifierSequence(p, program)
    if thrustForPhases > result:
      result = thrustForPhases

when isMainModule:
  let
    testProgram1 = stringToProgram("3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0")
    testProgram2 = stringToProgram("3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0")
    testProgram3 = stringToProgram("3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0")
  doAssert runAmplifierSequence([4, 3, 2, 1, 0], testProgram1) == 43210
  doAssert runAmplifierSequence([0, 1, 2, 3, 4], testProgram2) == 54321
  doAssert runAmplifierSequence([1, 0, 4, 3, 2], testProgram3) == 65210
  doAssert runAllPhases(testProgram1) == 43210
  doAssert runAllPhases(testProgram2) == 54321
  doAssert runAllPhases(testProgram3) == 65210
  let
    f = open("day7_input.txt")
    unprocessedProgram = readLine(f).stringToProgram()
  close(f)
  let p1output = runAllPhases(unprocessedProgram)
  echo "part 1: ", p1output
