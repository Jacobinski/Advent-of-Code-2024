
import gleam/set
import gleam/int
import gleam/list
import gleam/string
import gleam/io
import gleam/dict
import gleam/pair
import simplifile as file
import gleam_community/ansi

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
    visualize(track)

    io.println("Part 1: " <> int.to_string(part1(track, 100)))
}

pub fn part1(track: dict.Dict(Coordinate, Tile), minimum_to_save_ps: Int) -> Int {
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

    let cheat_ps = walls
        |> set.to_list
        |> list.map(fn(position) {
            case dict.get(seen_from_start, position), dict.get(seen_from_end, position) {
                Ok(start_to_wall_ps), Ok(end_to_wall_ps) -> {start_to_wall_ps + end_to_wall_ps}
                _, _ -> base_ps
            }
        })

    cheat_ps
    |> list.map(fn(x) { base_ps - x })
    |> list.count(fn(x) { x >= minimum_to_save_ps })
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

pub fn visualize(maze: dict.Dict(Coordinate, Tile)) {
    maze
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
            let #(_position, tile) = x
            case tile {
                Empty -> ansi.white(".")
                Wall -> ansi.blue("#")
                Start -> ansi.green("S")
                End -> ansi.red("E")
            }
        })
        |> string.join("")
    })
    |> string.join("\n")
    |> io.println
}
