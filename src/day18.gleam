import gleam/dict
import gleam/int
import gleam/string
import gleam/io
import gleam/pair
import gleam/list
import simplifile as file
import gleam_community/ansi

pub type Tile {
    Wall
    Empty
}
pub type Coordinate = #(Int, Int)
pub type Grid = dict.Dict(Coordinate, Tile)

// Gleam not have int.Max
const infinity = 9999999999999999999999999999999

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day18.txt")
    let bound = 70
    let fallen_bytes = 1024

    let bytes = parse(contents)

    io.println("Part 1: " <> int.to_string(part1(bytes, bound, fallen_bytes)))
}

pub fn part1(bytes: List(Coordinate), bound: Int, fallen_bytes: Int) -> Int {
    let #(bytes, _) = list.split(bytes, fallen_bytes)
    let grid = grid_empty(bound)
    let grid_bytes = {
        bytes
        |> list.map(fn(pos) { #(pos, Wall) })
        |> dict.from_list
    }
    let grid = dict.merge(grid, grid_bytes)
    print(grid)

    let start = #(0, 0)
    let end = #(bound, bound)
    let unseen = grid
        |> dict.filter(fn(_, tile) { tile == Empty })
        |> dict.map_values(fn(_,_){ infinity })
    let seen = dict.new()
    dijkstra(start, end, seen, unseen)
}

pub fn dijkstra(start: Coordinate, end: Coordinate, seen: dict.Dict(Coordinate, Int), unseen: dict.Dict(Coordinate, Int)) -> Int {
    let next = case dict.size(seen) == 0 {
        True -> #(start, 0)
        False -> dict.fold(unseen, #(#(-1, -1), infinity), fn(accumulator, coordinate, distance) {
            let #(_, best_distance) = accumulator
            case distance < best_distance {
                True -> #(coordinate, distance)
                False -> accumulator
            }
        })
    }
    let #(#(x, y), distance) = next
    let seen = dict.insert(seen, #(x, y), distance)
    let unseen = dict.delete(unseen, #(x, y))
    let updates = {
        [
            #(x+1, y),
            #(x-1, y),
            #(x, y+1),
            #(x, y-1),
        ]
        |> list.filter(fn(pos) { dict.has_key(unseen, pos) })
        |> list.map(fn(pos) {#(pos, distance+1) })
        |> dict.from_list
    }
    let unseen = dict.merge(unseen, updates)
    case #(x, y) == end {
        True -> distance
        False -> dijkstra(start, end, seen, unseen)
    }
}

pub fn parse(contents: String) -> List(Coordinate) {
    contents
    |> string.split("\n")
    |> list.map(fn(row) {
        let assert [x, y] = row
            |> string.split(",")
            |> list.map(fn(x) {
                let assert Ok(x) = int.parse(x)
                x
            })
        #(x, y)
    })
}

pub fn grid_empty(bound: Int) -> Grid {
    list.range(0, bound)
    |> list.map(fn(x) {
        list.range(0, bound)
        |> list.map(fn(y) {
            #(#(x, y), Empty)
        })
    })
    |> list.flatten
    |> dict.from_list
}

pub fn print(grid: dict.Dict(Coordinate, Tile)) {
    grid
    |> dict.to_list
    |> list.group(fn(tup) {
        let #(_, y) = pair.first(tup)
        y
    })
    |> dict.to_list
    |> list.sort(fn(a, b) {
        int.compare(pair.first(a), pair.first(b))
    })
    |> list.map(fn(row) {
        pair.second(row)
        |> list.sort(fn(a, b) {
            let #(xa, _) = pair.first(a)
            let #(xb, _) = pair.first(b)
            int.compare(xa, xb)
        })
        |> list.map(fn(x) {
            let #(_, tile) = x
            case tile {
                Empty -> ansi.white(".")
                Wall -> ansi.blue("#")
            }
        })
        |> string.join("")
    })
    |> string.join("\n")
    |> io.println
}