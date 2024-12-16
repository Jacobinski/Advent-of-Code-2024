import gleam/int
import gleam/list
import gleam/string
import gleam/io
import gleam/option
import gleam/dict
import simplifile as file

pub type Coordinate = #(Int, Int)
pub type Direction {
    North
    East
    South
    West
}
pub type Tile {
    Wall
    Empty
    Start
    End
}
pub type Reindeer {
    Reindeer(position: Coordinate, direction: Direction)
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day16.txt")
    let maze = parse(contents)
    let reindeer = init_reindeer(maze)
    let scores = run(dict.new(), 0, reindeer, maze)

    io.println("Part 1: " <> int.to_string(part1(scores, maze)))

}

pub fn part1(scores: dict.Dict(Coordinate, Int), maze: dict.Dict(Coordinate, Tile)) -> Int {
    let assert Ok(end_score) = dict.get(scores, find(maze, End))
    end_score
}

pub fn run(scores: dict.Dict(Coordinate, Int), new_score: Int, reindeer: Reindeer, maze: dict.Dict(Coordinate, Tile)) -> dict.Dict(Coordinate, Int) {
    let position = reindeer.position
    case dict.get(maze, position) {
        Ok(Wall) -> scores
        Ok(End) -> {
            dict.upsert(scores, position, fn(x) {
                case x {
                    option.Some(existing) -> int.min(new_score, existing)
                    option.None -> new_score
                }
            })
        }
        Ok(Start) | Ok(Empty) -> {
            case dict.get(scores, position) {
                Ok(existing) -> case existing > new_score {
                    False -> scores
                    True -> {
                        dict.insert(scores, position, new_score)
                        |> run(new_score+1, step(reindeer, no_turn), maze)
                        |> run(new_score+1001, step(reindeer, clockwise), maze)
                        |> run(new_score+1001, step(reindeer, counter_clockwise), maze)
                    }
                }
                Error(_) -> {
                    dict.insert(scores, position, new_score)
                    |> run(new_score+1, step(reindeer, no_turn), maze)
                    |> run(new_score+1001, step(reindeer, clockwise), maze)
                    |> run(new_score+1001, step(reindeer, counter_clockwise), maze)
                }
            }
        }
        Error(_) -> panic
    }
}

pub fn step(reindeer: Reindeer, turn: fn(Direction) -> Direction) -> Reindeer {
    let new_direction = turn(reindeer.direction)
    let #(x, y) = reindeer.position
    let #(dx, dy) = direction_offset(new_direction)
    let new_position = #(x+dx, y+dy)

    Reindeer(position: new_position, direction: new_direction)
}

pub fn find(maze: dict.Dict(Coordinate, Tile), tile: Tile) -> Coordinate {
    let assert Ok(position) = maze
        |> dict.filter(fn(_, t) { t == tile })
        |> dict.keys
        |> list.first
    position
}

pub fn init_reindeer(maze: dict.Dict(Coordinate, Tile)) -> Reindeer {
    Reindeer(position: find(maze, Start), direction: East)
}

pub fn direction_offset(direction: Direction) -> Coordinate {
    case direction {
        North -> #(0, -1)
        East -> #(1, 0)
        South -> #(0, 1)
        West -> #(-1, 0)
    }
}

pub fn no_turn(direction: Direction) -> Direction {
    direction
}

pub fn clockwise(direction: Direction) -> Direction {
    case direction {
        North -> East
        East -> South
        South -> West
        West -> North
    }
}

pub fn counter_clockwise(direction: Direction) -> Direction {
    case direction {
        North -> West
        East -> North
        South -> East
        West -> South
    }
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
