import gleam/set
import gleam/int
import gleam/dict
import gleam/list
import gleam/string
import gleam/io
import simplifile as file

pub type Lock = #(Int, Int, Int, Int, Int)
pub type Key = #(Int, Int, Int, Int, Int)

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day25.txt")
    let #(locks, keys) = parse(contents)

    io.println("Part 1: " <> int.to_string(part1(locks, keys)))
}

pub fn part1(locks: List(Lock), keys: List(Key)) -> Int {
    list.map(keys, fn(key) {
        list.count(locks, fn(lock) { match(lock, key) })
    })
    |> list.fold(0, int.add)
}

pub fn match(lock: Lock, key: Key) -> Bool {
    let #(l1, l2, l3, l4, l5) = lock
    let #(k1, k2, k3, k4, k5) = key
    [ l1+k1, l2+k2, l3+k3, l4+k4, l5+k5 ] |> list.all(fn(x) { x <= 5 })
}

pub fn parse(contents: String) -> #(List(Lock), List(Key)) {
    let groups = contents
        |> string.split("\n")
        |> list.sized_chunk(8)
        |> list.map(fn(chunk) { list.filter(chunk, fn(x) { x != "" } ) })
        |> list.group(fn(chunk) {
            case chunk {
                [first, ..] if first == "....." -> "key"
                [first, ..] if first == "#####" -> "lock"
                _ -> panic
            }
        })
        |> dict.map_values(fn(_, group) {
            list.map(group, fn(chunk) {
                chunk
                |> list.map(fn(row) {
                    let assert Ok(bits) = row
                        |> string.replace(each: ".", with: "0")
                        |> string.replace(each: "#", with: "1")
                        |> int.parse
                    bits
                })
                // Pad with a leading 1 so that even if the first column has zero height,
                // the resulting int.to_string() will still contain a consitent length
                |> list.fold(1_00000, int.add) // Ensure that the number is always six digits
                |> int.to_string
                |> string.to_graphemes
                |> fn(graphemes) {
                    let numbers = graphemes
                        |> list.map(fn(x) {
                            case int.parse(x) {
                                Ok(x) -> x
                                Error(_) -> panic
                            }
                        })
                    let assert [_padding, first, second, third, fourth, fifth] = numbers
                    #(first-1, second-1, third-1, fourth-1, fifth-1)
                }
            })
        })

    let assert Ok(locks) = dict.get(groups, "lock")
    let assert Ok(keys) = dict.get(groups, "key")

    #(locks, keys)
}