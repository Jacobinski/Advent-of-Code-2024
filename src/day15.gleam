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

pub type Grid2 = dict.Dict(Coordinate, Tile2)
pub type Tile2 {
    Robot2
    Wall2
    Empty2
    BoxLeft
    BoxRight
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day15.txt")
    let #(directions, grid) = parse(contents)
    let #(directions2, grid2) = parse2(contents)

    io.println("Part 1: " <> int.to_string(part1(directions, grid)))
    io.println("Part 2: " <> int.to_string(part2(directions2, grid2)))
}

pub fn part2(directions: List(Direction), grid: Grid2) -> Int {
    simulate2(directions, grid)
    |> dict.filter(fn(_, value) { value == BoxLeft })
    |> dict.keys
    |> list.fold(0, fn(acc, pos) {
        let #(x, y) = pos
        acc + x + 100*y
    })
}

pub fn simulate2(directions: List(Direction), grid: Grid2) -> Grid2 {
    directions
    |> list.fold(grid, fn(grid, direction) {
        let position = robot_position2(grid)
        case move2(position, direction, grid) {
            Error(_) -> grid
            Ok(new_grid) -> new_grid
        }
    })
}

pub fn move2(coordinate: Coordinate, direction: Direction, grid: Grid2) -> Result(Grid2, MoveError) {
    // NOTES: This function is recursive. In the function body, it will check if the next object
    //  is a wall (return Error), empty (return Ok()), or a moveable object (recurs). The function
    //  is only responsible for moving `coordinate` in `direction` and replacing it with an empty
    //  spot. The recursive calls will do the same, so if all recursive calls are Ok() then there
    //  will exist an empty spot in `direction` for the current object. If the *next* object is a
    //  box, then a double recursion will occur - one for each half - and if they both succeed,
    //  then the double-width box will have moved, created two empty spaces, and the current object
    //  (either a one-width robot, or half of a two-width box) can move to fill one of the spots.
    let #(x, y) = coordinate
    let #(dx, dy) = to_coordinate(direction)
    let assert Ok(curr) = dict.get(grid, #(x, y))
    let assert Ok(next) = dict.get(grid, #(x+dx, y+dy))

    case next {
        Robot2 -> panic // Invariant: The robot is the pusher, not the pushed.
        Wall2 -> Error(WallError)
        Empty2 -> Ok(
            grid
            |> dict.insert(#(x+dx, y+dy), curr)
            |> dict.insert(#(x, y), Empty2)
        )
        // Recurse: Make the box move another box. This double recursion links
        //   the two boxes together. We must use DFS during iteration so that
        //   we can avoid having the merge mulitple grids together at the end
        //   (a hard problem).
        BoxLeft | BoxRight -> case direction {
            Left | Right -> {
                case move2(#(x+dx, y+dy), direction, grid) {
                    Error(err) -> Error(err)
                    Ok(new_grid) -> Ok(
                        new_grid
                        |> dict.insert(#(x+dx, y+dy), curr)
                        |> dict.insert(#(x, y), Empty2)
                    )
                }
            }
            Up | Down -> {
                let twin = case next {
                    BoxLeft -> BoxRight
                    BoxRight -> BoxLeft
                    _ -> panic
                }
                let #(dx_twin, dy_twin) = case twin {
                    BoxLeft -> #(-1, 0)
                    BoxRight -> #(1, 0)
                    _ -> panic
                }
                case move2(#(x+dx, y+dy), direction, grid) {
                    Error(err) -> Error(err)
                    Ok(updated_grid) -> case move2(#(x+dx_twin+dx, y+dy_twin+dy), direction, updated_grid) {
                        Error(err) -> Error(err)
                        Ok(final_grid) -> Ok(
                            final_grid
                            |> dict.insert(#(x+dx, y+dy), curr)
                            |> dict.insert(#(x, y), Empty2)
                        )
                    }
                }

            }
        }
    }
}

pub fn robot_position2(grid: Grid2) -> Coordinate {
    let assert [position] = grid
        |> dict.filter(fn(_, value) { value == Robot2 })
        |> dict.keys
    position
}

pub fn parse2(contents: String) -> #(List(Direction), Grid2) {
    let #(top, bottom) = contents
        |> string.replace(each: ".", with: "..")
        |> string.replace(each: "#", with: "##")
        |> string.replace(each: "O", with: "[]")
        |> string.replace(each: "@", with: "@.")
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
                    "#" -> Wall2
                    "@" -> Robot2
                    "." -> Empty2
                    "[" -> BoxLeft
                    "]" -> BoxRight
                    _ -> panic
                }
                #(#(idx_col, idx_row), tile)
            })
        })
        |> list.flatten
        |> dict.from_list

    #(directions, grid)
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