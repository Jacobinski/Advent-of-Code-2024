import gleam/set
import gleam/result
import gleam/dict
import gleam/int
import gleam/list
import gleam/io
import gleam/string
import simplifile as file

pub type Coordinates = #(Int, Int)
pub type Map = dict.Dict(Coordinates, Int)

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day10.txt")
    let map = parse_map(contents)
    let trailheads = trailheads(map)
    io.println("Part 1: " <> int.to_string(part1(trailheads, map)))
    io.println("Part 2: " <> int.to_string(part2(trailheads, map)))
}

pub fn part1(trailheads: List(Coordinates), map: Map) -> Int {
    let assert Ok(score) = trailheads
        |> list.map(trailscore(_, map))
        |> list.reduce(int.add)
    score
}

pub fn part2(trailheads: List(Coordinates), map: Map) -> Int {
    let assert Ok(score) = trailheads
        |> list.map(rating(_, map))
        |> list.reduce(int.add)
    score
}

pub fn rating(coordinates: Coordinates, map: Map) -> Int {
    list.length(trailscore_helper(0, coordinates, map))
}

pub fn trailscore(coordinates: Coordinates, map: Map) -> Int {
    trailscore_helper(0, coordinates, map)
    |> set.from_list
    |> set.size
}

pub fn trailscore_helper(want_height: Int, coordinates: Coordinates, map: Map) -> List(Coordinates) {
    case dict.get(map, coordinates) {
        Error(_) -> []
        Ok(height) -> case height == want_height {
            False -> []
            True -> case height {
                9 -> [coordinates]
                _ -> {
                    let #(x, y) = coordinates
                    list.flatten([
                        trailscore_helper(height + 1, #(x+1, y), map),
                        trailscore_helper(height + 1, #(x-1, y), map),
                        trailscore_helper(height + 1, #(x, y+1), map),
                        trailscore_helper(height + 1, #(x, y-1), map),
                    ])
                }
            }
        }
    }
}

pub fn trailheads(map: Map) -> List(Coordinates) {
    map
    |> dict.filter(fn(_coordinates, height) { height == 0 })
    |> dict.keys
}

pub fn parse_map(contents: String) -> Map {
    contents
    |> string.split("\n")
    |> list.index_map(fn(row, row_idx) {
        row
        |> string.to_graphemes
        |> list.index_map(fn(char, col_idx){
            let assert Ok(x) = int.parse(char)
            #(#(row_idx, col_idx), x)
        })
    })
    |> list.flatten
    |> dict.from_list
}