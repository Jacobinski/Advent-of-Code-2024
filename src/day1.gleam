import gleam/result
import gleam/dict
import gleam/int
import gleam/list
import gleam/io
import gleam/string
import simplifile as file

pub fn main() {
  let assert Ok(contents) = file.read("inputs/day1.txt")
  let #(left, right) = parse(contents)
  io.println("Part 1: " <> int.to_string(part1(left, right)))
  io.println("Part 2: " <> int.to_string(part2(left, right)))
}

fn parse(content: String) -> #(List(Int), List(Int)) {
  content
  |> string.split("\n")
  |> list.fold(#([], []), fn(acc, line) {
    let #(left_acc, right_acc) = acc
    let assert [left, right] = string.split(line, "   ")
    let assert Ok(left) = int.parse(left)
    let assert Ok(right) = int.parse(right)
    #([left, ..left_acc], [right, ..right_acc])
  })
}

fn part1(left: List(Int), right: List(Int)) -> Int {
  let left = list.sort(left, by: int.compare)
  let right = list.sort(right, by: int.compare)
  list.zip(left, right)
  |> list.fold(0, fn(acc, tuple) {
    let #(left, right) = tuple
    acc + int.absolute_value(left - right)
  })
}

fn part2(left: List(Int), right: List(Int)) -> Int {
  let map = list.fold(right, dict.new(), fn(d, val) {
    let count = result.unwrap(dict.get(d, val), 0)
    dict.insert(d, val, count + 1)
  })
  list.fold(left, 0, fn(acc, val){
    let mult = result.unwrap(dict.get(map, val), 0)
    acc + val * mult
  })
}