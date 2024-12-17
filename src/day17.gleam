import gleam/pair
import gleam/float
import gleam/string
import gleam/int
import gleam/io
import gleam/list
import gleam/dict
import gleam/regexp
import gleam/option
import simplifile as file


pub type Computer{
    Computer(a: Int, b: Int, c: Int, pc: Int, out: List(Int))
}
pub type Program = dict.Dict(Int, Int)
pub type ProgramList = List(Int)

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day17.txt")
    let #(computer, program) = parse(contents)

    io.println("Part 1: " <> part1(computer, program))
    io.println("Part 2: " <> int.to_string(part2(computer, program)))
}

pub fn part2(computer: Computer, program: Program) -> Int {
     let target = program
        |> dict.to_list
        |> list.sort(fn(a,b) { int.compare(pair.first(a), pair.first(b))})
        |> list.map(pair.second)

    io.debug(program)
    io.debug(target)

    let solutions = crack(computer, program, target, 1, 0)

    let assert Ok(x) = solutions
        // |> io.debug
        |> list.sort(int.compare)
        |> list.first
    x
}

pub fn power(base: Int, exponent: Int) -> Int {
    let assert Ok(x) = int.power(base, int.to_float(exponent))
    float.round(x)
}

pub fn crack(computer: Computer, program: Program, target: List(Int), length: Int, a_partial: Int) -> List(Int) {
    let max_length = list.length(target)
    case length {
        x if x > max_length -> [a_partial]
        _ -> {
            let partial_target = target
                |> list.reverse
                |> list.split(length)
                |> pair.first
                |> list.reverse

            let candidates = [0, 1, 2, 3, 4, 5, 6, 7]
                |> list.map(fn(x) { {8*a_partial}+x })

            let partial_matches = candidates
                |> list.filter_map(fn(register) {
                    let comp = Computer(..computer, a: register)
                    case partial_target == eval(comp, program) {
                        True -> Ok(register)
                        False -> Error(Nil)
                    }
                })

            partial_matches
            |> list.map(fn(a) { crack(computer, program, target, length+1, a) })
            |> list.flatten
        }
    }
}

pub fn part1(computer: Computer, program: Program) -> String {
    eval(computer, program)
    |> list.map(fn(x) {int.to_string(x)})
    |> string.join(",")
}

pub fn eval(computer: Computer, program: Program) -> List(Int) {
    case opcode(computer, program) {
        Error(_) -> computer.out
        Ok(func) -> {
            let #(computer, program) = func(computer, program)
            eval(computer, program)
        }
    }
}

pub fn adv(computer: Computer, program: Program) -> #(Computer, Program) {
    let assert Ok(operand) = dict.get(program, computer.pc + 1)
    let operand = combo(operand, computer)
    let assert Ok(den) = int.power(2, int.to_float(operand))
    let den = float.round(den)
    let num = computer.a
    #(Computer(..computer, a: num / den, pc: computer.pc + 2), program)
}

pub fn bxl(computer: Computer, program: Program) -> #(Computer, Program) {
    let assert Ok(operand) = dict.get(program, computer.pc + 1)
    let xor = int.bitwise_exclusive_or(computer.b, operand)
    #(Computer(..computer, b: xor, pc: computer.pc + 2), program)
}

pub fn bst(computer: Computer, program: Program) -> #(Computer, Program) {
    let assert Ok(operand) = dict.get(program, computer.pc + 1)
    let operand = combo(operand, computer)
    #(Computer(..computer, b: operand % 8, pc: computer.pc + 2), program)
}

pub fn jnz(computer: Computer, program: Program) -> #(Computer, Program) {
    let assert Ok(operand) = dict.get(program, computer.pc + 1)
    case computer.a {
        0 -> #(Computer(..computer, pc: computer.pc + 2), program)
        _ -> #(Computer(..computer, pc: operand), program)
    }
}

pub fn bxc(computer: Computer, program: Program) -> #(Computer, Program) {
    let xor = int.bitwise_exclusive_or(computer.b, computer.c)
    #(Computer(..computer, b: xor, pc: computer.pc + 2), program)
}

pub fn out(computer: Computer, program: Program) -> #(Computer, Program) {
    let assert Ok(operand) = dict.get(program, computer.pc + 1)
    let operand = combo(operand, computer)
    let out = list.append(computer.out, [operand % 8])
    #(Computer(..computer, out: out, pc: computer.pc + 2), program)
}

pub fn bdv(computer: Computer, program: Program) -> #(Computer, Program) {
    let assert Ok(operand) = dict.get(program, computer.pc + 1)
    let operand = combo(operand, computer)
    let assert Ok(den) = int.power(2, int.to_float(operand))
    let den = float.round(den)
    let num = computer.a
    #(Computer(..computer, b: num / den, pc: computer.pc + 2), program)
}

pub fn cdv(computer: Computer, program: Program) -> #(Computer, Program) {
    let assert Ok(operand) = dict.get(program, computer.pc + 1)
    let operand = combo(operand, computer)
    let assert Ok(den) = int.power(2, int.to_float(operand))
    let den = float.round(den)
    let num = computer.a
    #(Computer(..computer, c: num / den, pc: computer.pc + 2), program)
}

pub fn opcode(computer: Computer, program: Program) -> Result(fn(Computer, Program)->#(Computer, Program), Nil) {
    case dict.get(program, computer.pc) {
        Error(_) -> Error(Nil)
        Ok(code) -> Ok(
            case code {
                0 -> adv
                1 -> bxl
                2 -> bst
                3 -> jnz
                4 -> bxc
                5 -> out
                6 -> bdv
                7 -> cdv
                _ -> panic
            }
        )
    }
}

pub fn combo(x: Int, computer: Computer) -> Int {
    case x {
        0 -> 0
        1 -> 1
        2 -> 2
        3 -> 3
        4 -> computer.a
        5 -> computer.b
        6 -> computer.c
        _ -> panic
    }
}

pub fn parse(contents: String) -> #(Computer, Program) {
    let assert Ok(re) = regexp.compile(
        "Register A: (\\d+)\nRegister B: (\\d+)\nRegister C: (\\d+)\n\nProgram: (\\d+(?:,\\d+)*)",
        regexp.Options(False, False)
    )
    let assert [match] = regexp.scan(re, contents)
    let assert [option.Some(a), option.Some(b), option.Some(c), option.Some(program)] = match.submatches
    let assert [a, b, c] = [a, b, c]
        |> list.map(fn(x) {
            let assert Ok(x) = int.parse(x)
            x
        })
    let program = program
        |> string.split(",")
        |> list.map(fn(x) {
            let assert Ok(x) = int.parse(x)
            x
        })
        |> list.index_map(fn(x, idx) {#(idx, x)})
        |> dict.from_list()

    #(Computer(a, b, c, 0, []), program)
}