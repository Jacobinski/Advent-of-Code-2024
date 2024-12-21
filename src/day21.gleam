import gleam/pair
import gleam/int
import gleam/string
import gleam/io
import gleam/list
import gleam/order
import gleam/dict
import simplifile as file

pub type NumericKey {
    NKey0
    NKey1
    NKey2
    NKey3
    NKey4
    NKey5
    NKey6
    NKey7
    NKey8
    NKey9
    NKeyA
}

pub type DirectionalKey {
    DKeyUp
    DKeyDown
    DKeyLeft
    DKeyRight
    DKeyA
}

const infinity = 999999999

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day21.txt")
    let codes = string.split(contents, "\n")

    io.println("Part 1: " <> int.to_string(part1(codes)))
}

pub fn part1(codes: List(String)) -> Int {
    codes
    |> list.map(fn(code) {
        let assert Ok(num) = int.parse(string.drop_end(code, 1))
        let length = code
            |> numeric_robot
            |> list.flat_map(fn(code) { directional_robot(code) })
            |> list.flat_map(fn(code) { directional_robot(code) })
            |> list.map(string.length)
            |> list.fold(infinity, fn(best, curr) {
                case curr < best {
                    True -> curr
                    False -> best
                }
            })
        num * length
    })
    |> list.fold(0, int.add)
}

pub fn numeric_robot(command: String) -> List(String) {
    let all_paths_segments = command
        |> string.to_graphemes
        |> list.fold(#([], NKeyA), fn(acc, key) {
            let #(sequences, prev) = acc
            let curr = to_numeric_key(key)
            let paths = numeric_keypad_paths(prev, curr)
            #(list.append(sequences, [paths]), curr)
        })
        |> pair.first
    let all_paths = all_paths_segments
        |> list.fold([""], fn(acc, segments) {
            segments
            |> list.map(fn(segment) {
                acc
                |> list.map(fn(prev){
                    prev <> segment
                })
            })
            |> list.flatten
        })
    let shortest_paths = all_paths
        |> list.fold([], fn(acc, candidate) {
            case acc {
                [] -> [candidate]
                [best, .._] -> case int.compare(string.length(best), string.length(candidate)) {
                    order.Lt -> acc
                    order.Eq -> [candidate, ..acc]
                    order.Gt -> [candidate]
                }

            }
        })
    shortest_paths
}

pub fn directional_robot(command: String) -> List(String) {
    let all_paths_segments = command
        |> string.to_graphemes
        |> list.fold(#([], DKeyA), fn(acc, key) {
            let #(sequences, prev) = acc
            let curr = to_directional_key(key)
            let paths = directional_keypad_paths(prev, curr)
            #(list.append(sequences, [paths]), curr)
        })
        |> pair.first
    let all_paths = all_paths_segments
        |> list.fold([""], fn(acc, segments) {
            segments
            |> list.map(fn(segment) {
                acc
                |> list.map(fn(prev){
                    prev <> segment
                })
            })
            |> list.flatten
        })
    let shortest_paths = all_paths
        |> list.fold([], fn(acc, candidate) {
            case acc {
                [] -> [candidate]
                [best, .._] -> case int.compare(string.length(best), string.length(candidate)) {
                    order.Lt -> acc
                    order.Eq -> [candidate, ..acc]
                    order.Gt -> [candidate]
                }

            }
        })
    shortest_paths
}

pub fn to_numeric_key(str: String) -> NumericKey {
    case str {
        "0" -> NKey0
        "1" -> NKey1
        "2" -> NKey2
        "3" -> NKey3
        "4" -> NKey4
        "5" -> NKey5
        "6" -> NKey6
        "7" -> NKey7
        "8" -> NKey8
        "9" -> NKey9
        "A" -> NKeyA
        _ -> panic
    }
}

pub fn to_directional_key(str: String) -> DirectionalKey {
    case str {
        "^" -> DKeyUp
        ">" -> DKeyRight
        "v" -> DKeyDown
        "<" -> DKeyLeft
        "A" -> DKeyA
        _ -> panic
    }
}

pub fn numeric_keypad_paths(from: NumericKey, to: NumericKey) -> List(String) {
    let positions = dict.from_list([
        #(NKey7, #(0, 0)),
        #(NKey8, #(1, 0)),
        #(NKey9, #(2, 0)),
        #(NKey4, #(0, 1)),
        #(NKey5, #(1, 1)),
        #(NKey6, #(2, 1)),
        #(NKey1, #(0, 2)),
        #(NKey2, #(1, 2)),
        #(NKey3, #(2, 2)),
        #(NKey0, #(1, 3)),
        #(NKeyA, #(2, 3)),
    ])
    let assert Ok(#(fx, fy)) = dict.get(positions, from)
    let assert Ok(#(tx, ty)) = dict.get(positions, to)
    let dx = tx - fx
    let dy = ty - fy
    let out1 = case dx > 0 {
        True -> string.repeat(">", dx)
        False -> string.repeat("<", -dx)
    }
    let out2 = case dy > 0 {
        True -> string.repeat("v", dy)
        False -> string.repeat("^", -dy)
    }

    // Optimize for the robot inputting each key press.
    // It prefers to keep pressing the same key, instead of switching between
    // keys (eg. ^^< is better than ^<^).
    // In some cases, these preferences would put us over the hole of death.
    // Do our best to avoid it
    let force_vertical = {from == NKeyA || from == NKey0}
        && {to == NKey1 || to == NKey4 || to == NKey7}
    let force_horizontal = {from == NKey1 || from == NKey4 || from == NKey7}
        && {to == NKeyA || to == NKey0}

    case force_vertical, force_horizontal {
        True, True -> panic
        True, False -> [out2 <> out1 <> "A"]
        False, True -> [out1 <> out2 <> "A"]
        False, False -> case dx == 0 || dy == 0 {
            True -> [out1 <> out2 <> "A"]
            False -> [out1 <> out2 <> "A", out2 <> out1 <> "A"]
        }
    }
}

pub fn directional_keypad_paths(from: DirectionalKey, to: DirectionalKey) -> List(String) {
    let positions = dict.from_list([
        #(DKeyUp, #(1, 0)),
        #(DKeyA, #(2, 0)),
        #(DKeyLeft, #(0, 1)),
        #(DKeyDown, #(1, 1)),
        #(DKeyRight, #(2, 1)),
    ])
    let assert Ok(#(fx, fy)) = dict.get(positions, from)
    let assert Ok(#(tx, ty)) = dict.get(positions, to)
    let dx = tx - fx
    let dy = ty - fy
    let out1 = case dx > 0 {
        True -> string.repeat(">", dx)
        False -> string.repeat("<", -dx)
    }
    let out2 = case dy > 0 {
        True -> string.repeat("v", dy)
        False -> string.repeat("^", -dy)
    }
    // Optimize for the robot inputting each key press.
    // It prefers to keep pressing the same key, instead of switching between
    // keys (eg. ^^< is better than ^<^).
    // In some cases, these preferences would put us over the hole of death.
    // Do our best to avoid it
    let force_vertical = {from == DKeyUp || from == DKeyA} && to == DKeyLeft
    let force_horizontal = from == DKeyLeft && {to == DKeyUp || to == DKeyA}

    case force_vertical, force_horizontal {
        True, True -> panic
        True, False -> [out2 <> out1 <> "A"]
        False, True -> [out1 <> out2 <> "A"]
        False, False -> case dx == 0 || dy == 0 {
            True -> [out1 <> out2 <> "A"]
            False -> [out1 <> out2 <> "A", out2 <> out1 <> "A"]
        }
    }
}
