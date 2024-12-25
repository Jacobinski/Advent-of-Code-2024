import gleam/pair
import gleam/bool
import gleam/option
import gleam/dict
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import gleam/regexp
import simplifile as file

pub type Wire = String
pub type Operator = fn(Bool, Bool) -> Bool
pub type Rule {
    Rule(left: Wire, op: Operator, right: Wire, result: Wire)
}
pub type WireDict = dict.Dict(Wire, Bool)

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day24.txt")
    let #(wires, rules) = parse(contents)

    io.println("Part 1: " <> int.to_string(part1(wires, rules)))

    let wires = dict.from_list([
        // 4
        #("x00", False),
        #("x01", False),
        #("x02", True),
        // 7
        #("y00", True),
        #("y01", True),
        #("y02", True),
    ])
    let rules = generate_full_adder_circuit(2) |> list.map(io_print_rule)
    io.println("Test: " <> int.to_string(part1(wires, rules)))
}

pub fn io_print_rule(rule: Rule) -> Rule {
    // The `case` statement doesn't like the `bool.` prefix
    // This works around the issue.
    let and = bool.and
    let or = bool.or
    let xor = bool.exclusive_or

    let op = case rule.op {
        op if op == and -> " AND "
        op if op == or -> " OR "
        op if op == xor -> " XOR "
        _ -> panic
    }
    io.println(rule.left <> op <> rule.right <> " -> " <> rule.result)
    rule
}

// The logic gates in Part 2 attempt to simulate a full adder circuit.
//  https://www.101computing.net/binary-additions-using-logic-gates/
// We will solve this problem by making a canonical full adder circuit
// and then mapping our known good circuit to the broken circuit.
pub fn generate_full_adder_circuit(bits: Int) -> List(Rule) {
    list.append(
        half_adder(x: "x00", y: "y00", sum: "z00", carry: "c00"),
        list.range(1, bits) |> list.flat_map(full_adder)
    )
    |> list.map(fn(rule) {
        // Make the last rule output a `z` instead of a `c`
        let c_a = "cA" <> to_suffix(bits)
        let c_b = "cB" <> to_suffix(bits)
        let c_out = "c" <> to_suffix(bits)
        let z_out = "z" <> to_suffix(bits + 1)
        let find = Rule(left: c_a, op: bool.or, right: c_b, result: c_out)
        let replace = Rule(left: c_a, op: bool.or, right: c_b, result: z_out)
        case rule == find {
            True -> replace
            False -> rule
        }
    })
}

pub fn half_adder(x x: String, y y: String, sum sum: String, carry carry: String) -> List(Rule) {
    // let x = "x" <> to_suffix(index)
    // let y = "y" <> to_suffix(index)
    // let c = "c" <> to_suffix(index)
    // let z = "z" <> to_suffix(index)
    [
        Rule(left: x, op: bool.exclusive_or, right: y, result: sum),
        Rule(left: x, op: bool.and, right: y, result: carry),
    ]
}

pub fn full_adder(index: Int) -> List(Rule) {
    //  x__ -> input x variable
    //  y__ -> input y variable
    //  z__ -> output z variable
    //  c__ -> output carry variable
    //  sA__ -> intermediate sum variable
    //  cA__ -> intermediate carry variable
    //  cB__ -> intermediate carry variable
    let x = "x" <> to_suffix(index)
    let y = "y" <> to_suffix(index)
    let z = "z" <> to_suffix(index)
    let c_in = "c" <> to_suffix(index-1)
    let c_out = "c" <> to_suffix(index)

    let s_a = "sA" <> to_suffix(index)
    let c_a = "cA" <> to_suffix(index)
    let c_b = "cB" <> to_suffix(index)
    list.flatten(
        [
            half_adder(x: x, y: y, sum: s_a, carry: c_a),
            half_adder(x: c_in, y: s_a, sum: z, carry: c_b),
            [ Rule(left: c_a, op: bool.or, right: c_b, result: c_out) ],
        ]
    )
}

pub fn to_suffix(x: Int) -> String {
    let s = int.to_string(x)
    case x < 10 {
        True -> "0" <> s
        False -> s
    }
}

pub fn part1(wires: WireDict, rules: List(Rule)) -> Int {
    let assert Ok(result) = simulate(wires, rules)
        |> dict.filter(fn(key, _) { string.starts_with(key, "z") })
        |> dict.to_list
        |> list.sort(fn(a, b) { string.compare(pair.first(a), pair.first(b)) })
        |> list.map(fn(wire) {
            case pair.second(wire) {
                True -> "1"
                False -> "0"
            }
        })
        |> list.reverse // LSB is z00
        |> string.concat
        |> int.base_parse(2)
    result
}

pub fn simulate(wires: WireDict, rules: List(Rule)) -> WireDict {
    let simulation = rules
        |> list.fold(#(wires, True), fn(acc, rule) {
            let #(w, success) = acc
            case dict.get(w, rule.left), dict.get(w, rule.right) {
                Ok(l), Ok(r) -> #(
                    dict.insert(w, rule.result, rule.op(l, r)),
                    success && True
                )
                _, _ -> #(w, False)
            }
        })
    let #(new_wires, done) = simulation
    case done {
        True -> new_wires
        False -> simulate(new_wires, rules)
    }
}

pub fn parse(contents: String) -> #(WireDict, List(Rule)) {
    let #(top, bottom) = contents
        |> string.split("\n")
        |> list.split_while(fn(x) { x != "" })
    let bottom = list.drop(bottom, 1)

    let wires = top
        |> list.map(fn(row) {
            let assert [id, s] = string.split(row, ": ")
            let state = case s {
                "1" -> True
                "0" -> False
                _ -> panic
            }
            #(id, state)
        })
        |> dict.from_list

    let assert Ok(re) = regexp.compile(
        "([a-z0-9]+) ([A-Z]+) ([a-z0-9]+) -> ([a-z0-9]+)",
        regexp.Options(False, False)
    )
    let rules = bottom
        |> list.map(fn(row) {
            let assert [match] = regexp.scan(re, row)
            let assert [
                option.Some(left),
                option.Some(operator),
                option.Some(right),
                option.Some(result)
            ] = match.submatches
            let operator = case operator {
                "XOR" -> bool.exclusive_or
                "OR" -> bool.or
                "AND" -> bool.and
                _ -> panic
            }
            Rule(left, operator, right, result)
        })

    #(wires, rules)
}