import gleam/set
import gleam/pair
import gleam/bool
import gleam/dict
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import gleam/regexp
import gleam/option
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
    io.println("Part 2: " <> part2(rules))
}

pub fn part2(rules: List(Rule)) -> String {
    find_swapped_wires(0, "", rules, [])
    |> set.from_list
    |> set.to_list
    |> list.sort(string.compare)
    |> string.join(",")
}

pub fn find_swapped_wires(index: Int, carry: Wire, rules: List(Rule), swapped: List(Wire)) -> List(Wire) {
    let x = "x" <> to_suffix(index)
    let y = "y" <> to_suffix(index)
    let z = "z" <> to_suffix(index)
    case index {
        i if i < 0 -> panic
        i if i > 44 -> swapped
        0 -> {
            let #(sum, carry, swap) = half_adder(x, y, rules)
            let new_swapped = case sum == z {
                True -> list.flatten([swapped, swap])
                False -> list.flatten([swapped, swap, [sum]])
            }
            find_swapped_wires(index + 1, carry, rules, new_swapped)
        }
        _ -> {
            let #(sum, new_carry, swap) = full_adder(x, y, carry, rules)
            let new_swapped = case sum == z {
                True -> list.flatten([swapped, swap])
                False -> list.flatten([swapped, swap, [sum]])
            }
            find_swapped_wires(index + 1, new_carry, rules, new_swapped)
        }
    }
}

pub type Sum = Wire
pub type Carry = Wire

pub fn half_adder(a: Wire, b: Wire, rules: List(Rule)) -> #(Sum, Carry, List(Wire)) {
    let #(sum, swapped_sum) = find(a, b, bool.exclusive_or, rules)
    let #(carry, swapped_carry) = find(a, b, bool.and, rules)

    #(sum, carry, list.flatten([swapped_carry, swapped_sum]))
}

pub fn full_adder(a: Wire, b: Wire, c_in: Wire, rules: List(Rule)) -> #(Sum, Carry, List(Wire)) {
    // A full adder consists of two half adders.
    // https://www.101computing.net/binary-additions-using-logic-gates/
    let #(s1, c1, swapped1) = half_adder(a, b, rules)
    let #(sum, c2, swapped2) = half_adder(c_in, s1, rules)
    let #(c_out, swapped3) = find(c1, c2, bool.or, rules)

    #(sum, c_out, list.flatten([swapped1, swapped2, swapped3]))
}

// Find the `result` field of the rule matching the input targets and operator.
// If an incomplete match was found (op and one of the two targets), the Option(Wire)
// will contain the other wire. This safeguards us from flipped wire outputs.
pub fn find(target1: Wire, target2: Wire, op: Operator, rules: List(Rule)) -> #(Wire, List(Wire)) {
    let match = list.find(rules, fn(rule) {
        { rule.op == op } &&
        {
            { rule.left == target1 && rule.right == target2 } ||
            { rule.right == target1 && rule.left == target2 }
        }
    })
    case match {
        Ok(rule) -> #(rule.result, [])
        Error(_) -> {
            let match_left_target1 = list.find(rules, fn(rule) {
                rule.op == op && rule.left == target1
            })
            let match_left_target2 = list.find(rules, fn(rule) {
                rule.op == op && rule.left == target2
            })
            let match_right_target1 = list.find(rules, fn(rule) {
                rule.op == op && rule.right == target1
            })
            let match_right_target2 = list.find(rules, fn(rule) {
                rule.op == op && rule.right == target2
            })
            // Add the correct wire (taken from the rule) and the
            // incorrect wire (taken from the target) to the swapped list.
            case match_left_target1, match_left_target2, match_right_target1, match_right_target2 {
                Ok(rule), Error(_), Error(_), Error(_) -> #(rule.result, [rule.right, target2])
                Error(_), Ok(rule), Error(_), Error(_) -> #(rule.result, [rule.right, target1])
                Error(_), Error(_), Ok(rule), Error(_) -> #(rule.result, [rule.left, target2])
                Error(_), Error(_), Error(_), Ok(rule) -> #(rule.result, [rule.left, target1])
                _, _, _, _ -> panic
            }
        }
    }
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