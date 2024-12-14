import gleam/set
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/io
import gleam/option
import gleam/regexp
import simplifile as file

pub type Robot {
    Robot(position: #(Int, Int), velocity: #(Int, Int))
}

/// https://en.wikipedia.org/wiki/Quadrant_(plane_geometry)
pub type Quadrant {
    I
    II
    III
    IV
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day14.txt")
    let #(width, height) = #(101, 103)

    let robots = parse(contents)

    io.println("Part 1: " <> int.to_string(part1(robots, width, height)))
    io.println("Part 2: " <> int.to_string(part2(robots, width, height)))
}

fn part2(robots: List(Robot), width: Int, height: Int) -> Int {
    find_tree(0, robots, width, height)
}

fn find_tree(acc: Int, robots: List(Robot), width: Int, height: Int) -> Int {
    /// The tree has a border (not mentioned in the question). Look for it.
    let positions = list.map(robots, fn(robot) { robot.position })
    let position_set = set.from_list(positions)
    let found_line = positions
        |> list.fold(False, fn(found, pos) {
            let #(x, y) = pos
            let has_line = [
                set.contains(position_set, #(x+1, y)),
                set.contains(position_set, #(x+2, y)),
                set.contains(position_set, #(x+3, y)),
                set.contains(position_set, #(x+4, y)),
                set.contains(position_set, #(x+5, y)),
                set.contains(position_set, #(x+6, y)),
                set.contains(position_set, #(x+7, y)),
                set.contains(position_set, #(x+8, y)),
            ] |> list.fold(True, bool.and)
            case found, has_line {
                True, _ -> True
                False, True -> True
                _, _ -> False
            }
        })
    case found_line {
        True -> acc
        False -> find_tree(
            acc + 1,
            simulate(robots, 1, width, height),
            width,
            height,
        )
    }
}

fn part1(robots: List(Robot), width: Int, height: Int) -> Int {
    robots
    |> simulate(100, width, height)
    |> list.map(fn(robot) {robot.position})
    |> list.filter_map(fn(pos){
        case on_axis(pos, width, height) {
            True -> Error(Nil)
            False -> Ok(quadrant(pos, width, height))
        }
    })
    |> list.group(fn(quadrant) {
        case quadrant {
            I -> "I"
            II -> "II"
            III -> "III"
            IV -> "IV"
        }
    })
    |> dict.map_values(fn(_key, val) {list.length(val)})
    |> dict.values
    |> list.fold(1, int.multiply)
}

fn on_axis(position: #(Int, Int), width: Int, height: Int) -> Bool {
    let #(x, y) = position
    let #(mid_x, mid_y) = #(width/2, height/2)
    x == mid_x || y == mid_y
}

fn quadrant(position: #(Int, Int), width: Int, height: Int) -> Quadrant {
    let #(x, y) = position
    let #(mid_x, mid_y) = #(width/2, height/2)
    case x - mid_x >= 0, y - mid_y >= 0 {
        True, True -> I
        False, True -> II
        False, False -> III
        True, False -> IV
    }
}

pub fn simulate(robots: List(Robot), time: Int, width: Int, height: Int) -> List(Robot) {
    robots
    |> list.map(fn(robot) {
        let #(px, py) = robot.position
        let #(vx, vy) = robot.velocity
        let new_pos = #(positive_modulo(px + vx * time, width), positive_modulo(py + vy * time, height))
        Robot(..robot, position: new_pos)
    })
}

fn positive_modulo(i: Int, n: Int) -> Int {
    {{i % n} + n} % n
}

pub fn parse(contents: String) -> List(Robot) {
    let assert Ok(re) = regexp.compile(
        "p=(-?\\d+),(-?\\d+) v=(-?\\d+),(-?\\d+)",
        with: regexp.Options(case_insensitive: False, multi_line: True)
    )
    regexp.scan(with: re, content: contents)
    |> list.map(fn(match){
        let assert [px, py, vx, vy] = match.submatches
            |> list.map(fn(x) {
                let assert option.Some(x) = x
                let assert Ok(x) = int.parse(x)
                x
            })
        Robot(#(px, py), #(vx, vy))
    })
}