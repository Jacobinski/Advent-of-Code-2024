import gleam/dict
import gleam/list
import gleam/io
import gleam/string
import gleam/int
import simplifile as file

pub type Coordinate = #(Int, Int)
pub type Grid = dict.Dict(Coordinate, Tile)
pub type Direction {
    Up
    Down
    Left
    Right
}
pub type Tile {
    Robot
    Wall
    Box
    Empty
}
pub type MoveError {
    WallError
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day15.txt")
    let #(directions, grid) = parse(contents)

    io.println("Part 1: " <> int.to_string(part1(directions, grid)))
}

pub fn part1(directions: List(Direction), grid: Grid) -> Int {
    simulate(directions, grid)
    |> dict.filter(fn(_, value) { value == Box })
    |> dict.keys
    |> list.fold(0, fn(acc, pos) {
        let #(x, y) = pos
        acc + x + 100*y
    })
}

pub fn simulate(directions: List(Direction), grid: Grid) -> Grid {
    directions
    |> list.fold(grid, fn(grid, direction) {
        let position = robot_position(grid)
        case move(position, direction, grid) {
            Error(_) -> grid
            Ok(new_grid) -> new_grid
        }
    })
}

pub fn move(coordinate: Coordinate, direction: Direction, grid: Grid) -> Result(Grid, MoveError) {
    let #(x, y) = coordinate
    let #(dx, dy) = to_coordinate(direction)
    let assert Ok(curr) = dict.get(grid, #(x, y))
    let assert Ok(next) = dict.get(grid, #(x+dx, y+dy))
    case next {
        Robot -> panic // Invariant: The robot is the pusher, not the pushed.
        Wall -> Error(WallError)
        Empty -> Ok(
            grid
            |> dict.insert(#(x+dx, y+dy), curr)
            |> dict.insert(#(x, y), Empty)
        )
        // Recurse: Make the box move another box.
        Box -> case move(#(x+dx, y+dy), direction, grid) {
            Error(err) -> Error(err)
            Ok(new_grid) -> Ok(
                new_grid
                |> dict.insert(#(x+dx, y+dy), curr)
                |> dict.insert(#(x, y), Empty)
            )
        }
    }
}

pub fn to_coordinate(direction: Direction) -> Coordinate {
    case direction {
        Up -> #(0, -1)
        Down -> #(0, 1)
        Left -> #(-1, 0)
        Right -> #(1, 0)
    }
}

pub fn robot_position(grid: Grid) -> Coordinate {
    let assert [position] = grid
        |> dict.filter(fn(_, value) { value == Robot })
        |> dict.keys
    position
}

pub fn parse(contents: String) -> #(List(Direction), Grid) {
    let #(top, bottom) = contents
        |> string.split("\n")
        |> list.split_while(fn(x) { x != ""})

    let directions = bottom
        |> string.join("")
        |> string.to_graphemes
        |> list.map(fn(x) {
            case x {
                "^" -> Up
                "v" -> Down
                "<" -> Left
                ">" -> Right
                _ -> panic
            }
        })

    let grid = top
        |> list.index_map(fn(row, idx_row) {
            row
            |> string.to_graphemes
            |> list.index_map(fn(char, idx_col) {
                let tile = case char {
                    "#" -> Wall
                    "O" -> Box
                    "@" -> Robot
                    "." -> Empty
                    _ -> panic
                }
                #(#(idx_col, idx_row), tile)
            })
        })
        |> list.flatten
        |> dict.from_list

    #(directions, grid)
}