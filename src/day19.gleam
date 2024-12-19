import gleam/bool
import gleam/io
import gleam/list
import gleam/string
import gleam/int
import rememo/memo
import simplifile as file

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day19.txt")
    let #(towels, designs) = parse(contents)

    io.println("Part 1: " <> int.to_string(part1(designs, towels)))
}

pub fn part1(designs: List(String), towels: List(String)) -> Int {
    designs
    |> list.map(fn(design) {
        use cache <- memo.create() possible(design, towels, cache)
    })
    |> list.count(fn(x) { x == True })
}

pub fn possible(design: String, towels: List(String), cache) -> Bool {
    use <- memo.memoize(cache, design)
    case design {
        "" -> True
        _ -> towels
            |> list.filter(fn(towel) { string.starts_with(design, towel) })
            |> list.map(fn(towel) { string.drop_start(design, string.length(towel)) })
            |> list.map(fn(new_design) { possible(new_design, towels, cache) })
            |> list.fold(False, bool.or)
    }
}

pub fn parse(contents: String) -> #(List(String), List(String)) {
    let #(towels, designs) = contents
        |> string.split("\n")
        |> list.split_while(fn(x) { x != ""})
    let designs = list.drop(designs, 1)
    let towels = towels
        |> list.map(fn(towels){
            towels
            |> string.split(",")
            |> list.map(fn(s) { string.trim(s)})
        })
        |> list.flatten
    #(towels, designs)
}