
import gleam/set
import gleam/int
import gleam/list
import gleam/string
import gleam/io
import gleam/dict
import gleam/pair
import simplifile as file

pub type Coordinate = #(Int, Int)
pub type Tile {
    Wall
    Empty
    Start
    End
}

const infinity = 9999999999999999

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day20.txt")
    let track = parse(contents)
    io.println("Part 1: " <> int.to_string(count_cheats(track, 2, 100)))
    io.println("Part 2: " <> int.to_string(count_cheats(track, 20, 100)))
}

pub fn count_cheats(track: dict.Dict(Coordinate, Tile), cheat_max_distance: Int, minimum_to_save_ps: Int) -> Int {
    let start = find(Start, track)
    let end = find(End, track)
    let seen = dict.new()
    let unseen = track
        |> dict.filter(fn(_, tile) { tile != Wall })
        |> dict.map_values(fn(_, _) { infinity })

    let walls = track
        |> dict.filter(fn(_, tile) { tile == Wall })
        |> dict.keys
        |> set.from_list

    let assert Ok(seen_from_start) = dijkstra(start, end, seen, unseen, walls)
    let assert Ok(seen_from_end) = dijkstra(end, start, seen, unseen, walls)

    let assert Ok(base_ps) = dict.get(seen_from_start, end)

    let valid_cheat_start = track
        |> dict.filter(fn(_, tile) { tile != Wall })
        |> dict.keys
    let valid_cheat_end = track
        |> dict.filter(fn(_, tile) { tile != Wall })
        |> dict.keys

    let cheat_paths = valid_cheat_start
        |> list.map(fn(start) {
            valid_cheat_end
            |> list.filter(fn(end) { manhattan_distance(start, end) <= cheat_max_distance })
            |> list.map(fn(end) { #(start, end) })
        })
        |> list.flatten

    let cheat_ps = cheat_paths
        |> list.map(fn(path) {
            let #(start, end) = path
            case dict.get(seen_from_start, start), dict.get(seen_from_end, end) {
                Ok(start_to_wall_ps), Ok(end_to_wall_ps) -> {
                    start_to_wall_ps + end_to_wall_ps + manhattan_distance(start, end)
                }
                _, _ -> base_ps
            }
        })

    cheat_ps
    |> list.map(fn(x) { base_ps - x })
    |> list.count(fn(x) { x >= minimum_to_save_ps })
}

pub fn manhattan_distance(a: Coordinate, b: Coordinate) -> Int {
    int.absolute_value(a.0 - b.0) + int.absolute_value(a.1 - b.1)
}

pub fn dijkstra(start: Coordinate, end: Coordinate, seen: dict.Dict(Coordinate, Int), unseen: dict.Dict(Coordinate, Int), walls: set.Set(Coordinate)) -> Result(dict.Dict(Coordinate, Int), Nil) {
    let sentinel = #(#(-1, -1), infinity)
    let next = case dict.size(seen) == 0 {
        True -> #(start, 0)
        False -> dict.fold(unseen, sentinel, fn(accumulator, coordinate, distance) {
            let #(_, best_distance) = accumulator
            case distance < best_distance {
                True -> #(coordinate, distance)
                False -> accumulator
            }
        })
    }
    case sentinel == next {
        True -> Error(Nil)
        False -> {
            let #(#(x, y), distance) = next
            let seen = dict.insert(seen, #(x, y), distance)
            let seen_updates = {
                [
                    #(x+1, y),
                    #(x-1, y),
                    #(x, y+1),
                    #(x, y-1),
                ]
                |> list.filter(set.contains(walls, _))
                |> list.map(fn(pos) {
                    case dict.get(seen, pos) {
                        Ok(prev_distance) -> #(pos, int.min(prev_distance, distance + 1))
                        Error(_) -> #(pos, distance + 1)
                    }
                })
                |> dict.from_list
            }
            let seen = dict.merge(seen, seen_updates)
            let unseen = dict.delete(unseen, #(x, y))
            let unseen_updates = {
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
            let unseen = dict.merge(unseen, unseen_updates)
            case #(x, y) == end {
                True -> Ok(seen)
                False -> dijkstra(start, end, seen, unseen, walls)
            }
        }
    }
}

pub fn find(target: Tile, track: dict.Dict(Coordinate, Tile)) -> Coordinate {
    track
    |> dict.filter(fn(_, tile) { tile == target })
    |> dict.to_list
    |> list.fold(#(-1, -1), fn(_acc, tile) {pair.first(tile)})
}

pub fn parse(contents: String) -> dict.Dict(Coordinate, Tile) {
    contents
    |> string.split("\n")
    |> list.index_map(fn(row, idx_row) {
        row
        |> string.to_graphemes
        |> list.index_map(fn(char, idx_col) {
            let tile = case char {
                "#" -> Wall
                "." -> Empty
                "S" -> Start
                "E" -> End
                _ -> panic
            }
            #(#(idx_col, idx_row), tile)
        })
    })
    |> list.flatten
    |> dict.from_list
}
