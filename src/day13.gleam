import gleam/regexp
import gleam/int
import gleam/list
import gleam/result
import gleam/io
import gleam/option
import gleam/float
import gleam/pair
import simplifile as file

pub type Coordinate = #(Int, Int)
pub type Button = Coordinate
pub type Target = Coordinate
pub type Arcade {
    Arcade(a: Button, b: Button, target: Target)
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day13.txt")
    let arcades = parse(contents)
    io.println("Part 1: " <> int.to_string(part1(arcades)))
    io.println("Part 2: " <> int.to_string(part2(arcades)))
}

pub fn part1(arcades: List(Arcade)) -> Int {
    arcades
    |> list.map(fn(arcade) { tokens(arcade) })
    |> list.map(fn(result) {
        case result {
            Ok(tokens) -> tokens
            Error(_) -> 0
        }
    })
    |> list.reduce(int.add)
    |> result.unwrap(-1)
}

pub fn part2(arcades: List(Arcade)) -> Int {
    arcades
    |> list.map(modify_arcade_for_part2)
    |> part1
}

pub fn modify_arcade_for_part2(arcade: Arcade) -> Arcade {
    let #(x, y) = arcade.target
    Arcade(..arcade, target: #(x + 10000000000000, y + 10000000000000))
}

pub fn tokens(arcade: Arcade) -> Result(Int, Nil) {
    let #(a, b) = solve_linear_equations(arcade.a, arcade.b, arcade.target)
    let #(ar, br) = #(float.round(a), float.round(b))

    let tolerance = 0.001
    let tokens_a = 3
    let tokens_b = 1

    let equal = float.loosely_equals(a, int.to_float(ar), tolerance) && float.loosely_equals(b, int.to_float(br), tolerance)
    case equal {
        False -> Error(Nil)
        True -> Ok(tokens_a * ar + tokens_b * br)
    }
}

pub fn solve_linear_equations(v1: Coordinate, v2: Coordinate, vt: Target) -> #(Float, Float) {
    // This solves the claw problem using vector algebra:
    //   a*v1 + b*v2 = vt = a(x1,y1) + b(x2, y2) = (xt, yt)
    // let (x1, y1) = v1
    // let (x2, y2) = v2
    // let (xt, yt) = vt
    let assert [x1, y1, x2, y2, xt, yt] = {
        [v1, v2, vt]
        |> list.map(fn(t) {[pair.first(t), pair.second(t)]})
        |> list.flatten
        |> list.map(int.to_float)
    }
    let b = { {yt /. y2} -. { {xt *. y1} /. {x1 *. y2} } } /. { 1.0 -. { {y1 *. x2} /. {x1 *. y2} }}
    let a = { xt /. x1 } -. { b *. {x2 /. x1} }
    #(a, b)
}

pub fn parse(contents: String) -> List(Arcade) {
    let assert Ok(re) = regexp.compile(
        "Button A: X\\+(\\d+), Y\\+(\\d+)\nButton B: X\\+(\\d+), Y\\+(\\d+)\nPrize: X=(\\d+), Y=(\\d+)",
        with: regexp.Options(case_insensitive: False, multi_line: True)
    )
    regexp.scan(with: re, content: contents)
    |> list.map(fn(match){
        let assert [option.Some(ax), option.Some(ay), option.Some(bx), option.Some(by), option.Some(px), option.Some(py)] = match.submatches
        let assert Ok(ax) = int.parse(ax)
        let assert Ok(ay) = int.parse(ay)
        let assert Ok(bx) = int.parse(bx)
        let assert Ok(by) = int.parse(by)
        let assert Ok(px) = int.parse(px)
        let assert Ok(py) = int.parse(py)
        Arcade(#(ax, ay), #(bx, by), #(px, py))
    })
}

