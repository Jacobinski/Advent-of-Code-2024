import gleam/regexp
import gleam/int
import gleam/list
import gleam/result
import gleam/io
import gleam/option
import rememo/memo
import simplifile as file

pub type Coordinate = #(Int, Int)
pub type Button = Coordinate
pub type Target = Coordinate
pub type Arcade {
    Arcade(a: Button, b: Button, target: Target)
}

const tokens_a = 3
const tokens_b = 1

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day13.txt")
    let arcades = parse(contents)
    io.println("Part 1: " <> int.to_string(part1(arcades)))
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

pub fn tokens(arcade: Arcade) -> Result(Int, Nil) {
    use cache <- memo.create()
    tokens_helper(arcade.target, arcade.a, arcade.b, cache)
}

pub fn tokens_helper(curr: Coordinate, a: Button, b: Button, cache) -> Result(Int, Nil) {
    use <- memo.memoize(cache, curr)
    {
        let #(x, y) = curr
        let #(ax, ay) = a
        let #(bx, by) = b
        case x, y {
            x, y if x < 0 || y < 0 -> Error(Nil)
            x, y if x == 0 && y == 0 -> Ok(0)
            x, y -> {
                let try_a = tokens_helper(#(x-ax, y-ay), a, b, cache)
                let try_b = tokens_helper(#(x-bx, y-by), a, b, cache)
                case try_a, try_b {
                    Ok(recurse_a), Ok(recurse_b) -> Ok(int.min(tokens_a + recurse_a, tokens_b + recurse_b))
                    Ok(recurse_a), Error(_) -> Ok(tokens_a + recurse_a)
                    Error(_), Ok(recurse_b) -> Ok(tokens_b + recurse_b)
                    Error(_), Error(_) -> Error(Nil)
                }
            }
        }
    }
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

