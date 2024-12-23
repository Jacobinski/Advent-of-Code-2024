import gleam/set
import gleam/pair
import gleam/int
import gleam/string
import gleam/io
import gleam/list
import gleam/dict
import rememo/memo
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

const infinity = 9999999999999999999999999999999999999999999999999999999

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day21.txt")
    let codes = string.split(contents, "\n")

    io.println("Part 1: " <> int.to_string(part1(codes)))
    io.println("Part 2: " <> int.to_string(part2(codes)))
}

pub fn part1(codes: List(String)) -> Int {
    codes
    |> list.map(fn(code) {
        let assert Ok(num) = int.parse(string.drop_end(code, 1))
        let length = code
            |> numeric_robot
            |> list.map(fn(path) { compute_input_length(path, 2) })
            |> list.fold(infinity, int.min)
        num * length
    })
    |> list.fold(0, int.add)
}

pub fn part2(codes: List(String)) -> Int {
    codes
    |> list.map(fn(code) {
        let assert Ok(num) = int.parse(string.drop_end(code, 1))
        let length = code
            |> numeric_robot
            |> list.map(fn(path) { compute_input_length(path, 25) })
            |> list.fold(infinity, int.min)
        num * length
    })
    |> list.fold(0, int.add)
}

pub fn compute_input_length(command: String, depth: Int) -> Int {
  use cache <- memo.create()
  compute(command, depth, cache)
}

pub fn compute(command: String, depth: Int, cache) -> Int {
    use <- memo.memoize(cache, #(depth, command))
    case depth {
        0 -> string.length(command)
        _ -> {
            subcommands(command)
            |> list.map(fn(cmd) {
                let paths = directional_robot(cmd)
                paths
                |> list.map(fn(p) { compute(p, depth-1, cache) })
                |> list.fold(infinity, int.min)
            })
            |> list.fold(0, int.add)
        }
    }
}

// Splits input string on "A" character. IE. "<^A<AA" -> ["<^A", "<A", "A"]
pub fn subcommands(s: String) -> List(String) {
    s
    |> string.to_graphemes
    |> list.fold(#([], ""), fn(acc, char) {
        let #(words, partial) = acc
        case char {
            "A" -> #([partial <> "A", ..words], "")
            x -> #(words, partial <> x)
        }
    })
    |> pair.first
    |> list.reverse
}

// [[A, B], [C], [D, E]] -> [[A, C, D], [A, C, E], [B, C, D], [B, C, E]]
pub fn segment_join(segments: List(List(String))) -> List(String) {
    segments
    |> list.fold([""], fn(acc, segment) {
        segment
        |> list.map(fn(piece) {
            acc
            |> list.map(fn(prev){ prev <> piece })
        })
        |> list.flatten
    })
}

pub fn numeric_robot(command: String) -> List(String) {
    command
    |> string.to_graphemes
    |> list.fold(#([], NKeyA), fn(acc, key) {
        let #(sequences, prev) = acc
        let curr = to_numeric_key(key)
        let paths = numeric_keypad_paths(prev, curr)
        #([paths, ..sequences], curr)
    })
    |> pair.first
    |> list.reverse
    |> segment_join
}

pub fn directional_robot(command: String) -> List(String) {
    command
    |> string.to_graphemes
    |> list.fold(#([], DKeyA), fn(acc, key) {
        let #(sequences, prev) = acc
        let curr = to_directional_key(key)
        let paths = directional_keypad_paths(prev, curr)
        #([paths, ..sequences], curr)
    })
    |> pair.first
    |> list.reverse
    |> segment_join
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
        True -> list.repeat(">", dx)
        False -> list.repeat("<", -dx)
    }
    let out2 = case dy > 0 {
        True -> list.repeat("v", dy)
        False -> list.repeat("^", -dy)
    }

    let invalid = set.from_list(case from, to {
        NKey7, NKey0 -> ["vvv>"]
        NKey7, NKeyA -> ["vvv>>"]
        NKey4, NKey0 -> ["vv>"]
        NKey4, NKeyA -> ["vv>>"]
        NKey1, NKey0 -> ["v>"]
        NKey1, NKeyA -> ["v>>"]
        NKey0, NKey1 -> ["<^"]
        NKey0, NKey4 -> ["<^^"]
        NKey0, NKey7 -> ["<^^^"]
        NKeyA, NKey1 -> ["<<^"]
        NKeyA, NKey4 -> ["<<^^"]
        NKeyA, NKey7 -> ["<<^^^"]
        _, _ -> []
    })

    [out1, out2]
    |> list.flatten
    |> list.permutations
    |> list.map(fn(x) {string.join(x, "")})
    |> list.filter(fn(x) { False == set.contains(invalid, x) })
    |> list.map(fn(x) { x <> "A"})
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
        True -> list.repeat(">", dx)
        False -> list.repeat("<", -dx)
    }
    let out2 = case dy > 0 {
        True -> list.repeat("v", dy)
        False -> list.repeat("^", -dy)
    }

    let invalid = set.from_list(case from, to {
        DKeyLeft, DKeyUp -> ["^>"]
        DKeyLeft, DKeyA -> ["^>>"]
        DKeyA, DKeyLeft -> ["<<v"]
        DKeyUp, DKeyLeft -> ["<v"]
        _, _ -> []
    })

    [out1, out2]
    |> list.flatten
    |> list.permutations
    |> list.map(fn(x) {string.join(x, "")})
    |> list.filter(fn(x) { False == set.contains(invalid, x) })
    |> list.map(fn(x) { x <> "A"})
}
