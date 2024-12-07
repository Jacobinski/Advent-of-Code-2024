// import gleam/string
import gleam/result
import gleam/pair
import gleam/int
import gleam/string
import gleam/io
import gleam/list
import gleam/set
import gleam/option
import simplifile as file

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day7.txt")
    let calibrations = parse(contents)
    io.println("Part 1: " <> int.to_string(part1(calibrations)))
    io.println("Part 2: " <> int.to_string(part2(calibrations)))
}

fn part1(calibrations: List(#(Int, List(Int)))) -> Int {
    calibrations
    |> list.filter(fn(calibration) {
        let #(total, numbers) = calibration
        let combos = combinations1(option.None, numbers)
        set.contains(combos, total)
    })
    |> list.map(pair.first)
    |> list.reduce(int.add)
    |> result.unwrap(0)
}

fn part2(calibrations: List(#(Int, List(Int)))) -> Int {
    calibrations
    |> list.filter(fn(calibration) {
        let #(total, numbers) = calibration
        let combos = combinations2(option.None, numbers)
        set.contains(combos, total)
    })
    |> list.map(pair.first)
    |> list.reduce(int.add)
    |> result.unwrap(0)
}

fn combinations1(acc: option.Option(Int), nums: List(Int)) -> set.Set(Int) {
    case acc, nums {
        option.Some(acc), [first, ..rest] -> set.union(
            combinations1(option.Some(acc * first), rest),
            combinations1(option.Some(acc + first), rest)
        )
        option.None, [first, ..rest] -> combinations1(option.Some(first), rest)
        option.Some(acc), [] -> set.from_list([acc])
        option.None, [] -> set.new()
    }
}

fn combinations2(acc: option.Option(Int), nums: List(Int)) -> set.Set(Int) {
    case acc, nums {
        option.Some(acc), [first, ..rest] -> [
            combinations2(option.Some(acc * first), rest),
            combinations2(option.Some(acc + first), rest),
            combinations2(option.Some(concat(acc, first)), rest),
        ] |> list.reduce(set.union) |> result.unwrap(set.new())
        option.None, [first, ..rest] -> combinations2(option.Some(first), rest)
        option.Some(acc), [] -> set.from_list([acc])
        option.None, [] -> set.new()
    }
}

fn concat(x: Int, y: Int) -> Int {
    let c = int.to_string(x) <> int.to_string(y)
    int.parse(c) |> result.unwrap(0)
}

fn parse(contents: String) -> List(#(Int, List(Int))) {
    contents
    |> string.split("\n")
    |> list.map(fn(row) {
        let assert [total, parts] = string.split(row, ":")
        let assert Ok(total) = int.parse(total)
        let parts = parts
            |> string.trim()
            |> string.split(" ")
            |> list.map(fn(x) {
                let assert Ok(x) = int.parse(x)
                x
            })
        #(total, parts)
    })
}