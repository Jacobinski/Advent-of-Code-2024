import gleam/order
import gleam/int
import gleam/list
import gleam/string
import gleam/io
import gleam/set
import gleam/option
import gleam/dict
import gleam/pair
import simplifile as file
import gleam_community/ansi

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

const very_large_number = 10000000000000000000000

pub type State {
    State(position: Coordinate, direction: Direction)
    Initial(position: Coordinate, direction: Direction)
}

pub fn print(maze: dict.Dict(Coordinate, Tile), path: set.Set(Coordinate)) {
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
            let #(position, tile) = x
            case set.contains(path, position), tile {
                True, _ -> ansi.green("O")
                _, Empty -> ansi.white(".")
                _, Wall -> ansi.blue("#")
                _, Start -> "S"
                _, End -> "E"
            }
        })
        |> string.join("")
    })
    |> string.join("\n")
    |> io.println
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day16.txt")

    let maze = parse(contents)
    let initial = Initial(position: find(maze, Start), direction: East)
    let scores = solve(dict.new(), 0, initial, initial, maze)

    io.println("Part 1: " <> int.to_string(part1(scores, maze)))
    io.println("Part 2: " <> int.to_string(part2(scores, maze)))
}

pub fn part2(scores: dict.Dict(State, #(Int, set.Set(State))), maze: dict.Dict(Coordinate, Tile)) -> Int {
    let end = find(maze, End)

    let assert Ok(#(end_state, _ )) = [ North, East, South, West ]
        |> list.map(fn (x) { State(end, x) })
        |> list.filter_map(fn(state) {
            case dict.get(scores, state) {
                Ok(score) -> Ok(#(state, score))
                Error(err) -> Error(err)
            }
        })
        |> list.reduce(fn(acc, curr) {
            let #(_, #(a_score, _)) = acc
            let #(_, #(c_score, _)) = curr
            case a_score < c_score {
                True -> acc
                False -> curr
            }
        })

    let ancestors = ancestry(end_state, scores)
        |> set.to_list
        |> list.map(fn(s) {s.position})
        |> set.from_list

    print(maze, ancestors)

    ancestors |> set.size
}

pub fn ancestry(target: State, scores: dict.Dict(State, #(Int, set.Set(State)))) -> set.Set(State) {
    case target {
        Initial(_, _) -> set.from_list([target])
        State(_, _) -> {
            let assert Ok(#(_, predecessors)) = dict.get(scores, target)

            predecessors
            |> set.to_list
            |> list.map(fn(p) { ancestry(p, scores) })
            |> list.fold(set.from_list([target]), set.union)
        }
    }
}

pub fn part1(scores: dict.Dict(State, #(Int, set.Set(State))), maze: dict.Dict(Coordinate, Tile)) -> Int {
    let end = find(maze, End)

    [ North, East, South, West ]
    |> list.map(fn (x) { State(end, x) })
    |> list.filter_map(fn(x) { dict.get(scores, x )  })
    |> list.map(pair.first)
    |> list.fold(very_large_number, int.min)
}

pub fn solve(scores: dict.Dict(State, #(Int, set.Set(State))), new_score: Int, new_state: State, prev_state: State, maze: dict.Dict(Coordinate, Tile)) -> dict.Dict(State, #(Int, set.Set(State))) {
    let position = new_state.position
    case dict.get(maze, position) {
        Ok(Wall) -> scores
        Ok(End) -> dict.upsert(scores, new_state, fn(val) {
            case val {
                option.Some(#(min, states)) -> case int.compare(new_score, min) {
                    order.Lt -> #(new_score, set.from_list([prev_state]))
                    order.Eq -> #(min, set.insert(states, prev_state))
                    order.Gt -> #(min, states)
                }
                option.None() -> #(new_score, set.from_list([prev_state]))
            }
        })
        Ok(Start) | Ok(Empty) -> {
            case dict.get(scores, new_state) {
                Ok(#(min, states)) -> case int.compare(new_score, min) {
                    order.Gt -> scores
                    order.Lt -> {
                        scores
                        |> dict.insert(new_state, #(new_score, set.from_list([prev_state])))
                        |> solve(new_score+1, forward(new_state), new_state, maze)
                        |> solve(new_score+1000, turn(new_state, clockwise), new_state, maze)
                        |> solve(new_score+1000, turn(new_state, counter_clockwise), new_state, maze)
                    }
                    order.Eq -> {
                        scores
                        |> dict.insert(new_state, #(new_score, set.insert(states, prev_state)))
                        |> solve(new_score+1, forward(new_state), new_state, maze)
                        |> solve(new_score+1000, turn(new_state, clockwise), new_state, maze)
                        |> solve(new_score+1000, turn(new_state, counter_clockwise), new_state, maze)
                    }
                }
                Error(_) -> {
                    scores
                    |> dict.insert(new_state, #(new_score, set.from_list([prev_state])))
                    |> solve(new_score+1, forward(new_state), new_state, maze)
                    |> solve(new_score+1000, turn(new_state, clockwise), new_state, maze)
                    |> solve(new_score+1000, turn(new_state, counter_clockwise), new_state, maze)
                }
            }
        }
        Error(_) -> panic
    }
}

pub fn turn(state: State, f: fn(Direction) -> Direction) -> State {
    State(position: state.position, direction: f(state.direction))
}

pub fn forward(state: State) -> State {
    let #(x, y) = state.position
    let #(dx, dy) = direction_offset(state.direction)
    State(position: #(x+dx, y+dy), direction: state.direction)
}

pub fn find(maze: dict.Dict(Coordinate, Tile), tile: Tile) -> Coordinate {
    let assert Ok(position) = maze
        |> dict.filter(fn(_, t) { t == tile })
        |> dict.keys
        |> list.first
    position
}


pub fn direction_offset(direction: Direction) -> Coordinate {
    case direction {
        North -> #(0, -1)
        East -> #(1, 0)
        South -> #(0, 1)
        West -> #(-1, 0)
    }
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
