import gleam/set
import gleam/bool
import gleam/dict
import gleam/pair
import gleam/list
import gleam/io
import gleam/int
import gleam/string
import simplifile as file

pub type Node {
    Antenna(id: String)
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day8.txt")
    let board = board(contents)
    io.println("Part 1: " <> int.to_string(part1(board)))
    io.println("Part 2: " <> int.to_string(part2(board)))
}

pub fn part1(board: List(#(#(Int, Int), String))) -> Int {
    number_antinodes(board, antinodes_pair)
}

pub fn part2(board: List(#(#(Int, Int), String))) -> Int {
    number_antinodes(board, antinodes_line)
}

pub fn number_antinodes(board: List(#(#(Int, Int), String)), antinode_fn: fn(#(#(Int, Int), #(Int, Int))) -> List(#(Int, Int))) -> Int {
    let #(max_x, max_y) = maxima(board)
    let #(min_x, min_y) = minima(board)
    let antennas = filter_antennas(board)

    antennas
    |> list.group(fn(item){
        let #(#(_x, _y), antenna) = item
        antenna.id
    })
    |> dict.values
    |> list.map(fn(group) {
        group
        |> list.map(pair.first)
        |> list.combination_pairs
        |> list.map(antinode_fn)
        |> list.flatten
        |> list.filter(fn(point) {
            let #(x, y) = point
            let assert Ok(in_bounds) = [
                x <= max_x,
                x >= min_x,
                y <= max_y,
                y >= min_y,
            ] |> list.reduce(bool.and)
            in_bounds
        })
    })
    |> list.flatten
    |> set.from_list
    |> set.size
}

pub fn antinodes_pair(pair: #(#(Int, Int), #(Int, Int))) -> List(#(Int, Int)) {
    let #(#(x1, y1), #(x2, y2)) = pair
    let dx = x1 - x2
    let dy = y1 - y2
    [#(x1 + dx, y1 + dy), #(x1 - 2*dx, y1 - 2*dy)]
}

pub fn antinodes_line(pair: #(#(Int, Int), #(Int, Int))) -> List(#(Int, Int)) {
    let #(#(x1, y1), #(x2, y2)) = pair
    let dx = x1 - x2
    let dy = y1 - y2
    // The correct solution would be to generate points until we are out of bounds
    // in both directions. The hacky solution, which is done here, is to recognize
    // that the input board is 50x50, so the longest antinode line can have
    // sqrt(50^2 + 50^2) ~= 71 items, so if we generate a line much longer than this
    // and prune it down in a bounds check (happens outside of this function) then
    // we should be safe.
    list.range(-100, 100)
    |> list.map(fn(idx) { #(x1 + idx * dx, y1 + idx * dy) })

}

pub fn maxima(board: List(#(#(Int, Int), String))) -> #(Int, Int) {
    maxima_minima_helper(board, int.max)
}

pub fn minima(board: List(#(#(Int, Int), String))) -> #(Int, Int) {
    maxima_minima_helper(board, int.min)
}

pub fn maxima_minima_helper(board: List(#(#(Int, Int), String)), func: fn(Int, Int) -> Int) -> #(Int, Int) {
    let assert Ok(maxima) = board
        |> list.map(pair.first)
        |> list.reduce(fn(a, b) {
            let #(x1, y1) = a
            let #(x2, y2) = b
            #(func(x1, x2), func(y1, y2))
        })
    maxima
}

pub fn filter_antennas(board: List(#(#(Int, Int), String))) -> List(#(#(Int, Int), Node)){
    board
    |> list.filter_map(fn(item){
        let #(#(x, y), char) = item
        case char {
            "." -> Error(Nil)
            c -> Ok(#(#(x, y), Antenna(id: c)))
        }
    })
}

pub fn board(contents: String) -> List(#(#(Int, Int), String)) {
    contents
    |> string.split("\n")
    |> list.index_map(fn(row, row_idx) {
        row
        |> string.to_graphemes
        |> list.index_map(fn(char, col_idx) {
            #(#(col_idx, row_idx), char)
        })
    })
    |> list.flatten
}