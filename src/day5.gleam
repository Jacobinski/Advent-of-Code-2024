import gleam/int
import gleam/option
import gleam/dict
import gleam/list
import gleam/io
import gleam/string
import simplifile as file

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day5.txt")
    let #(rules, updates) = parse(contents)
    io.println("Part 1: " <> int.to_string(part1(rules, updates)))
    io.println("Part 2: " <> int.to_string(part2(rules, updates)))
}

/// Splits the file into lists of "rules" and "updates"
fn parse(contents: String) -> #(List(String), List(String)) {
    let lines = string.split(contents, "\n")
    let #(rules, updates) = list.split_while(lines, fn(line) { line != "" })
    let updates = list.drop(updates, 1)
    #(rules, updates)
}

/// Creates an "inverse rules" dictionary which, given a number, tells you
/// which numbers are not allowed after it.
fn inverse_rules(rules: List(String)) -> dict.Dict(String, List(String)) {
    rules
    |> list.map(fn(x) {
        let assert [l, r] = string.split(x, "|")
        #(r, l)
    })
    |> list.fold(dict.new(), fn(d, tup) {
        let #(key, value) = tup
        case dict.get(d, key) {
            Ok(array) -> dict.insert(d, key, list.append(array, [value]))
            Error(_) -> dict.insert(d, key, [value])
        }
    })
}

/// Checks if a rulebook update list is valid.
fn update_is_valid(update: List(String), inverse_rules: dict.Dict(String, List(String))) -> Bool {
    case list.fold(update, #(True, []), fn(tup, num) {
        let #(valid, forbidden) = tup
        let num_is_valid = list.contains(forbidden, num) == False
        let new_forbidden = case dict.get(inverse_rules, num) {
            Ok(arr) -> arr
            Error(_) -> []
        }
        #(valid && num_is_valid, list.append(forbidden, new_forbidden))
    }) {
        #(True, _) -> True
        #(False, _) -> False
    }
}

fn part1(rules: List(String), updates: List(String)) -> Int {
    let inverse_rules = inverse_rules(rules)

    let valid_updates = updates
        |> list.map(string.split(_, ","))
        |> list.filter(update_is_valid(_, inverse_rules))

    let assert Ok(sum_of_medians) = valid_updates
        |> list.map(fn(x) {
            let assert Ok(first) = list.drop(x, list.length(x) / 2)
                |> list.first()
            let assert Ok(num) = int.parse(first)
            num
        })
        |> list.reduce(int.add)

    sum_of_medians
}

fn find_violation(update: List(String), rules: List(String)) -> option.Option(#(String, String)) {
    let inverse_rules = inverse_rules(rules)
    let violation_tuple = list.fold(update, #([], dict.new(), option.None), fn(tup, num) {
        // The "forbidden" array tracks which numbers are not allowed.
        // The "reason" dict tracks (forbidden_num: what made it forbidden)
        // The "violation" tuple tracks the first known violation.
        let #(forbidden, reason, violation) = tup
        let is_valid = list.contains(forbidden, num) == False
        let new_forbidden = case dict.get(inverse_rules, num) {
            Ok(arr) -> arr
            Error(_) -> []
        }

        let new_violation = case is_valid {
            True -> option.None
            False -> {
                let assert Ok(r) = dict.get(reason, num)
                option.Some(#(r, num))
            }
        }
        let new_reason = new_forbidden
            |> list.map(fn(v) { #(v, num) })
            |> dict.from_list

        #(
            list.append(forbidden, new_forbidden),
            dict.merge(reason, new_reason),
            option.or(violation, new_violation)
        )
    })
    violation_tuple.2
}

/// Recursively swaps invalid elements in the list until it is valid.
fn fix_violations(update: List(String), rules: List(String)) -> List(String) {
    case find_violation(update, rules) {
        option.None -> update
        option.Some(#(x, y)) -> {
            let new = swap(update, x, y)
            fix_violations(new, rules)
        }
    }
}

/// Swaps the `from` and `to` elements in the list
fn swap(update: List(String), from: String, to: String) -> List(String) {
    list.map(update, fn(x) {
        case x == from, x == to {
            True, _ -> to
            _, True -> from
            False, False -> x
        }
    })
}


fn part2(rules: List(String), updates: List(String)) -> Int {
    let inverse_rules = inverse_rules(rules)

    let invalid_updates = updates
        |> list.map(string.split(_, ","))
        |> list.filter(fn(u) { update_is_valid(u, inverse_rules) == False })

    let fixed_updates = invalid_updates
        |> list.map(fn(update){
            fix_violations(update, rules)
        })

    let assert Ok(sum_of_medians) = fixed_updates
        |> list.map(fn(x) {
            let assert Ok(first) = list.drop(x, list.length(x) / 2)
                |> list.first()
            let assert Ok(num) = int.parse(first)
            num
        })
        |> list.reduce(int.add)

    sum_of_medians
}