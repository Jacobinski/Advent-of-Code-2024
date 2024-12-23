import gleam/string
import gleam/io
import gleam/int
import gleam/list
import simplifile as file

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day22.txt")
    let numbers = parse(contents)

    io.println("Part 1: " <> int.to_string(part1(numbers)))
}

pub fn part1(numbers: List(Int)) -> Int {
    numbers
    |> list.map(secret(_, 2000))
    |> list.fold(0, int.add)
}

pub fn secret(initial: Int, repeats: Int) -> Int {
    case repeats {
        x if x <= 0 -> initial
        _ -> secret(next(initial), repeats-1)
    }
}

pub fn next(secret: Int) -> Int {
    let secret = mix(secret * 64, secret) |> prune
    let secret = mix(secret / 32, secret) |> prune
    let secret = mix(secret * 2048, secret) |> prune
    secret
}

pub fn mix(number: Int, secret: Int) -> Int {
    int.bitwise_exclusive_or(number, secret)
}

pub fn prune(secret: Int) -> Int {
    secret % 16777216
}

pub fn parse(contents: String) -> List(Int) {
    contents
    |> string.split("\n")
    |> list.map(fn(x){
        let assert Ok(x) = int.parse(x)
        x
    })
}