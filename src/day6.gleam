import gleam/bool
import gleam/pair
import gleam/dict
import gleam/set
import gleam/string
import gleam/option
import gleam/io
import gleam/list
import gleam/int
import simplifile as file

pub type Direction {
    Up
    Down
    Left
    Right
}

pub type Tile {
    Guard(dir: Direction, prev: set.Set(Direction))
    Visited(dirs: set.Set(Direction))
    Obstacle
    Empty
}

type Board = dict.Dict(#(Int, Int), Tile)

fn parse(contents: String) -> Board {
    contents
    |> string.split("\n")
    |> list.index_map(fn(row, row_idx) {
        row
        |> string.to_graphemes
        |> list.index_map(fn(val, col_idx) {
            #(#(col_idx, row_idx), val)
        })
    })
    |> list.flatten
    |> dict.from_list
    |> dict.map_values(fn(_, val) {
        case val {
            "^" ->  Guard(Up, set.new())
            "#" -> Obstacle
            _ -> Empty
        }
    })
}

fn find_guard(board: Board) -> option.Option(#(#(Int, Int), Tile)) {
    board
    |> dict.to_list
    |> list.find(fn(x) {
        case pair.second(x) {
           Guard(_, _) -> True
           _ -> False
        }
    })
    |> option.from_result
}

fn rotate(tile: Tile) -> Tile {
    case tile {
        Guard(Up, s) -> Guard(Right, set.insert(s, Up))
        Guard(Right, s) -> Guard(Down, set.insert(s, Right))
        Guard(Down, s) -> Guard(Left, set.insert(s, Down))
        Guard(Left, s) -> Guard(Up, set.insert(s, Left))
        other -> other
    }
}

pub type SimulationError {
    InfiniteLoop
}

fn simulate(board: Board) -> Result(Board, SimulationError) {
    case find_guard(board) {
        option.None -> Ok(board)
        option.Some(#(#(x, y), guard)) -> {
            let assert Ok(#(direction, prev_visited)) = case guard {
                Guard(dir, prev_visited) -> Ok(#(dir, prev_visited))
                _ -> Error("unsupported tile")
            }
            let #(dx, dy) = case direction {
                Up -> #(x, y-1)
                Down -> #(x, y+1)
                Left -> #(x-1, y)
                Right -> #(x+1, y)
            }
            case dict.get(board, #(dx, dy)) {
                // Guard will leave the board
                Error(_) -> Ok(dict.insert(board, #(x, y), Visited(set.insert(prev_visited, direction))))
                // Guard remains on board
                Ok(tile) -> {
                    let update = case tile {
                        // Guard turns at obstacle
                        Obstacle -> Ok(dict.insert(board, #(x, y), rotate(guard)))
                        // Guard moves forward onto previously seen tile
                        Visited(prev) -> {
                            case set.contains(prev, direction) {
                                True -> Error(InfiniteLoop)
                                False -> {
                                    Ok(
                                        board
                                        |> dict.insert(#(x, y), Visited(set.insert(prev_visited, direction)))
                                        |> dict.insert(#(dx, dy), Guard(direction, prev))
                                    )
                                }
                            }
                        }
                        // Guard moves forward onto empty space
                        _ -> {
                            Ok(
                                board
                                |> dict.insert(#(x, y), Visited(set.insert(prev_visited, direction)))
                                |> dict.insert(#(dx, dy), Guard(direction, set.new()))
                            )
                        }
                    }
                    case update {
                        Ok(new_board) -> simulate(new_board)
                        Error(err) -> Error(err)
                    }
                }
            }
        }
    }
}

pub fn part1(board: Board) -> Int {
    simulate(board)
    |> fn(x) {
        let assert Ok(x) = x
        x
    }
    |> dict.values
    |> list.count(fn(x) {
        case x {
            Visited(_) -> True
            _ -> False
        }
    })
}

pub fn part2(board: Board) -> Int {
    // This code is very slow, so we must optimize it a bit...
    // Optimization #1: Only place objects on the known path of the guard
    let visited = simulate(board)
        |> fn(x) {
            let assert Ok(x) = x
            x
        }
        |> dict.to_list
        |> list.filter_map(fn(tup) {
            let #(#(x, y), tile) = tup
            case tile {
                Visited(_) -> Ok(#(x, y))
                _ -> Error(Nil)
            }
        })
        |> set.from_list

    board
    |> dict.to_list
    |> list.map(fn(tup) {
        // This function checks to see if a new item on the board results
        // in an infinite loop.
        let #(#(x, y), tile) = tup
        case set.contains(visited, #(x, y)) {
            False -> False
            True -> {
                case tile {
                    Obstacle -> False
                    Guard(_, _) -> False
                    _ -> {
                        let board = dict.insert(board, #(x, y), Obstacle)
                        case simulate(board) {
                            Ok(_) -> False
                            Error(InfiniteLoop) -> True
                        }
                    }
                }
            }
        }
    })
    |> list.count(bool.and(_, True))
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day6.txt")
    let board = parse(contents)
    io.println("Part 1: " <> int.to_string(part1(board)))
    io.println("Part 2: " <> int.to_string(part2(board)))
}
