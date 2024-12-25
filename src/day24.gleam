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