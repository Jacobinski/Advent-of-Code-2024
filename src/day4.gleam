import gleam/result
import gleam/int
import gleam/bool
import gleam/dict
import gleam/string
import gleam/io
import gleam/list
import simplifile as file

pub fn main() {
  let assert Ok(contents) = file.read("inputs/day4.txt")
  io.println("Part 1: " <> int.to_string(part1(contents)))
  io.println("Part 2: " <> int.to_string(part2(contents)))
}

fn parse_crossword(contents: String) -> dict.Dict(#(Int, Int), String) {
  contents
  |> string.split("\n")
  |> list.index_map(fn(row_contents, idx_row) {
    row_contents
    |> string.to_graphemes()
    |> list.index_map(fn(character, idx_col) { #(#(idx_row, idx_col), character) })
  })
  |> list.flatten()
  |> dict.from_list()
}

fn part1(contents: String) -> Int{
  let crossword_dict = parse_crossword(contents)
  dict.keys(crossword_dict)
  |> list.map(fn(tuple) {
    let #(x, y) = tuple
    // HACK: This *should* be a loop, but I think that this approach is more aesthetic.
    [
        [
            dict.get(crossword_dict, #(x, y)) == Ok("X"),
            dict.get(crossword_dict, #(x, y+1)) == Ok("M"),
            dict.get(crossword_dict, #(x, y+2)) == Ok("A"),
            dict.get(crossword_dict, #(x, y+3)) == Ok("S"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("X"),
            dict.get(crossword_dict, #(x, y-1)) == Ok("M"),
            dict.get(crossword_dict, #(x, y-2)) == Ok("A"),
            dict.get(crossword_dict, #(x, y-3)) == Ok("S"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("X"),
            dict.get(crossword_dict, #(x+1, y)) == Ok("M"),
            dict.get(crossword_dict, #(x+2, y)) == Ok("A"),
            dict.get(crossword_dict, #(x+3, y)) == Ok("S"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("X"),
            dict.get(crossword_dict, #(x-1, y)) == Ok("M"),
            dict.get(crossword_dict, #(x-2, y)) == Ok("A"),
            dict.get(crossword_dict, #(x-3, y)) == Ok("S"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("X"),
            dict.get(crossword_dict, #(x+1, y+1)) == Ok("M"),
            dict.get(crossword_dict, #(x+2, y+2)) == Ok("A"),
            dict.get(crossword_dict, #(x+3, y+3)) == Ok("S"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("X"),
            dict.get(crossword_dict, #(x+1, y-1)) == Ok("M"),
            dict.get(crossword_dict, #(x+2, y-2)) == Ok("A"),
            dict.get(crossword_dict, #(x+3, y-3)) == Ok("S"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("X"),
            dict.get(crossword_dict, #(x-1, y+1)) == Ok("M"),
            dict.get(crossword_dict, #(x-2, y+2)) == Ok("A"),
            dict.get(crossword_dict, #(x-3, y+3)) == Ok("S"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("X"),
            dict.get(crossword_dict, #(x-1, y-1)) == Ok("M"),
            dict.get(crossword_dict, #(x-2, y-2)) == Ok("A"),
            dict.get(crossword_dict, #(x-3, y-3)) == Ok("S"),
        ],
    ]
    |> list.map( list.reduce(_, bool.and) )
    |> list.count( fn(x) { x == Ok(True) })
  })
  |> list.reduce(int.add)
  |> result.unwrap(0)
}

fn part2(contents: String) -> Int{
  let crossword_dict = parse_crossword(contents)
  dict.keys(crossword_dict)
  |> list.map(fn(tuple) {
    let #(x, y) = tuple
    // HACK: This *should* be a loop, but I think that this approach is more aesthetic.
    [
        [
            dict.get(crossword_dict, #(x, y)) == Ok("A"),
            dict.get(crossword_dict, #(x+1, y+1)) == Ok("M"),
            dict.get(crossword_dict, #(x-1, y-1)) == Ok("S"),
            dict.get(crossword_dict, #(x-1, y+1)) == Ok("S"),
            dict.get(crossword_dict, #(x+1, y-1)) == Ok("M"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("A"),
            dict.get(crossword_dict, #(x+1, y+1)) == Ok("M"),
            dict.get(crossword_dict, #(x-1, y-1)) == Ok("S"),
            dict.get(crossword_dict, #(x-1, y+1)) == Ok("M"),
            dict.get(crossword_dict, #(x+1, y-1)) == Ok("S"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("A"),
            dict.get(crossword_dict, #(x+1, y+1)) == Ok("S"),
            dict.get(crossword_dict, #(x-1, y-1)) == Ok("M"),
            dict.get(crossword_dict, #(x-1, y+1)) == Ok("M"),
            dict.get(crossword_dict, #(x+1, y-1)) == Ok("S"),
        ],
        [
            dict.get(crossword_dict, #(x, y)) == Ok("A"),
            dict.get(crossword_dict, #(x+1, y+1)) == Ok("S"),
            dict.get(crossword_dict, #(x-1, y-1)) == Ok("M"),
            dict.get(crossword_dict, #(x-1, y+1)) == Ok("S"),
            dict.get(crossword_dict, #(x+1, y-1)) == Ok("M"),
        ],
    ]
    |> list.map( list.reduce(_, bool.and) )
    |> list.count( fn(x) { x == Ok(True) })
  })
  |> list.reduce(int.add)
  |> result.unwrap(0)
}